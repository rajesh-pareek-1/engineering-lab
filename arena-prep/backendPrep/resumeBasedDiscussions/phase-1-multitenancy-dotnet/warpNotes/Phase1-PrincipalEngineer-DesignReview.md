# Principal Engineer Design Review — Top 5 Weaknesses & Redesign Proposals

## 1. Single Secret Catastrophe (`AppSecret`)

**The problem:** `AppSecret` is a god-key. It simultaneously:
- Signs every JWT
- Derives every tenant DB password via HMAC
- Hashes refresh tokens

Compromise of this one value gives an attacker full access to every tenant database, every user session, and the ability to forge tokens for any user. Rotation is operationally impossible without coordinated downtime across all tenants.

**What I'd change:**

Separate the concerns into three independent secrets with different lifecycles:

- **JWT signing** → Asymmetric keys (RSA/ECDSA). Rotate by publishing new public key to JWKS endpoint. Old tokens validate until expiry. Zero downtime.
- **DB authentication** → Azure Managed Identity. Eliminate passwords entirely. The app authenticates to SQL via AAD token. No secret to leak, no rotation problem. If Managed Identity isn't possible yet, store per-tenant random credentials in Key Vault — breaking the deterministic HMAC chain so that compromising one tenant doesn't reveal others.
- **Refresh tokens** → Use opaque random tokens stored server-side (already partially done). Decouple from `AppSecret`.

This turns one catastrophic blast radius into three independent, rotatable concerns.

---

## 2. Silent Null Propagation on Missing Tenant

**The problem:** If a JWT has no `tid` claim, or the claim is malformed, `RequestContext` sets `TenantId = null`. `TenantDbContextFactory` returns `null`. No exception, no 400, no log at the point of failure. The `NullReferenceException` surfaces deep in a repository or service — with a stack trace that tells you nothing about the root cause.

This also means a deleted tenant whose GUID is still in an active JWT will successfully resolve through the factory, format a connection string, and fail only when SQL Server rejects the connection to a non-existent database — with a `SqlException` that looks like an infra problem, not a tenant problem.

**What I'd change:**

Add a tenant validation middleware after authentication:

```csharp
public class TenantValidationMiddleware
{
    public async Task InvokeAsync(HttpContext context, IRequestContext reqCtx)
    {
        if (context.User.Identity?.IsAuthenticated == true && reqCtx.TenantId == null)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(new { error = "Missing tenant claim" });
            return;
        }
        await _next(context);
    }
}
```

Fail fast, fail loud, at the pipeline level. Optionally validate the tenant GUID exists in a cached set from the global DB (refreshed every few minutes) to catch deleted-tenant scenarios before they hit SQL.

---

## 3. Reflection-Based Factory With No Safety Net

**The problem:** The `TenantDbContextFactory` uses `GetMethod("CreateWithUserContext")` by string name. Three failure modes, all silent or cryptic:

- Method renamed → falls through to `Create` → audit trail loses user context. No error.
- Both methods removed → `NullReferenceException` on `.Invoke()`. Stack trace points to reflection internals, not the actual problem.
- Method signature changed → `TargetParameterCountException` at runtime. Only caught in production if that code path is hit.

No unit test can catch a rename unless the test explicitly calls the factory with a real DbContext type — and even then, it only catches complete removal, not the silent fallback.

**What I'd change:**

Two options depending on the .NET version:

**If on .NET 7+:** Use static abstract interface members. Compile-time enforcement. The factory becomes:

```csharp
public T DbContext<T>() where T : DbContext, ITenantDbContext<T>
{
    // ...
    var ctx = T.CreateWithUserContext(optionsBuilder.Options, userContext, _featureManager);
    _tenantContext[typeof(T)] = ctx;
}
```

**If stuck on older .NET:** Replace reflection with an explicit registration model. At startup, register a `Func<DbContextOptions, string, IFeatureManager, T>` factory delegate per concrete type:

```csharp
services.AddScoped<ITenantDbContextFactory>(sp =>
{
    var factory = new TenantDbContextFactory(/* ... */);
    factory.Register<RollOnDispatchContext>(
        (opts, user, fm) => RollOnDispatchContext.CreateWithUserContext(opts, user, fm));
    return factory;
});
```

Compile-time binding. If `CreateWithUserContext` is renamed, the registration fails to compile.

---

## 4. Thread-Local Hangfire Context Is a Tenant Leakage Vector

**The problem:** `BackgroundJobContext` uses `ConcurrentDictionary<int, BackgroundJobContext>` keyed by `Thread.ManagedThreadId`. This is effectively thread-local storage. The risks:

- **Thread reuse:** If `Dispose()` isn't called (exception before the `using` block, or a fire-and-forget path), the dictionary retains the old tenant context. The next job on that thread inherits it. This is a **cross-tenant data breach** — one tenant's background job operates on another tenant's database.
- **Async continuations:** `ManagedThreadId` can change across `await` boundaries. If a job does `await SomeAsync()`, the continuation might run on a different thread — now the thread-local context is on the wrong thread. The `using` block's `Dispose` clears the wrong entry.
- **No diagnostic signal:** If leakage occurs, there's no log, no metric, no alert. The job simply runs against the wrong database. You'd only discover it through data corruption or a customer report.

**What I'd change:**

Eliminate the thread-local dictionary entirely. The tenant ID is already serialized into Hangfire's job parameters (via `BackgroundJobFilter`). The `CustomHangfireJobActivator` already reads it and calls `SetBackgroundContext()`. The thread-local storage is only needed for the **enqueue-time capture** — the brief window between creating `BackgroundJobContext` and `OnCreating()` firing.

Replace it with `AsyncLocal<BackgroundJobContext>` (safe across async continuations) with a guard:

```csharp
private static readonly AsyncLocal<BackgroundJobContext> _current = new();

public BackgroundJobContext(Guid tenantId)
{
    if (_current.Value != null)
        throw new InvalidOperationException(
            $"Nested BackgroundJobContext detected. Existing: {_current.Value.TenantId}, New: {tenantId}");
    TenantId = tenantId;
    _current.Value = this;
}

public void Dispose() => _current.Value = null;
```

The nested-context guard catches programming errors immediately instead of silently overwriting. `AsyncLocal` flows correctly across `await`.

---

## 5. No Migration Orchestration — Schema Drift Is Invisible

**The problem:** The `RollOnDispatch.DataMigration` project points to a single connection string. Applying migrations to N tenants requires changing that string N times and running the tool N times. There is:

- No discovery (which tenants exist)
- No status tracking (which tenants are on which version)
- No parallelization
- No failure handling
- No drift detection

At 50+ tenants, a developer forgets one. At 100+, it's guaranteed. The app code assumes all tenants are on the latest schema. When it encounters a tenant on an older version, EF throws at runtime — but only for that tenant, on requests that touch the missing column/table. This creates intermittent, tenant-specific production errors that are extremely difficult to diagnose.

**What I'd change:**

Build a migration orchestrator as an Azure Function or standalone CLI:

```
MigrationOrchestrator
  → Input: migration bundle (EF bundle or SQL scripts)
  → Step 1: Query Global DB → SELECT TenantId FROM Tenants
  → Step 2: For each tenant (parallel, semaphore-limited to ~10):
      → Build connection string
      → Check __EFMigrationsHistory → skip if current
      → Apply pending migrations
      → Record result in MigrationLog (TenantId, Version, Status, Timestamp, Error)
  → Step 3: Report
      → Success: 97/100
      → Failed: 3/100 (with error details)
      → Alert on-call if failures > threshold
  → Step 4: Retry failed tenants (exponential backoff, max 3 attempts)
```

Add a startup health check that queries the global DB for any tenants with pending migrations and logs a warning (but doesn't block startup). Add a `/admin/migration-status` endpoint that returns per-tenant schema versions — so drift is visible before it causes runtime errors.

---

## Summary — Priority Order

If I had to fix these in order of production risk:

1. **Silent null propagation** (#2) — fix in a day, prevents the most common category of confusing errors
2. **Thread-local tenant leakage** (#4) — swap to `AsyncLocal`, add the nested guard. Small change, eliminates a data breach vector
3. **Migration orchestration** (#5) — build the CLI/Function. Highest effort, but prevents the drift problem that gets worse every month
4. **Reflection removal** (#3) — modernize the factory. Medium effort, prevents silent audit trail corruption
5. **Secret separation** (#1) — largest architectural change, but the current design is a ticking clock. Start with Managed Identity for DB auth, then decouple JWT signing
