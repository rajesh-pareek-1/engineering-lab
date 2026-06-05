# Backend Web API Revision

## Must-Say Lines

- Request lifecycle: `Client -> Kestrel -> middleware -> routing -> model binding -> controller/action -> response back through middleware`.
- Middleware is pipeline-level; filters are MVC/action-level.
- Order matters because middleware can short-circuit.
- Central exception middleware keeps controllers clean and returns consistent error shape.
- Authentication proves identity; authorization checks permissions.
- OAuth is delegated access; OpenID Connect adds login identity.
- Idempotency makes retries safe for create/payment/invoice/sync flows.

## ASP.NET Core Request Path

Say:

```text
The request reaches Kestrel, enters middleware in configured order, routing selects endpoint/controller, model binding maps route/query/body data, the action calls services, and the response exits through middleware in reverse.
```

Edge cases:

- `UseAuthentication()` must run before `UseAuthorization()`.
- Exception handling should be early in the pipeline.
- Middleware can short-circuit and never call the controller.
- Filters do not cover non-MVC endpoints the same way middleware does.

Common questions:

- Explain request lifecycle.
- Middleware vs filter?
- Why does order matter?
- Where do you put logging/correlation IDs?

## Controllers And Responses

- Prefer `ActionResult<T>` for typed API responses plus status flexibility.
- Keep controllers thin: validate input shape, call service, map result.
- Use DTOs instead of returning EF entities directly.
- Model binding reads route, query, body, header, and form data.

Edge cases:

- Body is normally read once.
- Circular references often mean DTO projection is missing.
- Returning too much shape couples clients to database entities.

## Exception Handling

Checklist:

- Catch unhandled exceptions once.
- Log exception plus request/correlation ID.
- Map known exceptions to correct status codes.
- Return a consistent JSON error format.
- Do not leak stack traces in production.

Strong answer:

```text
I use centralized exception middleware so controllers stay focused on business flow. It logs the real exception, maps expected errors to HTTP status codes, and returns a consistent response without leaking internals.
```

## Security

JWT flow:

```text
Login -> validate credentials -> issue token with claims -> client sends Bearer token -> authentication middleware validates token -> HttpContext.User is populated -> authorization policies decide access.
```

API security checklist:

- HTTPS only.
- Validate issuer, audience, expiry, and signing key.
- Role/policy/claim authorization.
- Input validation.
- Locked-down CORS.
- Rate limiting.
- No secrets in code/logs.
- Pagination limits.
- Safe error responses.

Edge cases:

- Do not trust tenant ID from route/body if claim says otherwise.
- Refresh tokens need separate storage/rotation strategy.
- CORS is browser protection, not API authentication.

## Caching, Queues, And Load

High-load answer:

```text
I keep I/O async, reduce DB work with projection/pagination/indexes, cache hot reads, move slow work to queues, rate-limit abusive traffic, monitor latency/errors, and scale stateless API instances horizontally.
```

Cache tradeoffs:

- In-memory: fastest, per instance, not shared.
- Redis/distributed: shared, network hop, invalidation complexity.
- Response cache: useful but dangerous around auth/stale data.

Queue answer:

```text
Queues decouple slow or unreliable work from the request path. A worker can retry, log, dead-letter, and process idempotently.
```

Edge cases:

- Queue consumers must be idempotent.
- Background jobs need tenant context.
- Retries can duplicate external side effects.
- Long work inside API requests causes timeouts and poor user experience.

## HttpClient And External Calls

- Do not create `HttpClient` per request.
- Use `IHttpClientFactory` to reuse handlers and avoid socket exhaustion.
- Add timeouts, retry policy only where safe, and circuit-breaker thinking for flaky services.

Common questions:

- Why `IHttpClientFactory`?
- What is socket exhaustion?
- How do you handle QuickBooks/external sync failures?

## Architecture Lines

- Monolith: simpler deployment and debugging.
- Microservices: independent scaling/ownership, but distributed failures and consistency issues.
- API gateway: routing, auth, rate limiting, request aggregation, observability.
- Versioning lets APIs evolve without breaking existing clients.
