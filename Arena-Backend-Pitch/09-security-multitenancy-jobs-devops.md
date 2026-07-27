# 9. Security, Multi-Tenancy, Hangfire, Observability, Testing, and DevOps

## Platform mnemonic: **SAFE-JOLT**

- **S - Security:** JWT, OAuth concepts, roles.
- **A - Architecture:** tenant isolation and DI.
- **F - Fault handling:** retries, idempotency, transactions.
- **E - Evidence:** logs and monitoring.
- **J - Jobs:** Hangfire scheduling/background work.
- **O - Operations:** Docker and Azure.
- **L - Lifecycle:** CI/CD and controlled releases.
- **T - Tests:** unit and integration coverage.

## Authentication vs authorization

> Authentication proves who the caller is. Authorization decides what the authenticated caller may do. JWT bearer authentication validates a token; role, claim, policy, and resource checks authorize the operation.

## JWT flow

```text
credentials / identity provider
  → validate identity
  → issue signed access token
  → client sends Bearer token
  → API validates signature, issuer, audience, expiry
  → claims principal created
  → authorization policy evaluated
```

> A JWT is signed, not normally encrypted. Do not put secrets in its payload. Use HTTPS, short-lived access tokens, safe key management, and validate all configured properties.

Cross-question: **Can we revoke a JWT?**

> A self-contained access token is difficult to revoke immediately without server-side state. Keep it short-lived and revoke/rotate refresh tokens. For high-risk needs, use a denylist or token-version/security-stamp check with the associated cost.

## Refresh tokens

> Refresh tokens are longer-lived credentials used to obtain new short-lived access tokens. Store them securely, preferably hashed server-side, rotate on use, detect reuse, associate them with a user/device/session, and revoke the token family when compromise is suspected.

## OAuth correction

> OAuth 2.0 is an authorization framework for delegated access; OpenID Connect adds identity/authentication. JWT is a token format and can be used with or without OAuth. If I only configured JWT bearer auth, I do not claim that I designed an OAuth server.

## Role-based and policy authorization

> Roles are broad groupings such as Admin or Dispatcher. Policies can express claim and requirement combinations. Resource-based authorization checks the specific object - for example, whether this dispatcher may access this shipment in this tenant.

## Multi-tenant defense in depth: **R-Q-C-J-L**

- **R - Resolve** tenant from trusted context.
- **Q - Query** with tenant isolation/filter.
- **C - Cache** keys include tenant.
- **J - Jobs** explicitly establish tenant scope.
- **L - Logs** include tenant but no secrets.

## Hangfire

> Hangfire persists job definitions/state and executes them outside the HTTP request. It supports fire-and-forget, delayed, recurring, and continuation jobs with retries and a dashboard.

### Reliable-job mnemonic: **I-T-R-O**

- **I - Idempotent:** rerunning is safe.
- **T - Tenant-aware:** establish correct tenant scope.
- **R - Retry classified:** retry transient, not permanent validation failures.
- **O - Observable:** structured logs, job ID, metrics, alerts.

Cross-question: **Why not `Task.Run` from a controller?**

> It is not durable, can be lost on process restart, does not provide persistent retry/status, and can capture request-scoped dependencies incorrectly. Durable background work belongs in a job system or queue.

## Logging and Application Insights

> Structured logging records named properties, allowing search and aggregation. Application Insights can correlate requests, dependencies, exceptions, and traces. Logs answer what happened; metrics show trends; traces show a request across components.

Example:

```csharp
logger.LogInformation(
    "Queued expiry reminder for Tenant {TenantId}, Document {DocumentId}, Job {JobId}",
    tenantId, documentId, jobId);
```

Avoid interpolated unstructured messages when named fields are useful. Never log passwords, JWTs, refresh tokens, connection strings, or sensitive documents.

### Correlation

> Accept or generate a correlation/trace ID at the request boundary, include it in logging scope, propagate it to HTTP/messages/jobs, and return a safe trace ID in errors. This connects the end-to-end flow.

## Unit vs integration tests

> A unit test isolates a focused unit and runs quickly, usually replacing external collaborators. An integration test verifies components together, such as ASP.NET Core routing/authentication/serialization and persistence behavior. Both are valuable: unit tests pinpoint business rules; integration tests catch wiring and contract errors.

### Test mnemonic: **A-A-A + E**

- **Arrange** inputs and dependencies.
- **Act** once.
- **Assert** outcome and important interaction.
- **Edges:** invalid, missing, unauthorized, conflict, cancellation, failure.

Cross-question: **Mock EF Core?**

> Mocking `DbSet` can give misleading behavior because LINQ translation and relational constraints differ. For query behavior, use integration tests against the actual provider or a suitable test database/container. EF InMemory can be useful for limited tests but is not relational SQL Server.

## Docker

> Docker packages the application and runtime dependencies into a repeatable image. Configuration and secrets remain outside the image. A multi-stage build uses an SDK image to build/publish and a smaller ASP.NET runtime image to run.

Production concerns:

- non-root user where possible;
- minimal pinned base images and vulnerability updates;
- health checks;
- environment-based configuration;
- no secrets baked into layers;
- logs written to standard output;
- graceful shutdown.

## Azure App Service and Azure SQL

> Azure App Service hosts the web application with managed deployment, scaling, configuration, TLS, and diagnostics. Azure SQL provides managed SQL Server capabilities. Application configuration should use environment/App Service settings and secret management rather than committed values.

## CI/CD pipeline

```text
commit / pull request
  → restore
  → build
  → unit + integration tests
  → static/security checks
  → publish artifact or Docker image
  → deploy non-production
  → smoke/health checks
  → approval / controlled production rollout
  → monitor and rollback/forward-fix
```

> CI proves every change can build and pass automated checks. CD creates a repeatable controlled path to environments. I contributed to pipeline/deployment validation; I would distinguish that from designing the entire platform if I did not own it.

## Deployment safety

Mnemonic: **B-H-M-R**

- **B - Backward-compatible** app/schema sequence.
- **H - Health** and smoke checks.
- **M - Monitor** errors, latency, and business signals.
- **R - Rollback or forward-fix** plan.

> Database migrations are often the hardest rollback point. Prefer expand-and-contract changes: add compatible schema, deploy code using it, migrate data, then remove old schema later.

## Performance and production incident answer

> I first stabilize impact, then use Application Insights and structured logs to identify affected endpoint, tenant, dependency, and timeframe. I check recent deployments, error rate, duration, database queries, and external services. After mitigation, I find root cause, add a regression test and monitoring signal, and document the prevention step.

