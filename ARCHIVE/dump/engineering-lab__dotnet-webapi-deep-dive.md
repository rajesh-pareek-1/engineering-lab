# .NET, ASP.NET Core, and Web API

## .NET Platform Evolution

`.NET Framework -> .NET Core -> .NET 5+`

Interview line:

```text
.NET Framework was Windows-only and legacy. .NET Core made the platform cross-platform, modular, and faster. Modern .NET 5+ unified the platform for web, cloud, APIs, desktop, and services.
```

## MVC vs Web API

| Topic | MVC | Web API |
| --- | --- | --- |
| Purpose | UI web apps | Data/API communication |
| Output | HTML views | JSON/XML |
| Main caller | Browser | SPA, mobile app, service |
| Controller style | ViewResult | IActionResult / ActionResult<T> |

Interview line:

```text
MVC renders UI. Web API exposes data and behavior to clients using HTTP.
```

## Razor vs MVC

- Razor is a view engine.
- MVC is an architectural framework.
- Razor lets C# generate dynamic HTML inside MVC views.

## ASP.NET Core Request Lifecycle

```text
Client -> Kestrel -> Middleware pipeline -> Routing -> Controller -> Action -> Response returns through middleware in reverse
```

Typical middleware order:

```csharp
app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

Key line:

```text
Middleware works at pipeline level. Filters work around controller/action execution.
```

## Middleware

Middleware is a component that handles request/response flow.

Key points:

- Order matters.
- It can short-circuit.
- It uses `HttpContext`.
- Good for cross-cutting concerns like auth, logging, exception handling, rate limiting, correlation IDs.

Custom middleware skeleton:

```csharp
public sealed class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ErrorHandlingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new { error = "Unexpected error" });
        }
    }
}
```

## Filters

Filters run inside MVC/Web API action execution.

Common types:

- Authorization filter
- Resource filter
- Action filter
- Exception filter
- Result filter

Use middleware for global request concerns. Use filters for controller/action-specific policies.

## Model Binding

Model binding maps request data to action parameters.

Sources:

- Route values
- Query string
- Request body
- Headers
- Form data

Example:

```csharp
[HttpPost("{tenantId}")]
public async Task<ActionResult<ShipmentDto>> Create(Guid tenantId, CreateShipmentRequest request)
```

## IActionResult vs ActionResult<T>

| Type | Use |
| --- | --- |
| `IActionResult` | Flexible response type, no compile-time body type |
| `ActionResult<T>` | Flexible status code plus typed response body |

Interview line:

```text
I prefer ActionResult<T> for APIs because it keeps response shape clear while still allowing NotFound, BadRequest, and other HTTP results.
```

## Global Exception Handling

Good API exception handling should:

- Catch unhandled errors once.
- Log with correlation/request ID.
- Return consistent error shape.
- Avoid leaking stack traces.

Production line:

```text
In production I would centralize exception handling in middleware so controllers stay clean and clients receive consistent error responses.
```

## JWT Authentication

Flow:

1. User logs in.
2. Server validates credentials.
3. Server issues JWT with claims.
4. Client sends `Authorization: Bearer <token>`.
5. Authentication middleware validates token and fills `HttpContext.User`.
6. Authorization checks roles/policies/claims.

Auth vs authz:

```text
Authentication verifies who you are. Authorization verifies what you can access.
```

## OAuth vs OpenID Connect

- OAuth: authorization, delegated access.
- OpenID Connect: authentication layer on top of OAuth, gives identity information.

Memory line:

```text
OAuth is access. OpenID Connect is login.
```

## Securing Web APIs

Checklist:

- HTTPS only
- JWT validation with issuer/audience/expiry
- Role/policy-based authorization
- Input validation
- Rate limiting
- CORS locked to known origins
- Structured logging
- No secrets in code
- Consistent error handling
- Pagination limits

## API Versioning

Options:

- URL: `/api/v1/shipments`
- Header: `api-version: 1`
- Query: `?api-version=1`

Interview line:

```text
Versioning allows API evolution without breaking existing clients.
```

## Newtonsoft.Json vs System.Text.Json

| Topic | Newtonsoft.Json | System.Text.Json |
| --- | --- | --- |
| Strength | Flexible, mature, many features | Faster, built into modern .NET |
| Use case | Complex converters/legacy behavior | Default modern APIs |

Circular reference options:

```csharp
options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
```

Best fix is often DTO projection instead of serializing EF entities directly.

## Caching

| Cache | Use | Tradeoff |
| --- | --- | --- |
| In-memory | Single instance, low latency | Not shared across servers |
| Distributed/Redis | Shared cache for web farms | Network hop and invalidation complexity |
| Response cache | Cache HTTP responses | Must handle auth and stale data carefully |

Interview line:

```text
Caching improves read latency and reduces DB load, but cache invalidation and stale data must be designed explicitly.
```

## Queues and Background Processing

Use queues/background jobs when:

- Work is slow.
- External systems may be offline.
- The API should respond quickly.
- Retries are needed.

Examples:

- Hangfire for invoice generation and scheduled jobs.
- Azure Service Bus for QuickBooks sync or service-to-service asynchronous work.

## High Request Load

For 100+ requests/second:

- Use async all the way.
- Add pagination and max limits.
- Cache hot reads.
- Move heavy work to queues.
- Optimize DB queries and indexes.
- Use rate limiting.
- Add observability.
- Scale horizontally if stateless.

## Idempotency

Idempotency means the same request can be retried safely.

Use for:

- Payments
- Invoice creation
- External sync
- Queue consumers

Pattern:

```text
Client sends idempotency key -> server checks processed table -> returns existing result or processes once
```

## HttpClient

Bad:

```csharp
using var client = new HttpClient();
```

Problem: socket exhaustion due to many TCP connections in `TIME_WAIT`.

Good:

```csharp
builder.Services.AddHttpClient<IQuickBooksClient, QuickBooksClient>();
```

## Monolith vs Microservices

| Topic | Monolith | Microservices |
| --- | --- | --- |
| Complexity | Lower | Higher |
| Deployment | One unit | Many units |
| Data | Shared DB possible | Database per service preferred |
| Communication | In-process | REST/gRPC/queue |

Interview line:

```text
Microservices help independent scaling and ownership, but add operational complexity, network failures, observability needs, and distributed data consistency problems.
```

## API Gateway

An API gateway is a single entry point for multiple services.

Responsibilities:

- Routing
- Authentication
- Rate limiting
- Request aggregation
- TLS termination
- Observability

## Misc Quick Lines

- `bin` contains final compiled output.
- `obj` contains intermediate build artifacts.
- Debug builds include symbols and less optimization.
- Release builds are optimized for production.
- NuGet is .NET's package manager.
- Kestrel is the cross-platform ASP.NET Core web server.

