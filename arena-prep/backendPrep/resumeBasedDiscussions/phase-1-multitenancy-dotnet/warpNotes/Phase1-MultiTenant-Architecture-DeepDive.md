# Phase 1 – Multi-Tenant Architecture Deep Dive

## 1. High-Level Architecture Flow

### Primary Request Path (JWT-Authenticated)

```
Client (Browser / Mobile)
  → Kestrel (ASP.NET)
    → CORS Middleware
      → Authentication Middleware (JWT Bearer)
        → Authorization Middleware
          → HttpHeadersMiddleware (security headers only)
            → RequestLogging Middleware (extracts tid for logging)
              → Controller Action
                → Service Layer (scoped)
                  ├─→ AppGlobalContext ──→ Global DB (dm-dev-ngat)
                  │     [Users, Tenants, Accounts, Roles, Permissions]
                  │
                  └─→ ITenantDbContextFactory.DbContext<T>()
                        → IRequestContext.TenantId (from JWT claim)
                          → string.Format(template, tenantGuid)
                            → CryptoUtils.GenerateHash(tenantGuid:secret)
                              → Reflection: T.CreateWithUserContext(options, userCtx, featureMgr)
                                → RollOnDispatchContext ──→ Tenant DB (GUID-named)
                                    [Shipments, DriverLoads, Invoices, Settings, ...]
```

### API Key Authentication Path

```
External Integration (CattlePO)
  → Kestrel
    → ApiKeyAuthenticationHandler
        → Validates key against config["CattlePOIntegration:Api_Key"]
        → Injects ClaimsPrincipal with:
            ├─ Claim("ApiKey", apiKey)
            └─ Claim("tid", config["DefaultTenant"])  ← HARDCODED default tenant
        → RequestContext extracts TenantId from "tid" claim
          → Same path as JWT from here ↓
            → ITenantDbContextFactory → Tenant DB
```

### Hangfire Background Job Path

```
Hangfire Job Trigger
  → BackgroundJobFilter.OnCreating()
      → Captures BackgroundJobContext from thread-local ConcurrentDictionary
      → Serializes TenantId as job parameter

  [Later, on worker thread]

  → CustomHangfireJobActivator.BeginScope()
      → Creates new IServiceScope
      → Reads BackgroundJobContext from job parameters
      → Resolves IRequestContext from scoped container
      → Calls rc.SetBackgroundContext(jc.TenantId)
          → Sets TenantId, UserId=0, Username="BackgroundService"
      → Returns ServiceJobActivatorScope
        → Job executes with tenant context
          → ITenantDbContextFactory resolves normally
```

### Migration Execution Path

```
Developer / CI Pipeline
  → RollOnDispatch.DataMigration (standalone web app)
      → appsettings.json: ConnectionStrings.TenantDatabase
          → Points to ONE specific tenant DB
      → DesignTimeDMContext : IDesignTimeDbContextFactory<RollOnDispatchContext>
          → UseSqlServer(TenantDatabase connection string)
          → AddInterceptors(FeatureFlaggedDBMigrationInterceptor)
      → dotnet ef database update
          → Applies RollOnDispatch.Data/Migrations/* to that single DB

Global DB migrations:
  → TenantManagement project directly
      → AppGlobalContext as the target
      → TenantManagement/Migrations/*
      → Applied against RollOnDispatchDatabase connection string
```

---

## 2. Full Request Lifecycle — Production Trace

Imagine a `GET /api/shipment?include=DriverLoads` from an authenticated dispatcher.

**Step 1 — Kestrel receives the request.**
No tenant awareness yet. Raw HTTP.

**Step 2 — JWT Bearer middleware fires.**
Configured in `Startup.ConfigureServices()` (`RollOnDispatch/Startup.cs:150-170`). Validates signature using `SymmetricSecurityKey` derived from `config["AppSecret"]`. Populates `HttpContext.User` as a `ClaimsPrincipal`. If the token is expired or signature fails, the request short-circuits to 401. The `ClaimsPrincipal` now has claims including `tid` (mapped by Microsoft's JWT handler to `http://schemas.microsoft.com/identity/claims/tenantid`).

**Step 3 — DI scope begins, `RequestContext` is constructed.**
`RequestContext` is registered as **scoped** (`ServiceCollectionExtensions.cs:21`). Its constructor (`RequestContext.cs:22-39`) receives `IHttpContextAccessor`, reads `HttpContext.User`, and sets the `ClaimsUser` property. The setter (`RequestContext.cs:42-93`) extracts:
- `Username` from `ClaimTypes.Email`
- `UserId` from `ClaimTypes.NameIdentifier`
- `TenantId` from `AppGlobals.ClaimTypeTenantIdUri` — **this is the tenant resolution moment**
- `Roles` from `ClaimTypes.Role`
- `Orgs` from custom `org` claim
- `Scopes` from custom `scope` claim

**Critical observation:** If the JWT has no `tid` claim, `TenantId` is `null`. The factory will return `null` for the DbContext. No exception — just a silent `null` that will throw `NullReferenceException` deeper in the stack. This is a latent production risk.

**Step 4 — Controller resolves, service is injected.**
`ShipmentController` injects services that depend on `ITenantDbContextFactory`. The factory itself (`TenantDBContextFactory.cs:29`) takes `AppGlobalContext`, `IConfiguration`, `IRequestContext`, `ILogger`, `IFeatureManager` — all scoped or singleton.

**Step 5 — Service calls `_dbContextFactory.DbContext<RollOnDispatchContext>()`.**
`TenantDBContextFactory.DbContext<T>()` (`TenantDBContextFactory.cs:38-73`):

1. **Cache check:** Looks up `typeof(RollOnDispatchContext)` in `_tenantContext` dictionary. If found, returns the cached instance. This matters because multiple services in the same request share one DbContext — one change tracker, one connection, one transaction boundary.

2. **Null TenantId guard:** If `_requestContext.TenantId` is null, logs a warning and returns `default(T)` (null). This path exists specifically for Hangfire scheduling edge cases where the context might not be set yet.

3. **Empty GUID guard:** If `TenantId == Guid.Empty`, returns null. Defensive check for misconfigured tokens.

4. **Connection string construction:**
   ```
   template = "Server=tcp:...;Initial Catalog={0};...User ID=...;Password=...;"
   formatted = string.Format(template, tenantGuid)
   ```
   The `Initial Catalog` becomes the tenant GUID (e.g., `d432ea85-2322-4850-ab21-97080fd48d83`).

5. **Password generation:** `GenerateTenantDbPass(Guid)` computes `"Tenant:" + HMAC(tenantGuid + ":" + AppSecret)`. Deterministic — same inputs always produce the same password. This means the actual SQL Server login for each tenant DB uses a predictable credential derived from a single secret.

6. **Reflection-based instantiation:** Looks for a static method `CreateWithUserContext` on type `T` via `GetMethod()`. If found, invokes it with `(options, "{userId}-{username}", featureManager)`. Falls back to `Create(options, featureManager)` if the method doesn't exist. This is because `T : DbContext` is generic — no compile-time knowledge of the static factory exists.

7. **Cache storage:** Stores the created context in `_tenantContext[typeof(T)]`.

**Step 6 — Repository queries the tenant database.**
The repository (e.g., in `RollOnDispatch.Data/Repositories/`) uses the DbContext to query `Shipments` with EF Core. SQL goes to the tenant-specific database.

**Step 7 — Cross-database resolution (if needed).**
If the `include` parameter references `Account` (which lives in the global DB), `TenantDbContextFactory.ResolveCrossDbReferences()` is called. It finds all `IAccountHolder` entities tracked by the tenant context, collects their `AccountId`s, and batch-fetches them from `AppGlobalContext.Accounts`. This is a **post-query join across databases** — not a SQL JOIN, but an in-memory resolution.

**Step 8 — Response serialization, scope disposal.**
When the request completes, the DI scope disposes. `TenantDbContextFactory.Dispose()` iterates `_tenantContext` and disposes every cached DbContext. Connections return to pool.

**Where things break in production:**
- Step 3: Missing `tid` claim → silent null → NRE later
- Step 5.4: Connection string format failure if template changes → `FormatException`
- Step 5.5: If `AppSecret` differs between app instances → different passwords → auth failure against SQL
- Step 5.6: If someone renames `CreateWithUserContext` → reflection returns null → falls through to `Create` → loses user audit context silently
- Step 7: N+1 risk if many distinct AccountIds need resolution

---

## 3. Code-Level Deep Dive

### A. Tenant Resolution

**Files:**
- `TenantManagement/Common/RequestContext.cs` — extraction logic
- `TenantManagement/Common/Interfaces/IRequestContext.cs` — contract
- `TenantManagement/Common/AppGlobals.cs` — claim type constants
- `TenantManagement/Services/AuthService.cs:297-304` — claim generation during login

**Claim type mapping:**
At token creation, `AuthService.GenClaimsIdentity()` writes:
```csharp
new Claim(AppGlobals.ClaimTypeTenantId, user.TenantId.ToString())
// where ClaimTypeTenantId = "tid"
```

At extraction, `RequestContext` reads:
```csharp
value.Claims.FirstOrDefault(c => c.Type == AppGlobals.ClaimTypeTenantIdUri)
// where ClaimTypeTenantIdUri = "http://schemas.microsoft.com/identity/claims/tenantid"
```

These are **different strings**. This works because the Microsoft JWT handler automatically maps the short `"tid"` claim to the long URI form. If you ever disable that mapping (e.g., `JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear()`), tenant resolution silently breaks. No exception — `TenantId` just becomes `null`.

**Why not middleware?**
This system embeds tenant extraction inside a scoped DI service constructor rather than a dedicated middleware. The reasoning:

1. The tenant isn't needed before authentication completes. Middleware would need to handle unauthenticated requests defensively.
2. `RequestContext` bundles tenant, user, roles, orgs, and permissions into one object. Separating tenant into middleware would fragment the identity model.
3. It's scoped — the same instance flows through the entire request. Middleware would need to stuff the result into `HttpContext.Items` or a similar bag, adding indirection.

**The trade-off:** You lose the ability to short-circuit requests with an invalid/missing tenant *before* the controller fires. A middleware approach would let you return 400/403 at the pipeline level. Currently, a missing tenant propagates silently until something tries to use it.

**Risks:**
- No validation that the tenant GUID actually exists in the `Tenants` table during resolution. A valid JWT with a deleted tenant's ID will proceed until the SQL query fails.
- `ApiKeyAuthenticationHandler` uses `config["DefaultTenant"]` — a single hardcoded tenant for all API key integrations. If multiple integrations need different tenants, this design doesn't support it.

### B. Dynamic Connection String Construction

**Template:**
```json
"TenantDatabase": "Server=tcp:dm-dev-ngat-dbserver.database.windows.net,1433;Initial Catalog={0};..."
```

`{0}` is replaced by the tenant GUID. The database name *is* the tenant GUID.

**HMAC password generation:**
```csharp
protected string GenerateTenantDbPass(Guid tenant)
{
    var secret = _config["AppSecret"];
    return "Tenant:" + CryptoUtils.GenerateHash($"{tenant}:{secret}");
}
```

**Risks of deterministic credentials:**
- **Secret rotation is catastrophic.** Changing `AppSecret` changes every tenant's database password simultaneously. You'd need to rotate all SQL logins in lockstep, which means downtime proportional to tenant count unless you build a dual-password migration.
- **Lateral movement.** If an attacker obtains `AppSecret` and the tenant GUID list (from the global DB), they can compute every tenant's database password offline. No per-tenant secret isolation.
- **Same password across environments.** If dev and staging share the same `AppSecret`, they generate identical credentials. An accidental connection string pointing at production would authenticate.

**Connection pooling implications:**
Each unique connection string gets its own pool in ADO.NET. With database-per-tenant, you get **N pools for N tenants**. Under load:
- Default pool size is 100 connections per unique string
- 500 tenants = 500 pools = theoretical max of 50,000 connections
- Azure SQL has hard limits per server (depends on tier)
- Pool fragmentation means each tenant's pool may hold idle connections while others starve

In practice, pools are lazily created and trimmed, but the ceiling is real. At scale, you'd need to either shard across multiple SQL servers or use elastic pools.

### C. Reflection-Based DbContext Instantiation

**Why reflection?**
`TenantDbContextFactory` is generic: `T DbContext<T>() where T : DbContext`. The constraint is `DbContext` — which doesn't define `CreateWithUserContext` or `Create`. These are **static methods on the concrete type** (e.g., `RollOnDispatchContext`).

In C# at the time this was written, you couldn't express "T must have a static method with this signature" in a generic constraint. So reflection is the escape hatch.

**What breaks silently:**
```csharp
var createMethod = typeof(T).GetMethod(TENANT_CONTEXT_WITH_USER_CONTEXT_FACTORY_METHOD_NAME, BindingFlags.Public | BindingFlags.Static);
if (createMethod != null)
{
    _tenantContext[typeof(T)] = (DbContext)createMethod.Invoke(null, [...]);
}
else
{
    _tenantContext[typeof(T)] = (DbContext)typeof(T).GetMethod(TENANT_CONTEXT_FACTORY_METHOD_NAME, ...).Invoke(null, [...]);
}
```

If someone renames `CreateWithUserContext` to `CreateWithContext`, the first `GetMethod` returns null, falls through to `Create`, and **the user audit context is silently lost**. `CreatedBy`/`ModifiedBy` fields in the audit trail would be null. No compile error, no runtime exception.

If both methods are missing, the fallback `GetMethod` returns null, and `.Invoke()` on null throws `NullReferenceException` — a cryptic error with no indication that the factory method name is wrong.

**Modern alternative (C# 11+):**
```csharp
public interface ITenantContext<T> where T : DbContext
{
    static abstract T CreateWithUserContext(DbContextOptions options, string userContext, IFeatureManager fm);
}
```

Then constrain the factory:
```csharp
public T DbContext<T>() where T : DbContext, ITenantContext<T>
```

Compile-time safety. No reflection. Renaming the method is a build error.

### D. Hangfire Tenant Context Propagation

**The problem:** Hangfire jobs run on background threads, outside the HTTP request pipeline. There's no `HttpContext`, no JWT, no `ClaimsPrincipal`. Yet they need tenant context.

**The mechanism:**

1. **At enqueue time** — the caller creates a `BackgroundJobContext(tenantId)`, which stores itself in a `static ConcurrentDictionary<int, BackgroundJobContext>` keyed by `Thread.ManagedThreadId` (`HangfireTenantContext.cs:26`).

2. **`BackgroundJobFilter.OnCreating()`** — this Hangfire filter runs on the enqueueing thread, reads the `BackgroundJobContext` from the thread-local dictionary, and serializes it into the job's parameters (`HangfireTenantContext.cs:64-68`).

3. **At execution time** — `CustomHangfireJobActivator.BeginScope()` creates a DI scope, deserializes the `BackgroundJobContext` from job parameters, and calls `IRequestContext.SetBackgroundContext(tenantId)` (`HangfireTenantContext.cs:106-119`).

**Risks of tenant leakage:**
- `ConcurrentDictionary` is keyed by `ManagedThreadId`. Thread pool reuse means the same thread ID can be reused for different tenants. If `BackgroundJobContext.Dispose()` (which calls `ClearContext()`) is missed (e.g., exception before the `using` block), a subsequent job on the same thread could inherit the wrong tenant's context.
- The `using var jc = new BackgroundJobContext(tenantId);` pattern used throughout (`TenantCornJobService.cs:33,39,53,...`) is correct, but a single miss is a **cross-tenant data breach**.

**Idempotency concerns:**
- If a Hangfire job fails and retries, it re-reads the tenant ID from job parameters — this is safe.
- But if the job has side effects (e.g., email sent, cron job registered), retry may duplicate them. There's no deduplication mechanism visible in the codebase.

---

## 4. Migration Strategy Analysis

### Current Architecture

```
Two migration tracks, two EF contexts, two target databases:

Track 1: Global DB (AppGlobalContext)
  Source:  TenantManagement/Migrations/
  Target:  ConnectionStrings.RollOnDispatchDatabase
  Applied: Standard EF tooling against one DB

Track 2: Tenant DB (RollOnDispatchContext)
  Source:  RollOnDispatch.Data/Migrations/
  Host:    RollOnDispatch.DataMigration/ (separate web app project)
  Target:  ConnectionStrings.TenantDatabase (pointed at ONE tenant)
  Applied: Manually, per-tenant, by changing the connection string
```

### Why Not Auto-Migrate at Startup?

Running `context.Database.MigrateAsync()` at startup for every tenant has several fatal problems:

1. **Startup time scales linearly with tenant count.** 100 tenants × 30 seconds per migration = 50 minutes before the app accepts traffic. Load balancer health checks would kill the instance.

2. **Concurrent instance danger.** In a multi-instance deployment (which this app uses — it's containerized per the `Dockerfile`), two instances starting simultaneously would both try to migrate the same tenant DBs. EF's migration lock (`__EFMigrationsHistory`) prevents duplicate application, but the contention causes timeouts, deadlocks, and unpredictable startup failures.

3. **Partial failure is unrecoverable.** If instance starts, migrates 47 of 100 tenants, then crashes — which 47? The remaining 53 are on an older schema. The app is now in an inconsistent state with no record of what happened.

4. **Feature-flagged migrations.** This codebase uses `FeatureFlaggedDBMigrationInterceptor` — migrations can be conditionally applied based on feature flags. Auto-migrate at startup wouldn't respect these flags correctly across environments.

### How This Scales

**At 100 tenants:** Manageable. CI/CD pipeline can loop through connection strings. Takes minutes. Manual intervention for failures is feasible.

**At 1,000 tenants:** Pipeline takes hours. Need parallelization. Failures require automated retry logic. Need a migration status dashboard to track which tenants are current.

**What breaks at 1,000+:**
- The `RollOnDispatch.DataMigration` project points to a single connection string. There's no loop, no tenant discovery, no status tracking. Someone must manually run it N times or write a script that iterates the `Tenants` table and runs migrations against each.
- Azure SQL server connection limits become a concern during mass migration events.
- No rollback strategy if a migration succeeds on 800 tenants and fails on 200.

### Migration Orchestration Flow (What Should Exist)

```
CI/CD Pipeline
  → Build migration bundle
    → Query Global DB: SELECT TenantId FROM Tenants
      → For each tenant (parallel, with concurrency limit):
          → Format connection string with TenantId
          → Apply migrations
          → Record result in MigrationLog table
      → Report: X succeeded, Y failed, Z skipped (already current)
        → Failed tenants → retry queue
          → After retries → alert on-call
```

This does not exist in the current codebase. Migration orchestration is entirely manual.

---

## 5. Operational Trade-Offs

### Advantages of Database-Per-Tenant

**Hard isolation.** One tenant's data literally cannot leak to another through an application bug. A missing `WHERE TenantId = @tid` filter — the most common multi-tenant vulnerability — is structurally impossible because the query runs against a database that only contains that tenant's data.

**Independent backup/restore.** You can restore Tenant A's database to a point-in-time without affecting Tenant B. With a shared database, point-in-time restore affects everyone.

**Blast radius containment.** A runaway query from one tenant can't lock tables that other tenants use. Deadlocks are tenant-scoped. A corrupt index only affects one tenant.

**Compliance simplicity.** Data residency requirements (GDPR, SOC2) are easier when you can point to a physically separate database per customer. "Tenant X's data is in this database, in this region, with this encryption key" is auditable.

**Per-tenant scaling.** A high-volume tenant can be moved to a higher tier without over-provisioning the shared infrastructure.

### Disadvantages

**Migration orchestration complexity.** Every schema change must be applied N times. There's no mechanism in this codebase for tracking migration state across tenants, retrying failures, or detecting version drift.

**Cross-tenant reporting is nearly impossible.** If the business needs "total shipments across all tenants this month," there's no single query that can answer it. You'd need to query each tenant DB individually and aggregate. The codebase has no infrastructure for this.

**Infrastructure cost.** Azure SQL charges per database (DTU or vCore). 500 tenants = 500 databases. Even at the Basic tier ($5/month), that's $2,500/month in database costs alone, before any performance considerations.

**Connection pool fragmentation.** As discussed in Section 3B. Each unique connection string gets its own pool. High tenant count + bursty traffic = many pools with few active connections each. ADO.NET's pool manager doesn't redistribute across pools.

### Real-World Edge Cases

**One tenant DB is slow — how is it detected?**
Currently: not detected proactively. There's no per-tenant health check, no query performance tracking per database, no alerting on per-tenant latency. The `RequestLogging` middleware logs the tenant ID with each request, so you could grep logs, but there's no automated monitoring. A slow tenant DB manifests as slow API responses for that tenant's users — and the only signal is user complaints.

**AppSecret rotation:**
Changing `AppSecret` simultaneously invalidates:
1. Every tenant's database password (computed via HMAC)
2. Every active JWT (signed with key derived from `AppSecret`)
3. Every refresh token (hashed with `AppSecret`-derived key)

There's no dual-key support. Rotation requires: update all tenant SQL logins, update config, restart all instances, force all users to re-authenticate — in a coordinated, zero-downtime window. In practice, this means `AppSecret` is effectively permanent.

**Tenant DB version drift:**
If a migration fails on 3 out of 100 tenants, those 3 are on an older schema. The application code assumes all tenants are on the latest schema. EF Core will throw at runtime when it encounters missing columns or tables — but only for those 3 tenants. The other 97 work fine. Detecting this requires checking `__EFMigrationsHistory` across every tenant DB.

---

## 6. Security Analysis

### Deterministic Password Generation

```csharp
"Tenant:" + CryptoUtils.GenerateHash($"{tenantGuid}:{AppSecret}")
```

**If `AppSecret` leaks:**
An attacker with the secret and the tenant list (obtainable from the global DB's `Tenants` table) can compute every tenant database password offline. No brute force needed. The entire fleet is compromised from a single secret.

**If the global DB is compromised:**
The global DB contains:
- All tenant GUIDs (`Tenants` table)
- All user credentials (hashed, but present)
- All account associations
- Connection mapping data

Combined with `AppSecret` (which might be in the same config or Key Vault), this gives full access to every tenant database.

**Lateral movement path:**
```
Compromise Global DB
  → Read Tenants table → list of all tenant GUIDs
  → If AppSecret is in appsettings.json (it is, in dev):
      → Compute HMAC for each tenant → all DB passwords
        → Direct SQL access to every tenant DB
          → Full data exfiltration
```

**The connection string template includes the SQL server hostname and port.** An attacker who reads `appsettings.json` has everything needed to connect directly to any tenant database, bypassing the application entirely.

### Better Alternatives

**Azure Managed Identity:** Eliminate passwords entirely. The app authenticates to SQL via AAD token. No secrets to leak, no passwords to rotate. Per-database access is controlled by AAD role assignments.

**Azure Key Vault with per-tenant secrets:** Each tenant's DB credentials are stored as a separate Key Vault secret. Compromise of one tenant's secret doesn't affect others. Rotation is per-tenant.

**Contained database users with random passwords:** Generate a cryptographically random password per tenant at provisioning time, store it in Key Vault, and retrieve it at runtime. Not deterministic — compromising one doesn't reveal others.

---

## 7. Scaling Evolution Strategy

### Why Database-Per-Tenant Fails at Scale

The current architecture works well for dozens to low hundreds of tenants. It degrades in specific ways:

**At ~500 tenants:** Azure SQL server connection limits become a concern. Default is 300 concurrent connections per server. Even with connection pooling, mass migration or batch operations can saturate this.

**At ~2,000 tenants:** Management overhead dominates. No human can manually verify 2,000 databases are on the correct schema version, performing adequately, and backed up. Automation is mandatory but doesn't exist in this codebase.

**At ~10,000+ tenants:** Cost becomes prohibitive. Infrastructure management becomes a full-time engineering effort. The Azure portal becomes unusable for database management at this scale.

### Why Single Shared Database Fails

A single database with `TenantId` column on every table:
- Every query must filter by `TenantId`. One missing filter = cross-tenant data leak.
- One tenant's expensive query blocks everyone (noisy neighbor).
- Database size grows unbounded — backup/restore affects all tenants.
- Data residency compliance is impossible.

### The Hybrid/Sharded Middle Ground

```
Incoming Request
  → Tenant ID (from JWT)
    → Shard Map Lookup (Global DB / Cache)
        │
        ├─ Tier: "Dedicated"
        │    → Dedicated SQL DB for this tenant
        │       (high-value / high-volume customers)
        │
        ├─ Tier: "Standard"
        │    → Shard DB #N (shared, partitioned by TenantId)
        │       → All queries include WHERE TenantId = @tid
        │       → ~50-200 tenants per shard
        │
        └─ Tier: "Free/Trial"
             → Shared Trial DB
                → Aggressive resource limits
                → Data purged after trial expiry
```

**The shard map** is a table in the global DB:

```
ShardMap:
  TenantId (GUID) | ShardId (int) | ConnectionString (encrypted) | Tier (enum)
```

**Why this works at scale:**
- Dedicated tenants get full isolation (same as today)
- Standard tenants share infrastructure (cost-efficient) but are isolated per-shard (blast radius limited to ~100 tenants)
- Trial tenants share a single cheap database
- Shard rebalancing is possible — move a tenant from shared to dedicated when they upgrade
- Migration orchestration only needs to hit ~N shards, not N tenants

**What changes in the codebase:**
`TenantDbContextFactory.DbContext<T>()` would look up the shard map instead of formatting a GUID into the connection string. Everything downstream (repositories, services) stays the same.

---

## 8. Modernization Opportunities

### Remove Reflection

Replace the current reflection-based factory with static abstract interface members (C# 11 / .NET 7+):

```csharp
public interface ITenantDbContext<TSelf> where TSelf : DbContext
{
    static abstract TSelf CreateWithUserContext(
        DbContextOptions options, string userContext, IFeatureManager fm);
}

// RollOnDispatchContext implements:
public class RollOnDispatchContext : AuditDbContextBase, ITenantDbContext<RollOnDispatchContext>
{
    public static RollOnDispatchContext CreateWithUserContext(...) { ... }
}
```

The factory constraint becomes `where T : DbContext, ITenantDbContext<T>`. Compile-time safety, no reflection, rename-proof.

### Introduce Shard Abstraction Layer

Create an `IShardResolver` that replaces the direct `string.Format()` in `TenantDbContextFactory`:

```csharp
public interface IShardResolver
{
    Task<string> GetConnectionStringForTenant(Guid tenantId);
}
```

Default implementation preserves current behavior. Shard-aware implementation looks up the shard map. The factory doesn't need to know the topology.

### Managed Identity for DB Auth

Replace `GenerateTenantDbPass()` entirely. Use `DefaultAzureCredential` to obtain an AAD token, set it on the SQL connection. No passwords in config, no HMAC, no rotation problem.

### Distributed Tracing

Add `TenantId` as a trace tag to every request. Use Application Insights or OpenTelemetry to correlate per-tenant latency, error rates, and throughput. Currently, the only observability is grep-friendly log lines from `RequestLogging` middleware — no structured metrics.

### Health Monitoring Per Tenant DB

A background service that periodically:
1. Queries each tenant DB with `SELECT 1`
2. Checks `__EFMigrationsHistory` for schema version
3. Reports metrics: latency, version, last successful check
4. Alerts on drift, unreachability, or degraded performance

### Migration Orchestration Service

A dedicated service or Azure Function that:
1. Reads the tenant list from the global DB
2. Applies pending migrations in parallel (with concurrency limits)
3. Records results per tenant
4. Retries failures with exponential backoff
5. Exposes a dashboard: "95% of tenants on v47, 5% on v46, 2 failed"

This replaces the current manual `RollOnDispatch.DataMigration` approach and is the single most impactful operational improvement for this system.
