# PROJECTS

Detailed project proof. Use only after `REVISION/MASTER_BEHAVIORAL.md`.

## RollOnDispatch

## 30 Second Introduction

```text
Hi, I am Rajesh. I work as a software developer at In Time Tec with experience across ASP.NET Core APIs, React/React Native, EF Core, SQL, and Azure-based product systems. I have worked on production workflows involving multi-tenant APIs, shipment and driver workflows, database optimization, background processing, and mobile/web integrations.
```

## 60-90 Second Project Pitch

```text
RollOnDispatch is a multi-tenant SaaS platform for trucking and livestock logistics. It manages the shipment lifecycle: creating shipments, assigning drivers, tracking delivery status, generating invoices, reports, and syncing accounting data with QuickBooks.

The backend follows a layered architecture: controllers receive HTTP requests, services handle validation and business logic, repositories handle persistence, and EF Core maps domain entities to SQL. Tenant context comes from authenticated claims and resolves tenant-specific database access.

For scalability, heavy work such as invoice generation and external QuickBooks sync is moved out of the request path using Hangfire and Azure Service Bus. I worked mainly around shipment APIs, driver/load workflows, validation, async processing, and query performance improvements.
```

## Architecture

```text
Controller -> Service -> Repository -> EF Core -> SQL
```

Responsibilities:

- Controller: HTTP request, response, status codes.
- Service: business rules, validation, orchestration.
- Repository: data access and reusable persistence methods.
- EF Core: ORM, tracking, queries, migrations.
- Background jobs: slow work outside request path.

## Create Shipment API Flow

1. Request reaches controller.
2. Authentication middleware validates JWT.
3. Tenant/user context is available to scoped services.
4. Controller calls service.
5. Service validates DTO, maps to entity, applies business rules.
6. Repository adds entity using EF Core.
7. `SaveChangesAsync` persists data.
8. Activity logging captures changes from EF ChangeTracker.
9. Response returns shipment ID/status.

Interview line:

```text
I explain APIs as flow, reason, and tradeoff: what happens, why we designed it that way, and what can go wrong.
```

## Key Concepts

### Repository Pattern

```text
Repository separates data access from business logic and centralizes common operations like Add, Update, GetList, and Delete.
```

Tradeoff:

```text
Too generic a repository can hide EF Core's query power, so optimized queries should still allow projection and filtering.
```

### Generic CRUD

```text
Generic base services/repositories reduce duplicate CRUD logic across entities. Business-specific service logic calls common base operations after validation.
```

### FluentValidation

```text
Validation stays in the service/application layer instead of making controllers large. It also allows conditional rules based on shipment status or workflow state.
```

### Activity Logging

```text
Activity logging can use EF ChangeTracker to record what changed during SaveChangesAsync.
```

Tradeoff:

```text
If audit logging failure is swallowed, the main operation succeeds but audit trail may have gaps. If audit logging is in the same transaction, reliability improves but failures can block business operations.
```

### TransactionScope

```text
TransactionScope is useful when multiple DB operations must succeed or rollback together.
```

## Performance Talking Points

### Pagination

Use `Skip` and `Take`, but enforce maximum page size.

Tradeoff:

```text
No max limit can still allow huge responses and DB pressure.
```

### Projection

Use `Select` to fetch only needed columns.

```text
Projection reduces memory usage, network transfer, and EF tracking overhead.
```

### Async/Await

```text
Async APIs prevent request threads from blocking while waiting for DB or external calls.
```

Trap:

```text
Avoid sync DB calls inside async flows.
```

### Indexes

Add indexes on fields frequently used by shipment, associate, driver, status, and date filters.

## Async Systems

### Hangfire

Used for background jobs such as invoice generation, notifications, and scheduled processing.

### Azure Service Bus

Used to decouple QuickBooks sync or other external integration work.

Flow:

```text
API creates work -> message/job queued -> background processor handles it -> retry/log on failure
```

### Invoice Flow

```text
API request -> background job -> generate invoice/report -> send email -> publish QuickBooks sync message
```

## Tradeoffs To Mention

- No optimistic concurrency can lead to last-write-wins.
- Activity logging may have gaps if failures are ignored.
- Pagination needs max limits.
- Double `SaveChanges` can increase DB overhead.
- Background jobs need tenant context isolation.
- External sync must be idempotent because retries can happen.

## Common Questions

### Why Service Bus?

```text
To decouple the API from slow or unavailable external systems. It gives asynchronous processing and retry support.
```

### Why Hangfire?

```text
To process heavy or scheduled work outside the request path and avoid request timeouts.
```

### How Does Multi-Tenancy Work?

```text
The authenticated request carries tenant identity. Scoped request context exposes TenantId, and tenant-aware data access resolves the correct tenant database.
```

### What Would You Improve?

```text
I would enforce pagination limits, add optimistic concurrency where update conflicts matter, make audit logging reliability explicit, and strengthen tenant validation before DB access.
```

## Safety Lines

Use these when you know the area but did not own all of it:

- "I worked around this flow and understand the high-level design."
- "I did not implement that end-to-end, but the way it works is..."
- "The tradeoff I would watch for is..."

## Multi-Tenancy Deep Dive

## High-Level Model

The architecture uses two database categories:

1. Global database
2. Tenant databases

Global database stores:

- Tenants
- Users
- Roles
- Permissions
- Accounts
- Config

Tenant database stores:

- Shipments
- Loads
- Driver/domain data
- Tenant-specific business entities

## Request Tenant Flow

```text
JWT contains tenant claim
-> authentication middleware validates token
-> RequestContext extracts TenantId
-> scoped services use RequestContext
-> ITenantDbContextFactory builds tenant connection
-> tenant DbContext created
-> context cached per request
```

Interview line:

```text
Tenant is resolved per request after authentication, so a normal startup-registered DbContext is not enough when the connection string changes per tenant.
```

## Why DbContext Is Not Registered Directly

Reasons:

- Tenant connection string depends on the authenticated user/request.
- Tenant is not known at application startup.
- DbContext must be created at runtime.
- The same request should reuse the same context for consistency.

## Why Cache DbContext Per Request

Without request cache:

- Multiple DbContexts per request.
- Multiple DB connections.
- Fragmented change tracking.
- Harder transaction boundary.
- More overhead.

With request cache:

- One unit of work.
- Shared tracking.
- Reduced connection churn.
- Better transactional consistency.

## Reflection-Based Factory

Original idea:

```text
Factory receives generic DbContext type and invokes static Create/CreateWithUserContext methods dynamically.
```

Why it was used:

- Generic factory needs to instantiate concrete context types.
- Older C# cannot enforce static method contracts on generic types.

Risks:

- Method rename is not caught at compile time.
- Signature changes fail at runtime.
- Fallbacks can silently lose user/audit context.

Better options:

- Static abstract interface members on modern C#.
- Explicit factory delegates registered at startup.
- Per-context factory implementation.

## Database-Per-Tenant Benefits

- Strong tenant isolation.
- Smaller blast radius.
- Easier per-tenant restore.
- No noisy-neighbor issue.
- Tenant-specific scaling possible.
- Safer data access boundaries.

## Database-Per-Tenant Tradeoffs

- Migration orchestration complexity.
- Higher infrastructure cost.
- Cross-tenant reporting is harder.
- Connection pool pressure at scale.
- Operational overhead grows with tenant count.

## Migration Strategy

Use separate migration tracks:

- Global DB migrations.
- Tenant DB migrations.

Avoid auto-migrating all tenants on app startup because:

- Startup time scales with tenant count.
- Multiple app instances can race.
- Partial failures become hard to detect.
- App availability should not depend on migration duration.

Better migration orchestrator:

```text
Read tenant list from global DB
-> check each tenant __EFMigrationsHistory
-> apply pending migrations with limited parallelism
-> record status per tenant
-> retry failures
-> alert/report failed tenants
```

## Principal Engineer Risk Review

### 1. Single Secret Catastrophe

Problem:

```text
One AppSecret signs JWTs, derives tenant DB passwords, and hashes refresh tokens.
```

Risk:

```text
Compromise one secret and attacker may access tokens, sessions, and tenant DBs.
```

Better:

- Asymmetric JWT signing keys with rotation.
- Azure Managed Identity for DB auth, or per-tenant random credentials in Key Vault.
- Separate refresh token secret/storage.

### 2. Silent Null Tenant Propagation

Problem:

```text
Missing tenant claim returns null context, then failure appears deep in repository/service.
```

Better:

```text
Tenant validation middleware after authentication. Fail fast with 400/401/403 and log clear reason.
```

### 3. Reflection Factory With No Safety Net

Problem:

```text
GetMethod("CreateWithUserContext") can fail silently or at runtime.
```

Better:

```text
Compile-time factory registration or static abstract interfaces.
```

### 4. Thread-Local Hangfire Tenant Context

Problem:

```text
Thread.ManagedThreadId based storage can leak tenant context across reused threads or async continuations.
```

Better:

```csharp
private static readonly AsyncLocal<BackgroundJobContext?> Current = new();
```

Add nested-context guard and always clear context.

### 5. Invisible Schema Drift

Problem:

```text
Some tenant DBs can miss migrations and fail only for specific tenants at runtime.
```

Better:

- Migration log per tenant.
- Drift health check.
- Admin migration-status endpoint.
- Alerting on failed migrations.

## Scale Evolution

At very large scale:

```text
Tenant -> Shard -> Database
```

Hybrid model:

- Small tenants share shards.
- Large tenants get isolated DBs.
- Tenant metadata decides connection routing.

## Best Interview Close

```text
Database-per-tenant gives strong isolation and simpler tenant safety, but it shifts complexity into migrations, connection management, cross-tenant reporting, and operational tooling.
```

## Resume Answer Bank

Use this file to connect resume bullets to spoken interview answers.

## Role Positioning

### Backend Role

```text
I am strongest in ASP.NET Core APIs, EF Core, SQL optimization, background processing, authentication, and multi-tenant backend workflows. I also understand frontend/mobile integration, which helps me design practical API contracts.
```

### Full Stack Role

```text
I can own features end-to-end: React/React Native UI, API integration, ASP.NET Core backend, SQL workflows, and deployment coordination.
```

### Mobile/Frontend Role

```text
I have worked on React Native and React TypeScript apps with Redux Toolkit, RTK Query, API integration, offline-aware workflows, push notifications, and performance-focused dashboards.
```

## Tell Me About Yourself

```text
I am Rajesh Pareek, a software developer with around 2.5 years of hands-on experience across ASP.NET Core, React, React Native, EF Core, SQL, and Azure DevOps. At In Time Tec, I have worked on SaaS and logistics platforms involving shipment workflows, driver/mobile features, multi-tenant backend services, REST APIs, database performance, background jobs, and production support. My strength is connecting product workflows with clean technical implementation and explaining tradeoffs clearly.
```

## Strong Project Story: Performance Improvement

Situation:

```text
Some API/listing flows had performance pressure because queries were fetching more data than required.
```

Action:

```text
I used pagination, projection with Select, avoided unnecessary materialization, reviewed indexes on frequently filtered columns, and used async EF Core calls.
```

Result:

```text
Response time improved and DB load reduced. The key lesson was to push filtering/projection to SQL instead of doing it in memory.
```

## Strong Project Story: Background Processing

Situation:

```text
Invoice/report/QuickBooks workflows could be slow or depend on external systems.
```

Action:

```text
Heavy work was moved to Hangfire/background jobs and Service Bus style messaging so API requests were not blocked.
```

Result:

```text
Users get faster API responses, and background work can retry or be monitored separately.
```

Tradeoff:

```text
Background work must be idempotent and tenant-safe because retries can happen.
```

## Strong Project Story: Multi-Tenancy

Situation:

```text
The product needed tenant isolation for logistics/customer data.
```

Action:

```text
Tenant identity flows from JWT into request context. Tenant-aware services resolve the correct tenant DB dynamically and cache DbContext per request.
```

Result:

```text
This gives strong isolation and safer per-tenant operations.
```

Tradeoff:

```text
It adds migration, connection, and cross-tenant reporting complexity.
```

## Strong Project Story: Frontend/API Integration

Situation:

```text
Frontend/mobile screens needed reliable API contracts for dashboards, forms, and driver workflows.
```

Action:

```text
I worked with typed API integration, reusable hooks/components, Redux Toolkit/RTK Query patterns, and consistent DTOs between frontend and backend.
```

Result:

```text
Feature delivery became more predictable and integration bugs were easier to debug.
```

## Common Resume Bullet Explanations

### "Built REST APIs"

```text
I built endpoints with controller-service-repository layering, request validation, DTO mapping, EF Core persistence, auth checks, structured errors, pagination, and async DB calls.
```

### "Optimized SQL / EF Core"

```text
I focused on filtering early, projection, indexes, avoiding N+1, using AsNoTracking for reads, and checking generated SQL/execution plans where needed.
```

### "JWT Authentication"

```text
JWT is validated by middleware, claims populate HttpContext.User, and role/policy authorization controls access to endpoints.
```

### "Clean Architecture / SOLID"

```text
I keep controllers thin, services focused on business logic, repositories focused on persistence, and dependencies injected through interfaces so code remains testable and maintainable.
```

### "React Native"

```text
I worked on cross-platform mobile workflows using React Native, TypeScript, navigation, secure storage, push notifications, geolocation, offline sync, and API integration.
```

### "CI/CD"

```text
I contributed to Azure DevOps style pipelines for automated build, lint/test checks, and controlled deployments across environments.
```

## Resume Claim Defense Map

Use this when an interviewer points to one bullet and asks, "Explain this."

| Resume claim | What they may ask | Strong answer angle | Project proof | Tradeoff to mention |
| --- | --- | --- | --- | --- |
| Multi-tenant SaaS | How does tenant resolution work? | JWT/request context resolves tenant-specific DB access. | RollOnDispatch tenant-aware data flow. | Migrations, connection pools, cross-tenant reporting. |
| REST APIs | What happens in one API call? | Controller -> service -> repository -> EF Core -> response. | Shipment/driver/load workflows. | Validation, errors, pagination, transaction boundary. |
| JWT authentication | How is token verified? | Middleware validates issuer/audience/expiry and sets claims. | Protected APIs and role-based workflows. | Token expiry, refresh, claim trust, tenant validation. |
| SQL optimization | How did you improve performance? | Projection, indexes, AsNoTracking, avoid N+1, pagination. | Listing/report-style queries. | Index write overhead, stale assumptions without execution plan. |
| Background jobs | Why not process in API? | Move slow/retryable work out of request path. | Invoice/report/QuickBooks-style flows. | Idempotency, retries, monitoring, tenant context. |
| Clean architecture | What does clean mean practically? | Thin controller, service business logic, repository persistence, DI. | API layering used in backend workflows. | Too many abstractions can slow simple changes. |
| React/React Native | What was hard? | State/API sync, offline/network handling, native features, performance. | Driver app, web dashboards, mobile workflows. | Device differences, stale state, retry handling. |
| CI/CD | What did pipeline do? | Build/test/lint/deploy with controlled environments. | Azure DevOps style deployment flow. | Secrets, rollback, environment drift. |

## Bullet-To-Answer Scripts

### Multi-Tenant Backend

Question:

```text
Your resume says multi-tenant backend. Explain the design.
```

Answer:

```text
The system separates global data from tenant business data. After JWT authentication, tenant identity is available in request context. Tenant-aware data access uses that context to resolve the correct tenant database and create/reuse DbContext for the request. The benefit is strong tenant isolation. The tradeoff is operational complexity around migrations, connection pooling, background jobs, and cross-tenant reporting.
```

### Performance Optimization

Question:

```text
How exactly did you optimize database performance?
```

Answer:

```text
I look at whether the query fetches too much data, runs too often, or uses poor access paths. Practically that means projection with Select, filtering before materialization, AsNoTracking for read-only queries, pagination limits, indexes on filter/join columns, and avoiding N+1. I would verify using generated SQL or execution plan rather than guessing.
```

### Background Jobs

Question:

```text
Why use Hangfire or queues?
```

Answer:

```text
Slow or retryable work should not block an API request. A request can enqueue work, return quickly, and a background worker can process with retry, logging, and failure handling. For invoice or external sync flows, this improves responsiveness and reliability. The important details are idempotency, monitoring, and tenant-safe context propagation.
```

### React Native

Question:

```text
What did you do in React Native?
```

Answer:

```text
I worked on API-driven mobile workflows using React Native and TypeScript, including navigation, state management, secure storage, push notification integration, geolocation/timezone behavior, document/image features, and offline-aware flows. The main challenge is predictable state when API calls, device permissions, and network conditions vary.
```

### Full Stack Ownership

Question:

```text
What does full stack mean in your case?
```

Answer:

```text
For me it means I can follow a feature from UI behavior to API contract to service logic to database query. I may not own every infrastructure detail, but I can debug integration issues across frontend, backend, and data flow.
```

## Red-Flag Questions And Safe Answers

### "Did You Personally Build This?"

```text
I worked on parts of this flow directly and worked around the full system enough to explain the architecture and tradeoffs. For the exact piece I did not own end-to-end, I will separate what I implemented from what I understand.
```

### "What Was The Hardest Bug?"

```text
The hardest bugs are usually integration or data-flow bugs: API returns correct data but UI state is stale, query fetches too much data, background work retries and risks duplicates, or tenant context is missing. My approach is to trace request ID/logs, reproduce with data, inspect generated SQL or payload, and fix the root flow rather than only the symptom.
```

### "What Are You Weak At?"

```text
I am still deepening system design at larger scale, especially around distributed consistency and advanced cloud operations. I compensate by being clear about tradeoffs, reading production behavior carefully, and validating designs with logs, metrics, and simpler failure modes.
```

## Questions To Ask Interviewer

- "What are the biggest backend reliability challenges in this product today?"
- "How do you handle observability for APIs and background jobs?"
- "How are database migrations managed across environments?"
- "What does ownership look like for a developer in the first 3 months?"
