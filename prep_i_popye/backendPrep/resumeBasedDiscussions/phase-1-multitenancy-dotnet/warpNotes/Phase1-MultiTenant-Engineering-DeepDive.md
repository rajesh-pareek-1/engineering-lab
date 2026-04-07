# Phase 1 – Multi-Tenant Architecture (Engineering Deep Dive)

## 1. High-Level Architecture

```
HTTP Request (with JWT Bearer token)
  → Kestrel
    → JWT Authentication Middleware
      → ClaimsPrincipal populated with tid, email, roles
        → RequestContext (scoped — extracts TenantId from claims)
          → Controller / Service Layer
            ├── AppGlobalContext ──→ Shared Global DB
            │     [Tenants, Users, Accounts, Roles, Permissions]
            │
            └── ITenantDbContextFactory.DbContext<T>()
                  → Reads TenantId from RequestContext
                    → Formats connection string: Initial Catalog = {TenantGuid}
                      → Generates HMAC-based password
                        → Reflection: T.CreateWithUserContext(options, userCtx, featureMgr)
                          → RollOnDispatchContext ──→ Tenant-Specific SQL DB
                              [Shipments, DriverLoads, Invoices, Settings, ...]

Background Jobs (Hangfire):
  Enqueue time:
    → BackgroundJobContext(tenantId) stored in thread-local dictionary
      → BackgroundJobFilter serializes TenantId into job parameters

  Execution time:
    → CustomHangfireJobActivator reads TenantId from job parameters
      → Calls IRequestContext.SetBackgroundContext(tenantId)
        → Same factory path as HTTP requests from here
```

Two databases per tenant relationship:
- **One shared global DB** — identity, auth, tenant registry, cross-tenant config
- **One DB per tenant** — all business data, named by tenant GUID (e.g., `d432ea85-2322-4850-ab21-97080fd48d83`)

---

## 2. Full Request Lifecycle

### Step 1 — JWT Authentication

Configured in `RollOnDispatch/Startup.cs:150-170`. The middleware validates the token signature using a symmetric key derived from `config["AppSecret"]`, checks issuer/audience, and populates `HttpContext.User`.

The JWT contains a `tid` claim written at login time:

```csharp
// TenantManagement/Services/AuthService.cs:297-304
new Claim(AppGlobals.ClaimTypeTenantId, user.TenantId.ToString())
// ClaimTypeTenantId = "tid"
```

Microsoft's JWT handler automatically maps `"tid"` → `"http://schemas.microsoft.com/identity/claims/tenantid"`. This mapping is implicit and undocumented in the codebase.

### Step 2 — RequestContext Construction

`RequestContext` is registered as **scoped** (`TenantManagement/Extensions/ServiceCollectionExtensions.cs:21`):

```csharp
services.AddScoped<IRequestContext, RequestContext>();
```

Its constructor reads `HttpContext.User` and the `ClaimsUser` setter extracts tenant:

```csharp
// TenantManagement/Common/RequestContext.cs:60-62
var tenant = value.Claims.FirstOrDefault(c => c.Type == AppGlobals.ClaimTypeTenantIdUri);
TenantId = tenant != null ? Guid.Parse(tenant.Value) : null;
```

One `RequestContext` instance lives for the entire HTTP request. Every service that injects `IRequestContext` gets the same instance with the same `TenantId`.

### Step 3 — Dynamic Connection String Construction

When a service needs tenant data, it calls `ITenantDbContextFactory.DbContext<RollOnDispatchContext>()`.

The factory (`TenantManagement/Data/TenantDBContextFactory.cs:52-54`) builds the connection string:

```csharp
var connectionString = _config.GetConnectionString("TenantDatabase");
// Template: "Server=tcp:...;Initial Catalog={0};...Password=...;"
optionsBuilder.UseSqlServer(
    string.Format(connectionString, _requestContext.TenantId, GenerateTenantDbPass(_requestContext.TenantId.Value))
);
```

The database name is the tenant GUID. The password is deterministic:

```csharp
// TenantDBContextFactory.cs:124-128
protected string GenerateTenantDbPass(Guid tenant)
{
    var secret = _config["AppSecret"];
    return "Tenant:" + CryptoUtils.GenerateHash($"{tenant}:{secret}");
}
```

Same tenant GUID + same AppSecret = same password every time. No per-tenant secret storage needed.

### Step 4 — DbContext Instantiation

The factory creates the `RollOnDispatchContext` via reflection (explained in Section 3) and caches it in a per-request dictionary:

```csharp
// TenantDBContextFactory.cs:40-43
if (_tenantContext.ContainsKey(typeof(T)))
{
    return (T)Convert.ChangeType(_tenantContext[typeof(T)], typeof(T));
}
```

If two services in the same request both call `DbContext<RollOnDispatchContext>()`, they get the **same instance**. This means:
- One change tracker — entities loaded by one service are visible to another
- One connection — multiple operations can share a transaction
- No redundant connection string formatting or reflection

### Step 5 — Why Scoped, Not Singleton

`TenantDbContextFactory` is scoped because:
- **Different requests have different tenants.** A singleton would need to be thread-safe and would cache contexts across tenants — a data leak waiting to happen.
- **DbContext is not thread-safe.** EF Core DbContext must not be shared across concurrent requests. Scoped lifetime guarantees one instance per request.
- **Disposal is automatic.** When the DI scope ends (request completes), `TenantDbContextFactory.Dispose()` cleans up all cached DbContexts and returns connections to the pool.

The global DB context (`AppGlobalContext`) is registered via `AddDbContextPool` — pooled but still scoped per request. Pooling reuses the object but resets its state between requests.

---

## 3. Reflection-Based DbContext Instantiation

### The Problem It Solves

`TenantDbContextFactory` is generic — `T DbContext<T>() where T : DbContext`. It doesn't know at compile time which concrete DbContext `T` is. The `RollOnDispatchContext` has a static factory method:

```csharp
// RollOnDispatch.Data/RollOnDispatchContext.cs:19-24
public static RollOnDispatchContext CreateWithUserContext(
    DbContextOptions options, string userContext, IFeatureManager featureManager)
{
    var dbcontext = new RollOnDispatchContext((DbContextOptions<RollOnDispatchContext>)options);
    dbcontext.UserContext = userContext;
    return dbcontext;
}
```

This method sets `UserContext` — used by `AuditDbContextBase` to populate `CreatedBy`/`ModifiedBy` on every entity save. It's a static method on the concrete type, not on `DbContext` or any interface. You can't call it through a generic constraint.

### How Reflection Bridges the Gap

```csharp
// TenantDBContextFactory.cs:55-63
var createMethod = typeof(T).GetMethod("CreateWithUserContext", BindingFlags.Public | BindingFlags.Static);
if (createMethod != null)
{
    _tenantContext[typeof(T)] = (DbContext)createMethod.Invoke(null,
        [optionsBuilder.Options, $"{_requestContext.UserId}-{_requestContext.Username}", _featureManager]);
}
else
{
    // Fallback: call Create(options, featureManager) instead
    _tenantContext[typeof(T)] = (DbContext)typeof(T)
        .GetMethod("Create", BindingFlags.Public | BindingFlags.Static)
        .Invoke(null, new object[] { optionsBuilder.Options, _featureManager });
}
```

The factory looks up the method by name at runtime. If `CreateWithUserContext` exists, it's called with user context for audit. If not, it falls back to `Create` without user context.

### Risks

- **Silent fallback.** If `CreateWithUserContext` is renamed, the factory silently falls through to `Create`. The audit trail loses `CreatedBy`/`ModifiedBy` — no exception, no log, no compile error.
- **Null method crash.** If both methods are missing, `GetMethod` returns null and `.Invoke()` throws `NullReferenceException` — a cryptic error with no indication that the factory method is missing.
- **Signature changes.** If someone adds or removes a parameter, it throws `TargetParameterCountException` at runtime — only when that code path is hit in production.

### Why It Was Done This Way

At the C# version this was written in, there was no way to express "T must have a static method with this signature" in a generic constraint. Interfaces couldn't have static members. Reflection was the only mechanism to call a static method on an unknown type `T`.

---

## 4. Hangfire Tenant Propagation

### The Problem

Hangfire jobs run on background threads with no `HttpContext`, no JWT, no `ClaimsPrincipal`. But they need to know which tenant's database to operate on.

### How TenantId Flows Into Jobs

**At enqueue time** — the caller wraps the operation in a `BackgroundJobContext`:

```csharp
// TenantManagement/Common/HangfireTenantContext.cs:41-44
public BackgroundJobContext(Guid tenantId)
{
    TenantId = tenantId;
    SetContext(this);  // stores in ConcurrentDictionary keyed by Thread.ManagedThreadId
}
```

**`BackgroundJobFilter.OnCreating()`** runs on the same thread, reads the context, and serializes it into the job:

```csharp
// HangfireTenantContext.cs:64-68
public void OnCreating(CreatingContext filterContext)
{
    var jc = BackgroundJobContext.GetContext();
    filterContext.SetJobParameter(nameof(BackgroundJobContext), jc);
}
```

**At execution time** — the custom job activator reads it back:

```csharp
// HangfireTenantContext.cs:106-116
public override JobActivatorScope BeginScope(JobActivatorContext context)
{
    var serviceScope = _serviceScopeFactory.CreateScope();
    var jc = context.GetJobParameter<BackgroundJobContext>(nameof(BackgroundJobContext));
    if (jc != null)
    {
        var rc = serviceScope.ServiceProvider.GetRequiredService<IRequestContext>();
        rc.SetBackgroundContext(jc.TenantId);
    }
    return new ServiceJobActivatorScope(serviceScope);
}
```

`SetBackgroundContext` sets `TenantId`, `UserId = 0`, and `Username = "BackgroundService"`:

```csharp
// RequestContext.cs:108-114
public void SetBackgroundContext(Guid tenantId)
{
    TenantId = tenantId;
    UserId = 0;
    Username = "BackgroundService";
    Roles = new List<string>() { "BackgroundService" };
}
```

From here, `TenantDbContextFactory` works identically to the HTTP path — it reads `TenantId` from `IRequestContext` and builds the connection string.

### Why Thread-Local Storage

The `BackgroundJobContext` needs to survive from the moment it's created (in the calling code) to when `BackgroundJobFilter.OnCreating()` fires (in Hangfire's pipeline). These happen on the **same thread** synchronously — so a `ConcurrentDictionary<int, BackgroundJobContext>` keyed by `ManagedThreadId` works as a simple handoff mechanism.

The pattern used throughout the codebase is:

```csharp
// RollOnDispatch/Services/TenantCornJobService.cs:33-34
using var jc = new BackgroundJobContext(tenantId);
RecurringJob.AddOrUpdate<TenantCornJobService>(...);
```

The `using` ensures `ClearContext()` is called after the enqueue completes, removing the entry from the dictionary.

### Risks

- **Missed disposal.** If an exception occurs between `new BackgroundJobContext(tenantId)` and the `using` block's dispose, the dictionary retains a stale entry. The next job enqueued on that thread could inherit the wrong tenant.
- **Thread reuse.** Thread pool threads are reused. A stale entry from a previous operation could leak into an unrelated enqueue.
- **Async boundaries.** `ManagedThreadId` can change across `await`. If async code creates a `BackgroundJobContext` and then awaits before enqueuing, the filter might run on a different thread and miss the context.

In practice, these risks are mitigated by the consistent `using var jc = ...` pattern and the fact that enqueue calls are synchronous. But the mechanism is fragile — a single deviation from the pattern could cause cross-tenant data access.

---

## 5. Why Database-Per-Tenant Was Chosen

### Data Isolation

Each tenant's business data (shipments, driver loads, invoices, settings) lives in a physically separate SQL database. This eliminates an entire class of bugs:
- A missing `WHERE TenantId = @tid` filter can't leak data — there's no other tenant's data in the database to leak.
- A full table scan on one tenant's data doesn't touch another tenant's rows.
- SQL-level access controls are per-database, not per-row.

### Performance

- **No noisy neighbor.** A heavy query from Tenant A doesn't lock tables that Tenant B uses. Deadlocks are tenant-scoped.
- **Per-tenant indexing.** Each database has its own indexes optimized for that tenant's data volume. A tenant with 100 shipments and a tenant with 100,000 shipments don't share the same index.
- **Connection isolation.** Each tenant's connection pool is independent. One tenant exhausting connections doesn't starve others.

### Operational Benefits

- **Independent backup/restore.** Restoring Tenant A to yesterday doesn't affect Tenant B.
- **Tenant-level maintenance.** Index rebuilds, statistics updates, and shrink operations are per-tenant. A maintenance window for one tenant doesn't require downtime for others.
- **Simple deletion.** Offboarding a tenant is `DROP DATABASE`. No need to audit every table for orphaned rows.
- **Compliance.** Data residency and audit requirements are straightforward — each tenant's data is in exactly one database.

---

## 6. Trade-offs

### Operational Overhead

- **Every schema change must be applied N times.** The `RollOnDispatch.DataMigration` project targets a single connection string. There's no built-in loop over tenants, no status tracking, no parallelization.
- **Schema drift is invisible.** If a migration fails on 3 of 100 tenants, those 3 are on an older schema. The app assumes all tenants are current. EF Core will throw at runtime — but only for those 3 tenants, on requests that touch the changed tables.
- **Monitoring is per-tenant.** No aggregated view of database health across tenants. A slow tenant DB is only detected when users complain.

### Migration Management

- **Two migration tracks.** Global DB migrations in `TenantManagement/Migrations/`, tenant DB migrations in `RollOnDispatch.Data/Migrations/`. Different EF contexts, different connection strings, different deployment steps.
- **No auto-migration at startup.** The app doesn't run `Database.MigrateAsync()` on boot. This is deliberate — startup would scale linearly with tenant count, and concurrent instances would contend on the same databases. But it means migrations are a manual step.
- **Feature-flagged migrations.** The `DesignTimeDMContext` in `RollOnDispatch.DataMigration/Startup.cs:38-51` adds a `FeatureFlaggedDBMigrationInterceptor`. Some migrations are conditionally applied based on feature flags, adding another dimension to track.

### Cost

- Azure SQL charges per database. At scale, this is the dominant cost driver. 100 tenants at the Basic tier (~$5/mo each) = $500/month just for tenant databases, plus the global DB. Premium tiers multiply this significantly.
- Connection pool memory scales with tenant count. Each unique connection string maintains its own pool in ADO.NET.

### Schema Duplication

- Every tenant database has the exact same schema — the same tables, indexes, constraints, and stored procedures. There's no mechanism to give one tenant a different schema version (other than failed migrations, which is a bug, not a feature).
- Adding a column to one table means adding it to every tenant database. At 100 tenants, this is a 100-database deployment.

### Cross-Tenant Operations

- There's no single query that spans tenant data. Reporting across tenants requires iterating each database individually.
- Cross-database references (e.g., `Account` in the global DB referenced from tenant data) are resolved in-memory after querying, via `AppGlobalContext.ResolveAccounts()` — not via SQL JOINs.

---

## Key File Reference

| Concern | File |
|---------|------|
| JWT setup | `RollOnDispatch/Startup.cs:150-170` |
| Claim constants | `TenantManagement/Common/AppGlobals.cs` |
| Tenant extraction | `TenantManagement/Common/RequestContext.cs:60-62` |
| IRequestContext contract | `TenantManagement/Common/Interfaces/IRequestContext.cs` |
| Connection string template | `RollOnDispatch/appsettings.json:12` |
| DbContext factory | `TenantManagement/Data/TenantDBContextFactory.cs` |
| Factory interface | `TenantManagement/Data/Interfaces/ITenantDBContextFactory.cs` |
| Tenant DbContext | `RollOnDispatch.Data/RollOnDispatchContext.cs` |
| Global DbContext | `TenantManagement/Data/AppGlobalContext.cs` |
| Audit base class | `TenantManagement/Data/AuditDbContextBase.cs` |
| Hangfire context | `TenantManagement/Common/HangfireTenantContext.cs` |
| Service registration | `TenantManagement/Extensions/ServiceCollectionExtensions.cs` |
| DB registration | `TenantManagement/Extensions/ServiceCollectionDBContextExtensions.cs` |
| Tenant entity | `TenantManagement/Data/Entities/Tenant.cs` |
| Provisioning service | `TenantManagement/Services/TenantProvisioningService.cs` |
| Migration host | `RollOnDispatch.DataMigration/Startup.cs` |
| Cron job setup | `RollOnDispatch/Services/TenantCornJobService.cs` |
| API key auth | `RollOnDispatch/ApiKeyAuth/ApiKeyAuthenticationHandler.cs` |
