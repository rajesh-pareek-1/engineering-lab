# 6. ASP.NET Core and REST APIs

## Request pipeline mind map

```text
HTTP request
  → Kestrel
  → middleware pipeline
       exception handling
       HTTPS / CORS
       authentication
       authorization
       logging
  → routing
  → model binding + validation
  → controller action
  → service / EF Core
  → result serialization
  → HTTP response
```

## Mnemonic: **M-R-C-S-R**

- **M - Middleware** handles cross-cutting concerns.
- **R - Routing** selects endpoint.
- **C - Controller** translates HTTP to a use case.
- **S - Service** performs business flow.
- **R - Response** uses correct status and DTO.

## Middleware

> Middleware forms an ordered pipeline. Each component can handle the request, call the next component, and inspect the response on the way back. Order matters: authentication must run before authorization, and exception middleware should be early enough to catch downstream exceptions.

### Middleware example

```csharp
public sealed class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;

    public CorrelationIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(
        HttpContext context,
        ILogger<CorrelationIdMiddleware> logger)
    {
        var correlationId =
            context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString("N");

        context.Response.Headers["X-Correlation-Id"] = correlationId;

        using (logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = correlationId
        }))
        {
            await _next(context);
        }
    }
}
```

Registration order:

```csharp
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.UseEndpoints(endpoints => endpoints.MapControllers());
```

> Middleware can run before and after `_next`, terminate the pipeline early, or pass control onward. Typical uses are global exception handling, correlation IDs, request logging, security headers, CORS, authentication, and rate limiting.

## Middleware vs MVC filters

### Interview answer

> Middleware operates at the general HTTP pipeline and can apply to all requests. MVC filters operate inside the MVC/action pipeline and understand controller/action context. I use middleware for global exception handling and correlation, and filters for MVC-specific behavior when necessary.

```text
HTTP request
  → middleware before `_next`
  → routing/auth middleware
  → MVC selected
      → authorization filter
      → resource filter
      → action filter before
      → controller action
      → action filter after
      → exception/result filters
  → middleware after `_next`
  → HTTP response
```

| Middleware | Filter |
|---|---|
| Runs in the ASP.NET Core HTTP pipeline | Runs inside MVC/controller execution |
| Can apply to controllers, minimal APIs, static files, etc. depending on placement | Applies to MVC controllers/actions |
| Has `HttpContext` and `RequestDelegate` | Has MVC contexts such as action arguments, controller, model state, and result |
| Configured in `Program.cs` pipeline order | Applied globally, by attribute, or controller/action configuration |
| Best for global HTTP cross-cutting concerns | Best for action/controller-specific cross-cutting behavior |
| Can short-circuit before MVC is reached | Can short-circuit or alter action/result within MVC |

### Filter types: **A-R-A-E-R**

- **Authorization filter:** MVC authorization decision; normally prefer authorization policies for application security.
- **Resource filter:** wraps most MVC processing; useful for resource caching or expensive setup.
- **Action filter:** before/after controller action; sees action arguments and result.
- **Exception filter:** handles exceptions from MVC action execution, but not every middleware/routing failure.
- **Result filter:** before/after action-result execution.

### Action-filter example

```csharp
public sealed class ValidateTenantAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.HttpContext.User.HasClaim(c => c.Type == "tenant_id"))
        {
            context.Result = new ForbidResult();
        }
    }
}
```

Applied to one controller/action:

```csharp
[ValidateTenant]
[HttpPost("{driverLoadId:int}/attachments")]
public Task<IActionResult> UploadAttachment(int driverLoadId) { /* ... */ }
```

> In production, tenant authorization should normally use a proper policy/resource authorization handler rather than a simplistic custom filter. The example demonstrates that an action filter can inspect MVC/action context.

### How to choose

Use **G-A**:

- **G - Global HTTP concern:** middleware.
- **A - Action-aware MVC concern:** filter.

Examples:

- Global exception response → middleware.
- Correlation ID/request timing → middleware.
- Authentication/authorization pipeline → middleware plus policies.
- Inspect or modify action arguments → action filter.
- Controller-specific audit metadata → action filter when appropriate.
- Modify an MVC result → result filter.

Cross-question: **Why is exception middleware usually preferred to exception filters?**

> Exception middleware can catch failures from more of the downstream pipeline and produce one application-wide error contract. Exception filters are limited to exceptions arising within MVC action/result processing and do not catch errors that occur before MVC.

Cross-question: **Can both short-circuit?**

> Yes. Middleware can return without calling `_next`. A filter can set `context.Result` and prevent the action or later stage from executing.

Cross-question: **Does filter order matter?**

> Yes. Filters have scope—global, controller, action—and can implement ordering. Before-code runs toward the action and after-code unwinds outward, similar to nested scopes.

Cross-question: **Middleware lifetime?**

> Conventional middleware is normally constructed once, so scoped services should be injected into `InvokeAsync`, not captured in its constructor. `IMiddleware`-based middleware can be activated per request through DI.

## REST design

> REST APIs model resources through predictable URIs and HTTP semantics. They are stateless: each request carries the information needed to process it. I use nouns in routes, correct verbs, meaningful status codes, validation, pagination, and versioning when contracts evolve incompatibly.

### How I start designing an API for a new requirement: **B-C-R-F-S-O**

1. **Business:** actors, outcome, rules, failure cases, acceptance criteria.
2. **Contract:** resources, DTOs, endpoints, verbs, status codes, idempotency.
3. **Relationships:** entities, ownership, cardinality, constraints, transaction boundary.
4. **Flow:** authentication → validation → business logic → persistence/integration → response.
5. **Safety:** authorization, tenant isolation, input limits, concurrency, audit and secrets.
6. **Operations:** pagination, indexes, logs, metrics, retries, tests, versioning and rollout.

> I do not start from the controller. I first clarify who performs the operation, the business invariant, expected scale, security boundary, and failure behavior. Then I define the API contract and data model, review them with consumers, implement the smallest vertical slice, and add tests and observability.

Student-document example:

```http
GET    /api/document-types
POST   /api/students/{studentId}/documents
GET    /api/students/{studentId}/documents?type=PASSPORT&status=Approved
GET    /api/students/{studentId}/documents/{documentId}
PATCH  /api/students/{studentId}/documents/{documentId}/status
DELETE /api/students/{studentId}/documents/{documentId}
```

```csharp
public sealed record UploadStudentDocumentRequest(
    string TypeCode,
    DateTimeOffset? Expiry,
    Dictionary<string, string> Fields,
    IFormFile File);
```

Create response:

```csharp
return CreatedAtAction(
    nameof(GetDocument),
    new { studentId, documentId = result.Id },
    result);
```

Cross-questions:

- `POST` retry? Accept an idempotency key and enforce uniqueness.
- Simultaneous approval? Use `rowversion` and return `409 Conflict`.
- File plus SQL partial failure? Store pending/completed state or compensate by deleting the blob.
- Security? Verify the caller can access that student; never trust `studentId` alone.
- Large lists? Stable sorting plus server-side pagination.
- Breaking contract? Prefer additive changes; version only incompatible changes.

### Verbs and idempotency

- `GET /shipments/42`: retrieve; safe and idempotent.
- `POST /shipments`: create; normally not idempotent unless protected with an idempotency key.
- `PUT /shipments/42`: complete replacement; intended to be idempotent.
- `PATCH /shipments/42`: partial update; idempotency depends on operation.
- `DELETE /shipments/42`: intended to be idempotent in final state.

## Status codes: **2 good, 4 client, 5 server**

- `200 OK`: successful read/update with body.
- `201 Created`: created; include location when useful.
- `204 No Content`: successful operation without body.
- `400 Bad Request`: malformed input/basic validation.
- `401 Unauthorized`: actually unauthenticated/invalid credentials.
- `403 Forbidden`: authenticated but not permitted.
- `404 Not Found`: resource absent or intentionally hidden.
- `409 Conflict`: concurrency or current-state conflict.
- `422 Unprocessable Content`: semantically invalid input, if the API convention uses it.
- `500 Internal Server Error`: unexpected failure; do not expose internals.

## DTOs vs entities

> DTOs stabilize API contracts, limit exposed fields, support validation, and prevent over-posting. EF entities model persistence and change tracking. Returning entities directly can leak navigation properties or internal fields and tightly couple API evolution to database design.

Cross-question: **Manual mapping or AutoMapper?**

> Manual mapping is explicit and easy to debug for important or complex mappings. AutoMapper reduces repetitive simple mapping but must be configured and tested. For queries, direct projection with `Select` is often efficient because EF requests only required columns.

## Validation

> ASP.NET Core can validate DTO annotations automatically under `[ApiController]`; FluentValidation can express richer boundary rules. Business rules still belong in the service/domain layer, and database constraints remain the final integrity guard.

Example response shape:

```json
{
  "code": "shipment.invalid_status",
  "message": "Shipment cannot be dispatched from its current status.",
  "traceId": "...",
  "errors": { "status": ["Expected Ready status."] }
}
```

## Centralized exception handling

> I map known exceptions - validation, not found, conflict, forbidden - to consistent problem responses. Unexpected exceptions are logged with correlation context and returned as a generic 500. Controllers stay clean, and clients receive one predictable format.

Cross-question: **Why not `try/catch` in every controller?**

> It duplicates logic, produces inconsistent responses, and can cause repeated logging. Catch locally only when the method can recover, translate a specific exception, or add meaningful business handling.

## Pagination, filtering, and sorting

> For collection endpoints, apply authorization and tenant filters first, then user filters and a stable sort, then pagination, and finally projection. Server-side pagination prevents unbounded memory, query, and network cost.

Offset pagination:

```csharp
query.OrderBy(x => x.Id).Skip((page - 1) * size).Take(size);
```

> Offset pagination is simple but high offsets can become expensive and concurrent inserts can shift results. Keyset pagination uses the last seen stable key, such as `WHERE Id > @lastId ORDER BY Id`, which is efficient for sequential browsing.

## API versioning

> Prefer backward-compatible additions. For breaking changes, version by route, header, or media type according to team convention. Support a documented deprecation period and monitor old-version usage.

## CORS

> CORS is a browser enforcement mechanism controlling which origins may call an API from frontend JavaScript. It is not authentication. Configure only required origins, methods, and headers; avoid wildcard origins with credentials.

## OpenAPI/Swagger

> OpenAPI documents endpoints, schemas, authentication, and responses. Swagger UI helps discovery and manual testing. Documentation does not replace automated tests or authorization.

## GraphQL

### What it is

> GraphQL is a typed API query language and server execution model. The server publishes a schema of types and fields. Clients request exactly the fields they need through queries, change data through mutations, and may receive real-time updates through subscriptions. Resolver functions obtain each requested field's data.

```graphql
query GetShipment($id: Int!) {
  shipment(id: $id) {
    shipmentId
    reference
    status
    driverLoads {
      driverLoadId
      driver {
        name
      }
    }
  }
}
```

Conceptual .NET resolver:

```csharp
public Task<Shipment?> GetShipmentAsync(
    int id,
    IShipmentRepository repository,
    CancellationToken cancellationToken) =>
    repository.GetByIdAsync(id, cancellationToken);
```

### GraphQL vs REST

| REST | GraphQL |
|---|---|
| Multiple resource endpoints | Commonly one GraphQL endpoint |
| Server defines response shape | Client selects fields within schema |
| HTTP status and caching are natural | Application errors often appear in GraphQL response; caching needs deliberate design |
| Simple and observable for many CRUD APIs | Useful for connected data and varying client needs |
| Versioning may use routes/headers | Schema evolves through additive fields and deprecation |

### Benefits

- reduces over-fetching and under-fetching;
- one typed schema supports web/mobile views with different field needs;
- introspection and tooling improve discoverability;
- clients can retrieve related data in one logical request.

### Risks and solutions

- **N+1 database queries:** batch/cache resolver loads with DataLoader and project efficiently.
- **Expensive nested queries:** apply depth, complexity, pagination, timeout, and rate limits.
- **Authorization:** enforce at resolver/use-case/resource level; hiding UI fields is not security.
- **Caching:** use normalized client caching, persisted queries, or appropriate server/CDN strategy.
- **Monitoring:** capture operation name, duration, resolver/dependency behavior—never blindly log sensitive query variables.

### Interview answer

> I have mainly worked with REST APIs, not production GraphQL. My understanding is that GraphQL exposes a typed schema and lets clients request specific fields through queries, while mutations change data. It is helpful when several clients need different shapes of connected domain data, but it adds resolver performance, N+1, authorization, query-complexity, caching, and observability concerns. For ROD, it could support flexible shipment/load-board views, but I would not replace stable REST endpoints unless those benefits justify the added complexity.

Cross-question: **Does GraphQL always make one database query?**

> No. It is one logical client request, but naive field resolvers may execute many database calls. DataLoader batching, projections, and measured resolver design are necessary.

Cross-question: **Query vs mutation?**

> Query reads data and should not create side effects. Mutation changes state. Both are fields in the schema with resolver logic and require authentication, authorization, validation, and error handling.

## API security checklist: **A-V-L-P-E**

- **A - Authenticate and authorize.**
- **V - Validate input and ownership.**
- **L - Limit rate, payload size, and returned data.**
- **P - Protect secrets and sensitive logs.**
- **E - Encrypt in transit and handle errors safely.**

## Cross-question chain: design a shipment endpoint

1. Define resource and contract.
2. Authenticate and resolve tenant.
3. Authorize permission and resource ownership.
4. Validate DTO and shipment state.
5. Execute service workflow.
6. Use transaction for related writes.
7. Save audit/business event.
8. Return `201`, `200`, or suitable error.
9. Log correlation, tenant, shipment, duration.
10. Test success, invalid input, forbidden, missing, conflict, and failure rollback.
