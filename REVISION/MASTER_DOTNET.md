# Fundamentals

## Core mental model

- ASP.NET Core request path: client -> Kestrel -> middleware -> routing -> model binding -> controller/action -> service -> repository -> EF Core -> SQL -> response returns through middleware.
- Middleware is pipeline-level. Filters are MVC/action-level.
- DI lifetimes: transient = new each resolve, scoped = one per request, singleton = app lifetime.
- DbContext is scoped because it tracks one unit of work and is not thread-safe.
- C# compiles to IL; CLR loads it; JIT compiles to machine code.
- `IQueryable` means provider/database translation. `IEnumerable` means in-memory iteration.
- Async/await is non-blocking I/O flow, not automatic parallelism.

## Must-say lines

- "Middleware order matters because each component can short-circuit."
- "Authentication proves identity; authorization checks permission."
- "I prefer `ActionResult<T>` for APIs because it keeps response shape clear while preserving status-code flexibility."
- "I push filtering and projection to SQL instead of materializing early."
- "`throw` preserves stack trace; `throw ex` resets it."
- "Dispose releases external resources now; GC frees managed memory later."

# Frequently Asked Questions

## Explain ASP.NET Core lifecycle

Request enters Kestrel, passes through middleware in order, routing selects endpoint, model binding maps route/query/body values, controller calls service logic, persistence happens through EF Core/SQL, and response travels back through middleware.

## Middleware vs filters

- Middleware: global request/response pipeline, logging, auth, exception handling, rate limiting.
- Filters: controller/action execution, authorization/action/result/exception filters.
- Use middleware for broad cross-cutting concerns. Use filters for MVC-specific policies.

## DI lifetimes

- Transient: lightweight stateless objects.
- Scoped: per-request state like DbContext/request context.
- Singleton: app-wide stateless services/config/cache wrappers.
- Trap: singleton must not capture scoped services or user/tenant state.

## JWT, OAuth, OpenID Connect

- JWT: signed token with claims validated by authentication middleware.
- OAuth: delegated access.
- OpenID Connect: login identity layer on top of OAuth.
- Auth vs authz: who you are vs what you can access.

## EF Core query optimization

Filter early, project with `Select`, avoid N+1, use `AsNoTracking` for reads, paginate, index filter/join/sort columns, inspect generated SQL/execution plan.

## Async vs threading

- Thread: OS execution resource.
- Task: work abstraction.
- async/await: continuation model for non-blocking waits.
- CPU-bound work may use `Task.Run`; I/O-bound work should use real async APIs.

# Production Scenarios

## High request load

Use async all the way, pagination limits, DTO projection, indexes, caching for hot reads, queues for slow work, rate limiting, observability, and horizontal scale if stateless.

## Global exception handling

Centralize in middleware. Log exception plus request/correlation ID. Map known exceptions to correct HTTP status. Return consistent JSON. Never leak stack traces in production.

## External API failure

Use `IHttpClientFactory`, timeout, retry only when safe, circuit-breaker thinking, idempotency keys, structured logs, and background queue if work can be asynchronous.

## Queue/background job

API accepts request -> validates -> creates DB record or idempotency key -> enqueues job/message -> worker processes with tenant context, retry, logging, and dead-letter/failure visibility.

## Multitenancy

Tenant claim -> authentication -> request context -> tenant-aware factory -> tenant connection -> request-scoped DbContext. Benefit: isolation. Cost: migrations, connection pools, tenant validation, cross-tenant reports, background job context.

# Performance Concepts

- Projection: fetch only columns needed by API/screen.
- `AsNoTracking`: less memory and tracking overhead for read-only queries.
- N+1: one parent query plus one query per parent; fix with projection, Include, batching, or join.
- Index: faster lookup/filter/sort; slower writes and extra storage.
- Connection pooling: reuse physical DB connections; leaking DbContext/connections causes pool pressure.
- HttpClient pooling: avoid per-request client creation; use `IHttpClientFactory`.
- GC pressure: reduce allocations, boxing, large object churn, and long-lived references.
- Thread pool starvation: blocking async calls with `.Result`/`.Wait()` can exhaust request threads.
- Caching: in-memory is fastest but per-instance; Redis is shared but adds network and invalidation complexity.

# Edge Cases

- `UseAuthentication()` before `UseAuthorization()`.
- Exception middleware should be early.
- Body stream is normally read once.
- `IQueryable.ToList()` too early moves filtering to memory.
- `Any()` is better than `Count() > 0` for existence.
- `Single()` throws on zero or many rows; `First()` only needs first.
- DbContext is not thread-safe. Do not use one context across parallel tasks.
- Lazy loading can hide N+1.
- `async void` only for top-level event handlers.
- `throw ex` hides the real failure origin.
- Value type assignment copies value. Reference assignment copies reference.
- Event publishers can keep subscribers alive; unsubscribe when lifetimes differ.

# Tricky Questions

## Why not generic repository everywhere?

It can hide EF Core's query power. Use repositories for persistence boundaries, but allow optimized projection/filtering for important queries.

## Why not put tenant ID in route/body?

Route/body can be tampered with. Tenant should come from authenticated claims and be validated against authorization rules.

## Why not return EF entities?

It leaks internal shape, causes circular reference risks, over-fetching, and client coupling. Use DTO projection.

## Why can `.Result` deadlock or hurt throughput?

It blocks a thread waiting for async work. Under load that can starve the thread pool and reduce request capacity.

## What is captive dependency?

A singleton holds a scoped service, accidentally preserving request-specific state beyond its lifetime.

## Why is idempotency important?

Retries happen. Idempotency prevents duplicate payments, invoices, messages, and external sync side effects.

# Syntax Refreshers

```csharp
app.UseExceptionHandler();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

```csharp
builder.Services.AddScoped<IShipmentService, ShipmentService>();
builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(conn));
builder.Services.AddHttpClient<IQuickBooksClient, QuickBooksClient>();
```

```csharp
var rows = await _context.Shipments
    .AsNoTracking()
    .Where(x => x.TenantId == tenantId && x.Status == Status.Open)
    .Select(x => new ShipmentListItem { Id = x.Id, Number = x.Number })
    .ToListAsync();
```

```csharp
var a = FetchAAsync();
var b = FetchBAsync();
await Task.WhenAll(a, b);
```

```csharp
catch (Exception)
{
    throw;
}
```

# Real Project Examples

## RollOnDispatch API flow

Request -> JWT -> tenant/user context -> controller -> service validation/business rules -> repository -> EF Core -> `SaveChangesAsync` -> activity logging -> typed response.

## Performance story

Reduced unnecessary DB and memory work using pagination, projection, avoiding early `ToList`, `AsNoTracking`, indexes on common filters, and async EF calls.

## Background processing story

Invoice/report/QuickBooks-style work should not block API requests. Enqueue work, return quickly, process with retries, monitoring, tenant context, and idempotency.

## Multitenancy story

Tenant identity comes from claims, flows into request context, and resolves tenant-specific DB access. Strong isolation, but operational complexity around migrations, connections, and background jobs.

# 30-Minute Rapid Revision

1. Request lifecycle in 30 seconds.
2. Middleware vs filters.
3. DI lifetimes and captive dependency.
4. JWT/auth/authz/OAuth/OIDC.
5. EF Core: IQueryable, projection, N+1, AsNoTracking, DbContext lifetime.
6. Async: await, Task.WhenAll, `.Result`, thread pool starvation.
7. Caching, queues, idempotency, rate limiting.
8. Multitenancy request flow and tradeoffs.
9. Say one project performance story.
10. Say one production-debugging story: logs -> correlation ID -> reproduce -> inspect SQL/payload -> fix root cause.

# Questions To Ask Interviewer

- What are the biggest backend reliability problems in the product today?
- How do you observe API latency, errors, and background job failures?
- How are database migrations handled across environments or tenants?
- What does good ownership look like in the first 90 days?
- Where are the biggest performance bottlenecks right now: API, database, queue, or client?
