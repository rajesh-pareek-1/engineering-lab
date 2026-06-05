# Mock Interview: Backend Round

Use this as a spoken mock. Answer first, then compare with the strong answer.

## 1. Explain ASP.NET Core Request Lifecycle

Expected answer:

```text
Client request enters Kestrel, passes through middleware in configured order, route matching selects controller/action, model binding maps request data, action executes, and response travels back through middleware in reverse.
```

Weak answer:

```text
Request goes to controller and returns response.
```

Strong answer:

```text
In ASP.NET Core the request first hits Kestrel, then middleware such as exception handling, routing, authentication, and authorization. After routing, model binding maps route/query/body data into action parameters, controller action calls services, and the response returns through the same middleware chain in reverse. Order matters because middleware can short-circuit.
```

## 2. How Would You Handle Global Exceptions?

Expected answer:

```text
Central middleware, structured logging, consistent error response, no stack trace leak.
```

Weak answer:

```text
Use try/catch in every controller.
```

Strong answer:

```text
I would use exception-handling middleware around the pipeline. It catches unhandled exceptions once, logs the exception with correlation/request information, maps known exceptions to proper status codes, and returns a consistent JSON error shape. Controllers stay focused on business flow.
```

## 3. What Are DI Lifetimes?

Expected answer:

```text
Transient = new every resolve, scoped = one per request, singleton = one for app lifetime.
```

Weak answer:

```text
They decide object creation.
```

Strong answer:

```text
Transient is useful for lightweight stateless services, scoped is one instance per request and is the usual choice for DbContext, and singleton lives for the whole application. The trap is captive dependency: injecting a scoped service into singleton can accidentally hold request-specific state forever.
```

## 4. How Do You Handle High Request Load?

Expected answer:

```text
Async, caching, DB optimization, queues, rate limiting, horizontal scale, observability.
```

Weak answer:

```text
Increase server size.
```

Strong answer:

```text
First I keep APIs non-blocking with async I/O. Then I reduce DB pressure using pagination, projection, indexes, and caching for hot reads. Heavy work moves to queues/background jobs. I add rate limiting for protection, monitor latency/errors, and scale stateless app instances horizontally if needed.
```

## 5. Explain Queue-Based Processing

Expected answer:

```text
API enqueues work, worker processes asynchronously, retry/failure monitoring handles reliability.
```

Weak answer:

```text
Queue is fire and forget.
```

Strong answer:

```text
Queues decouple the request from slow or unreliable work. For example, invoice generation or QuickBooks sync can be enqueued so the API responds quickly. A background worker processes messages with retries, idempotency, tenant context, logging, and dead-letter handling for failures.
```

## 6. How Do You Secure a Web API?

Expected answer:

```text
HTTPS, JWT validation, authorization, validation, rate limiting, CORS, logging, no secret leaks.
```

Weak answer:

```text
Use JWT.
```

Strong answer:

```text
JWT is one layer. I would enforce HTTPS, validate issuer/audience/expiry, use role or policy authorization, validate input, avoid leaking errors, configure CORS for trusted origins, apply rate limiting, store secrets safely, and log security-relevant failures.
```

## 7. What Is Idempotency?

Expected answer:

```text
Same request can be retried safely without duplicate side effects.
```

Weak answer:

```text
Same response.
```

Strong answer:

```text
Idempotency makes retry scenarios safe. The client sends an idempotency key, the server checks whether that key was already processed, and returns the previous result instead of creating duplicates. This matters for payments, invoice creation, queue consumers, and external sync.
```

