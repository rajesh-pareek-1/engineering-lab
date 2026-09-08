# High-End Topic 01 — Multi-tenancy in ROD

> Detailed, source-grounded interview sheet.

---

## The one-line answer

> **“In ROD, each customer company is a tenant. We resolve the tenant from trusted authenticated request or background-job context, then `ITenantDbContextFactory` creates the EF Core context connected to that tenant’s SQL database.”**

```text
JWT proves identity.       Tenant resolution chooses the data boundary.
```

---

## 1. What is multi-tenancy?

```text
One software product
        ↓
serves many customer companies
        ↓
while keeping each company’s data, configuration, and access isolated.
```

```text
Tenant  ≠ User
Tenant  ≠ Role
Tenant  ≠ Account

Tenant  = customer/data boundary
User    = person inside that boundary
Role    = what that person may do
Account = business sub-unit/member grouping inside the tenant
```

Example:

```text
ROD platform
├── Tenant A — Trucking Company Alpha
│   ├── dispatchers
│   ├── drivers
│   └── shipments
└── Tenant B — Trucking Company Beta
    ├── dispatchers
    ├── drivers
    └── shipments
```

**Non-negotiable rule:** a valid Tenant A user must never read or change Tenant B data, even if they alter a URL, query string, or request body.

---

## 2. Why does a SaaS product need it?

```text
Without multi-tenancy
One customer = one separate application deployment
→ duplicate releases, cost, monitoring, and maintenance

With multi-tenancy
One platform = many companies
→ shared codebase, central upgrades, controlled isolation
```

The deeper reason is protection, not only cost:

```text
Authentication → Who are you?
Authorization  → What may you do?
Tenancy        → Which customer’s data may you touch?
```

---

## 3. ROD architecture: shared control plane versus tenant data

ROD uses a **database-per-tenant** model for operational logistics data.

```text
AppGlobalContext — shared/control-plane SQL database
├── Tenants
├── Users
├── Accounts and AccountUsers
├── Roles, Permissions, Scopes
├── tenant settings
├── message/integration configuration
├── QuickBooks configuration
├── cross-tenant tracking records
└── Hangfire SQL job storage

RollOnDispatchContext — tenant operational SQL database
├── shipments
├── driver loads
├── associates / drivers
├── attachments
└── other ROD operational entities
```

The global `Tenant` has GUID `TenantId` as its key and a unique company name. `User` and `Account` carry `TenantId`; `AccountUser` represents the account-to-user relationship.

**Important:** Do not say every business row has `TenantId` in ROD’s operational database. Here, the primary isolation boundary is the database connection selected for the tenant.

---

## 4. ROD HTTP request flow — draw this

```text
React / Driver Mobile App
        |
        | Authorization: Bearer <JWT>
        v
ASP.NET Core pipeline
        |
        | UseAuthentication() validates token
        | issuer + audience + signature + lifetime
        v
HttpContext.User claims
        |
        | tenant identity (tid), user ID, email, roles, scopes
        v
IRequestContext (RequestContext)
        |
        | extracts TenantId from authenticated claims
        v
ITenantDbContextFactory
        |
        | creates SQL Server options for current tenant
        v
RollOnDispatchContext
        |
        v
Repository → Service → Controller → response
```

### What ROD does

1. JWT authentication completes before the endpoint executes.
2. `RequestContext` reads authenticated claims and resolves `TenantId`, user ID, username, roles, scopes, and organization/account context.
3. Scoped `ITenantDbContextFactory` receives `IRequestContext`.
4. The factory uses the configured `TenantDatabase` connection-string template, current tenant GUID, and a derived credential to build EF Core `DbContextOptions` through `UseSqlServer`.
5. It creates `RollOnDispatchContext` through `Create` or `CreateWithUserContext`.
6. The repository receives this tenant-bound context, so its shipment, driver, and attachment query executes against that customer’s database.

Conceptual responsibility — not literal production code:

```csharp
public RollOnDispatchContext CreateTenantContext()
{
    var tenantId = _requestContext.TenantId
        ?? throw new UnauthorizedAccessException("Tenant context is required.");

    var connection = BuildTenantConnection(tenantId.Value);

    var options = new DbContextOptionsBuilder<RollOnDispatchContext>()
        .UseSqlServer(connection)
        .Options;

    return RollOnDispatchContext.CreateWithUserContext(
        options,
        $"{_requestContext.UserId}-{_requestContext.Username}",
        _featureManager);
}
```

### Why the factory matters

```text
Bad: Controller receives tenantId from query/body and picks a DB.
Good: Trusted RequestContext → factory → tenant DbContext → repository.
```

The ROD factory caches a context by `DbContext` type during its scoped lifetime, avoiding repeated context creation within one request.

---

## 5. Where does the tenant ID come from?

```text
Login creates JWT
        ↓
JWT contains tenant identity (tid) + user/role/scope claims
        ↓
JWT middleware validates signature and creates ClaimsPrincipal
        ↓
RequestContext extracts tenant identity
        ↓
Tenant factory uses it to choose the business-data connection
```

Say this clearly:

> “The API derives tenancy from a signed, validated identity context. The UI may display a tenant, but it must not be the authority that selects the database.”

Bad design:

```http
GET /api/shipments?tenantId=tenant-b
```

Correct design:

```text
Bearer JWT → trusted tenant claim → server-side context → database selection
```

---

## 6. Background jobs — the hidden difficult part

An HTTP request has `HttpContext`. A Hangfire job does not.

```text
Document-expiry reminder begins later
        ↓
No HTTP request exists
        ↓
How does it know which tenant database to query?
```

ROD’s solution:

```text
Application schedules a tenant job
        |
        | BackgroundJobContext(tenantId)
        v
Hangfire client filter stores tenant context as a job parameter
        v
Hangfire runs the job later
        |
        | CustomHangfireJobActivator opens a DI scope
        | retrieves stored tenant context
        | calls IRequestContext.SetBackgroundContext(tenantId)
        v
ITenantDbContextFactory
        v
Correct tenant RollOnDispatch database
```

`SetBackgroundContext` assigns the tenant plus the service identity `BackgroundService`, because a scheduled job has no human user.

### Concrete ROD example

```text
Tenant A document-expiry job
→ restore Tenant A context
→ create Tenant A RollOnDispatchContext
→ read Tenant A mobile-app drivers and attachments
→ send Tenant A notifications
```

**Rule:** tenant propagation must cover APIs **and** asynchronous work.

---

## 7. Tenant onboarding / provisioning flow in ROD

```text
New company signup
        ↓
Validate no duplicate user/company
        ↓
Create billing checkout
        ↓
After successful subscription:
generate TenantId (GUID)
        ↓
Call configured tenant-provisioning endpoint
        ↓
Provisioning completion callback
        ↓
Create global Tenant record
Create administrator user
        ↓
Queue onboarding email
Initialize tenant cron jobs
Initialize company settings
```

The visible backend source triggers an external configured provisioning endpoint. Its source is not present here. Use this exact interview wording:

> “The backend starts tenant provisioning through a configured external endpoint; the application then completes the tenant record, administrator user, onboarding, settings, and tenant-specific job setup.”

Do **not** claim exact Azure resource-creation steps unless you have that provisioning component’s source.

---

## 8. Common multi-tenancy models

| Model                              | Shape                                        | Main advantage                       | Main risk/cost                    |
| ---------------------------------- | -------------------------------------------- | ------------------------------------ | --------------------------------- |
| Shared database, shared schema     | Every tenant row carries`TenantId`         | Lowest cost; simple global reporting | Highest cross-tenant leakage risk |
| Shared database, schema per tenant | `tenantA.Shipments`, `tenantB.Shipments` | More separation                      | Schema/migration complexity       |
| Database per tenant                | Separate operational DB per company          | Strong isolation; easier restore     | More databases/migrations         |
| Deployment per tenant              | Separate app and DB                          | Maximum compliance/isolation         | Highest infrastructure cost       |
| Hybrid                             | Small tenants shared, large tenants isolated | Flexible cost/performance            | More platform complexity          |

ROD’s operational data is closest to **database per tenant**.

### Shared-database alternative

Every tenant-owned row needs a tenant key and query/index discipline:

```sql
CREATE TABLE Shipments
(
    ShipmentId BIGINT PRIMARY KEY,
    TenantId UNIQUEIDENTIFIER NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CreatedAt DATETIME2 NOT NULL
);

CREATE INDEX IX_Shipments_TenantId_CreatedAt
ON Shipments (TenantId, CreatedAt DESC);
```

EF Core safety net:

```csharp
modelBuilder.Entity<Shipment>()
    .HasQueryFilter(x => x.TenantId == _tenantContext.TenantId);
```

An EF query filter is only one defense. Use tenant-aware authorization, composite tenant-aware unique constraints, careful raw SQL, integration tests, and database row-level security where appropriate.

---

## 9. Benefits

```text
I-S-O-L-A-T-E

I = Isolation at the database connection boundary
S = Separate backup and restore options
O = One noisy tenant is easier to identify/manage
L = Lower chance of forgotten query filters leaking data
A = Ability to move a large tenant independently
T = Tenant-specific recovery and performance tuning
E = Easier enterprise/compliance conversations
```

Best sentence:

> “With a shared schema, every query must remember the tenant filter. With database-per-tenant, the connection itself becomes part of the isolation boundary.”

---

## 10. Disadvantages, weaknesses, and improvements

| Challenge                     | Why it exists                                          | Better operating approach                                                |
| ----------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------ |
| Migration fan-out             | Every schema change reaches every tenant DB            | Version registry; canary first; bounded parallel rollout; failure report |
| More database operations      | More backups, monitoring, credentials, and cost        | Automation, templates, runbooks, elastic pools where suitable            |
| Cross-tenant reporting        | Data is physically split                               | Read model/warehouse, ETL, or aggregate service                          |
| Connection-pool fragmentation | Many unique connection strings mean many pools         | Monitor pool pressure; group small tenants only if suitable              |
| Partial provisioning          | External provision + local write are distributed steps | Status machine, idempotency key, retry, reconciliation/cleanup job       |
| Background context loss       | A job has no HTTP context                              | Durable tenant job parameter; explicit tests                             |

Security improvements:

```text
• Fail closed when tenant context is absent or invalid.
• Never allow query/body values to select a database.
• Store secrets in Key Vault / use managed identity.
• Never log connection strings, provisioning codes, tokens, or sensitive payloads.
• Authorize tenant membership and action/role.
• Isolate Blob paths, queues, caches, and jobs—not only SQL.
```

### Source-aware review insight

The ROD tenant factory permits a null tenant context to support Hangfire scheduling. That is practical, but a hardened design must distinguish:

```text
Scheduling phase: tenant context may be absent.
Business-data access: tenant context must exist; fail immediately and clearly.
```

Do not volunteer criticism in an interview. Use it only when asked, “What would you improve?”

---

## 11. How it scales

```text
API scale
→ stateless ASP.NET Core instances behind a load balancer
→ resolve tenant per request
→ EF Core / SQL connection pooling

Database scale
→ move high-volume tenant to stronger SQL resources
→ isolate noisy customers
→ tenant-specific backup, restore, and tuning

Job scale
→ queues + bounded Hangfire workers
→ idempotent jobs
→ per-tenant concurrency/rate control

Migration scale
→ version registry
→ canary tenant
→ bounded batches
→ retry/reconcile failed tenants
```

Every request/job log and trace should carry:

```text
correlation ID
tenant ID
user ID (when a human initiated it)
route/job name
status/result
duration
```

Use tenant IDs in secure logs/traces. At very high scale, avoid using full tenant IDs as a primary aggregate metric dimension because high-cardinality metrics become costly; use tenant tier, plan, or region for aggregate dashboards.

---

## 12. Tests that prove isolation

```text
✓ Tenant A token returns only Tenant A data.
✓ Tenant B token returns only Tenant B data.
✓ Tenant A asks for Tenant B resource ID → deny/not-found; never expose data.
✓ Missing/invalid tenant claim → controlled failure.
✓ Background job for Tenant A resolves Tenant A database.
✓ Provisioning retry does not create duplicate tenant/user/job.
✓ Migrations report the schema result for every tenant.
```

---

## 13. Rapid cross-questions

| Question                               | Answer                                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Is multi-tenancy just JWT?             | No. JWT establishes identity; tenancy enforces customer isolation across APIs, databases, jobs, storage, cache, and logging.      |
| Does authorization replace tenancy?    | No. A user can have a valid dispatcher role and still be restricted to only their tenant’s data.                                 |
| Where is tenant ID found in ROD?       | After JWT authentication,`RequestContext` extracts it from authenticated claims and exposes `TenantId`.                       |
| How does a repository know the tenant? | It receives`RollOnDispatchContext` from `ITenantDbContextFactory`, not a UI-supplied tenant ID.                               |
| How do Hangfire jobs know the tenant?  | `BackgroundJobContext` is stored as a Hangfire job parameter and restored by the custom job activator into `IRequestContext`. |
| What does Hangfire SQL store?          | Job schedules, arguments/parameters, state, retries, and queue metadata—not tenant shipment data.                                |
| Major DB-per-tenant disadvantage?      | Provisioning, monitoring, backups, secret management, and schema migrations across many databases.                                |

---

## 14. The 90-second spoken answer

> “Multi-tenancy means one SaaS platform serves multiple customer companies while enforcing a strict data boundary for each company. In ROD, a tenant is the customer organization. We use a database-per-tenant model for operational logistics data, while shared platform concerns such as tenants, users, roles, permissions, settings, integrations, and Hangfire storage live in the global database.
>
> On an API request, JWT authentication validates the user token. Our `RequestContext` gets tenant identity from trusted claims, and `ITenantDbContextFactory` creates the EF Core `RollOnDispatchContext` connected to the correct tenant SQL database. Repositories then work with a context already scoped to that customer.
>
> We also propagate tenant context to Hangfire jobs, because jobs have no HTTP request. The tenant ID is persisted with the job and restored into the job’s DI scope before the DbContext is resolved. This gives the same isolation for document-expiry reminders. The trade-off is more work around provisioning and migrations, but it provides strong isolation and lets us scale or recover tenants independently.”

---

## Memory map

```text
T-E-N-A-N-T

T = Trusted claim identifies tenant
E = EF Core context is created for that tenant
N = No frontend value selects the database
A = APIs and async jobs both carry tenant context
N = Namespace/data boundary is the tenant database
T = Trace, test, and transition tenants safely
```
