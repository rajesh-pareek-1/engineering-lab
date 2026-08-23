# 12. Actual .NET + React First-Round Additions

> Based on Priyansh's real first-round question set.
> **Rule:** say what you have done in ROD; say “I understand the design, but have not used it in production” for GraphQL, Apollo, or Power Automate if that is true.

## 1. How would you use GraphQL in .NET?

> I have mainly used REST in production. For a .NET GraphQL API, I would use **Hot Chocolate** because it integrates with ASP.NET Core, DI, authorization, HTTP/WebSocket transport, DataLoader batching, and OpenTelemetry. I would expose GraphQL only where connected client data shapes justify it; REST remains a good fit for stable workflow endpoints.

```csharp
builder.Services
    .AddGraphQLServer()
    .AddQueryType<Query>()
    .AddAuthorization()
    .AddDataLoader();

var app = builder.Build();
app.MapGraphQL("/graphql");
```

```csharp
public sealed class Query
{
    [Authorize]
    public Task<Shipment?> GetShipmentAsync(
        int id,
        IShipmentRepository repository,
        CancellationToken cancellationToken) =>
        repository.GetByIdAsync(id, cancellationToken);
}
```

**Production safeguards:** authorize each resolver/use case, derive tenant from claims—not GraphQL arguments—use DataLoader to prevent N+1, paginate nested lists, set query cost/depth limits, and trace operation/resolver time.

## 2. REST methods—short answer with examples

| Method | Meaning | ROD-style example | Typical success |
|---|---|---|---|
| `GET` | Read; no side effect | `GET /api/shipments/42` | `200` |
| `POST` | Create or command | `POST /api/shipments` | `201 Created` |
| `PUT` | Replace known resource representation | `PUT /api/shipments/42` | `200` / `204` |
| `PATCH` | Partial update | `PATCH /api/shipments/42` status only | `200` / `204` |
| `DELETE` | Remove/deactivate | `DELETE /api/attachments/9` | `204` |

> `PUT` is normally idempotent: sending the same representation again has the same final state. `POST` is not automatically idempotent, so for retryable creates I use an idempotency key or a durable uniqueness rule.

## 3. What is multi-tenancy? Give your ROD example

> A multi-tenant application serves multiple customer organizations while keeping each customer’s users and data isolated. In ROD, authenticated request context carries the tenant identity; `ITenantDbContextFactory` uses it to select the correct tenant SQL database. Background jobs do not have a browser JWT, so `BackgroundJobContext` carries and restores the tenant ID before repositories run.

```text
JWT tid claim / Hangfire BackgroundJobContext
        → IRequestContext
        → ITenantDbContextFactory
        → correct tenant SQL database
```

## 4. Explain authentication flow and expired access token

```text
Login credentials
 → identity service validates user
 → short-lived access JWT + refresh credential
 → React sends Authorization: Bearer <access JWT>
 → ASP.NET Core validates signature, issuer, audience, expiry
 → authorization checks role/policy/resource/tenant
```

> When access token expires, the client calls a protected refresh endpoint with the refresh credential. The server validates, rotates, and revokes as needed; the client stores the new tokens and retries the original request **once**. If refresh fails, clear session and go to login. Coordinate simultaneous `401`s so ten API calls do not cause ten refresh calls.

## 5. Valid JWT but `403 Forbidden`—what do you check?

> `403` means authentication succeeded but authorization failed. I check the endpoint’s role/policy/permission, token claims and scopes, tenant claim versus requested resource, custom authorization handler, current user/role status, and server logs with trace ID. A newly changed role may also mean the JWT is stale and needs refresh/re-login.

```text
401 = missing / invalid / expired identity
403 = known identity, but not allowed to do this action
```

## 6. A valid user gets an error while login/accessing an API—how do you debug?

```text
Browser/API client: URL, method, headers, payload, status, response, correlation ID
        ↓
Auth: issuer/audience/signature/expiry, account lock/disabled state, role/tenant claim
        ↓
App: authorization policy, request validation, controller/service logs
        ↓
Data/dependency: tenant DB, identity provider, external service latency/failure
```

> I never log passwords, raw JWTs, refresh tokens, or sensitive documents. I use a correlation/trace ID to connect client evidence to backend logs.

## 7. SQL query is 8 seconds—how do you optimize it?

> First capture the actual query and parameters, inspect actual execution plan plus IO/time statistics, then compare estimated versus actual row counts. I look for scans/seeks, join choices, key lookups, sort/spill warnings, non-sargable predicates, missing or overlapping indexes, unnecessary columns, and poor pagination. I make one measured change and retest; a scan is not automatically wrong.

## 8. SQL is milliseconds but the .NET API is slow—what now?

> That proves the SQL execution is not the whole bottleneck. I time each boundary: middleware/auth, controller/service, number of EF commands, materialization/tracking, mapping, serialization/payload size, outbound calls, connection-pool wait, thread-pool starvation/blocked async code, GC/CPU, and network time-to-first-byte. I check generated SQL and command duration separately from total request duration.

```text
Fast SQL + slow API
→ too many queries / N+1?
→ tracking or materializing huge graph?
→ large JSON / circular navigation / mapping?
→ slow HTTP/Blob/third-party dependency?
→ blocking .Result/.Wait, CPU, connection pool, network?
```

## 9. Offset pagination: why can inserts create duplicates or misses?

> Offset pagination says “skip the first 100 rows.” If new rows are inserted before page 2 between requests, the offset shifts: records can appear again or be missed. A stable `ORDER BY` makes a snapshot deterministic only while data is unchanged.

### Keyset/cursor pagination

> Send the last stable sort key from the previous page, not a page number. For newest-first shipments I use `(CreatedAt, Id)` because timestamp alone can tie.

```sql
SELECT TOP (@pageSize) ShipmentId, CreatedAt, Reference
FROM Shipments
WHERE TenantId = @tenantId
  AND (
        CreatedAt < @lastCreatedAt
        OR (CreatedAt = @lastCreatedAt AND ShipmentId < @lastShipmentId)
      )
ORDER BY CreatedAt DESC, ShipmentId DESC;
```

> Keyset pagination is fast and stable for next/previous sequential browsing, but arbitrary “jump to page 37” is less natural. For a perfect historical snapshot, I would need an explicit snapshot/version boundary as well.

## 10. Find the second-largest **distinct** number—explain first

> First I clarify whether duplicates count. For second-largest **distinct** value, I scan once and keep the largest and second-largest values—O(n) time and O(1) extra space.

```csharp
static int SecondLargestDistinct(IEnumerable<int> values)
{
    int? largest = null;
    int? second = null;

    foreach (var value in values)
    {
        if (largest is null || value > largest)
        {
            second = largest;
            largest = value;
        }
        else if (value < largest && (second is null || value > second))
        {
            second = value;
        }
    }

    return second ?? throw new InvalidOperationException(
        "At least two distinct values are required.");
}
```

## 11. DI lifetimes

| Lifetime | Meaning | Good use |
|---|---|---|
| Transient | New object whenever resolved | small stateless helper |
| Scoped | One instance per HTTP request/job scope | DbContext, repositories, services, tenant context |
| Singleton | One instance for app lifetime | thread-safe shared configuration/client/factory |

> Never inject a scoped DbContext/repository directly into a singleton. The singleton outlives the request/job scope and can hold invalid or cross-request state.

## 12. Global exception handling—where and why?

> Use early ASP.NET Core exception-handling middleware. It wraps downstream routing/controllers/services so 100 endpoints can return one safe `ProblemDetails`-style error contract. Catch locally only when the method can recover or translate a meaningful business exception.

```csharp
app.UseMiddleware<ExceptionHandlingMiddleware>(); // early
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
```

## 13. Three independent APIs: sequential or parallel?

> If calls are genuinely independent and downstream limits allow it, start all tasks first and await `Task.WhenAll`. This reduces total latency to roughly the slowest call, rather than the sum. Do not parallelize dependent calls or run concurrent EF queries on one `DbContext`.

```csharp
var profileTask = _profileClient.GetAsync(userId, cancellationToken);
var limitsTask = _limitsClient.GetAsync(userId, cancellationToken);
var alertsTask = _alertsClient.GetAsync(userId, cancellationToken);

await Task.WhenAll(profileTask, limitsTask, alertsTask);
```

## 14. Unit-test flow and .NET test environment

```text
Arrange → create service + mock dependencies + input
Act     → call one method
Assert  → result, state, collaborator calls, exception/log behavior
```

> I create a separate xUnit test project, reference the application layer, use Moq/fakes for repositories and external integrations, and keep unit tests deterministic and fast. I use integration tests separately for routing, auth, serialization, EF mapping, and database behavior.

## 15. CI/CD pipeline: high-level answer

```text
PR → checkout → restore → build → lint/static analysis → unit tests
   → integration/security scan → package / Docker image → push registry
   → deploy staging → migrations with reviewed plan → smoke test
   → approval/controlled production rollout → telemetry / rollback plan
```

> Secrets come from secure pipeline variables/Key Vault, never source control. I publish test results and stop promotion on failures.

## 16. Third-party limitation / Power Automate answer

> I do not claim production Power Automate work unless I personally used it. I would say: “I understand it can automate approval/notification workflows through connectors, but my direct integration experience is with Blob Storage, Notification Hub, and QuickBooks-style services.” For any third-party tool I check API limits, payload/timeout constraints, auth/expiry, pagination, reliability SLA, and export/lock-in. I hide the provider behind an adapter, use timeouts/retries for transient failures, and retain a manual/reconciliation fallback.

## 17. Import one million records safely

```text
Upload file to Blob → create ImportJob(Pending) → enqueue worker
→ stream rows; do not load whole file into RAM
→ validate/chunk (for example, 500–5,000 rows)
→ bulk copy to staging table
→ set-based validation/upsert into final tables
→ row-level error report + progress + audit
→ idempotent resume/checkpoint + retry safe chunks
```

> The HTTP request returns `202 Accepted` with an import job ID. The UI polls or receives SignalR progress. I throttle database writes, keep transactions short per chunk, enforce tenant/authorization rules, and never allow one malformed row to silently corrupt valid data.

## Sources for the new/tool-specific answers

- [Hot Chocolate for ASP.NET Core](https://chillicream.com/docs/hotchocolate/server)
- [EF Core performance guidance](https://learn.microsoft.com/en-us/ef/core/performance/)
- [Azure Static Web Apps overview](https://learn.microsoft.com/en-us/azure/static-web-apps/overview)
