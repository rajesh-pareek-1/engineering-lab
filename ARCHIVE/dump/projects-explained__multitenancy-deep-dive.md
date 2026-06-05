# Multi-Tenant Architecture Deep Dive

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

