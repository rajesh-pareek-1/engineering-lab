# Prioritized Interview Question Bank

This is the deduplicated question bank from the scattered raw files.

## Tier A: Deep Mastery

These topics separate a production backend engineer from a feature-only coder.

1. ASP.NET Core request lifecycle
2. Middleware order and custom middleware
3. Global exception handling
4. Dependency injection lifetimes and captive dependency risks
5. DbContext lifetime and unit of work
6. IEnumerable vs IQueryable
7. LINQ deferred execution
8. N+1 query problem
9. SQL indexes and execution plans
10. Transactions and ACID
11. Async/await vs threading
12. Task.WhenAll vs WaitAll
13. Thread pool starvation
14. HttpClientFactory and socket exhaustion
15. Garbage collection generations
16. Dispose vs Finalize
17. Boxing/unboxing and generics
18. `throw` vs `throw ex`
19. JWT, OAuth, OpenID Connect
20. Caching: in-memory vs Redis/distributed
21. Queue systems and background workers
22. Idempotency
23. Rate limiting
24. SOLID principles with examples
25. Multi-tenant database-per-tenant design

## Tier B: Confident and Concise

1. MVC vs Web API
2. Razor vs MVC
3. IActionResult vs ActionResult<T>
4. Model binding
5. Filters vs middleware
6. Newtonsoft.Json vs System.Text.Json
7. Circular reference handling
8. API versioning
9. Content-Type vs Accept
10. CORS
11. API gateway
12. Monolith vs microservices
13. Service-to-service communication
14. Hangfire
15. Azure Service Bus
16. Repository pattern
17. ORM and EF Core
18. Code First vs DB First
19. Include vs Select
20. AsNoTracking
21. First vs Single
22. Any vs Count
23. Lock and ConcurrentDictionary
24. Connection pooling
25. Kestrel vs IIS
26. Docker and CI/CD basics
27. Logging and Application Insights
28. NuGet packages
29. Debug vs Release
30. bin vs obj

## Tier C: Fundamentals

1. C# vs .NET
2. Class vs object
3. OOP pillars
4. Constructor types
5. Interface vs abstract class
6. Overloading vs overriding
7. Encapsulation vs abstraction
8. Inheritance and sealed class
9. Static class
10. Partial class
11. String vs StringBuilder
12. ref vs out
13. var vs dynamic
14. const vs readonly
15. Value type vs reference type
16. Array vs List
17. List vs Dictionary
18. IEnumerable vs IEnumerator
19. Extension methods
20. Exception handling basics

## Top 20 Answers To Memorize

### 1. HTTP Lifecycle

```text
Request enters Kestrel, flows through middleware, matches routing, reaches controller/action, then response travels back through middleware in reverse.
```

### 2. Middleware

```text
Middleware is pipeline code for cross-cutting request/response concerns. Order matters because each component can short-circuit.
```

### 3. Global Exception Handling

```text
I prefer centralized exception middleware so controllers stay clean and all clients receive a consistent error shape with proper logging.
```

### 4. DI Lifetimes

```text
Transient creates new instances, scoped creates one per request, singleton creates one for app lifetime. DbContext should be scoped because it is not thread-safe and tracks one unit of work.
```

### 5. JWT

```text
JWT is validated by authentication middleware. If valid, claims are attached to HttpContext.User and authorization policies decide access.
```

### 6. OAuth vs OpenID

```text
OAuth is for delegated authorization. OpenID Connect adds authentication and identity on top of OAuth.
```

### 7. Async/Await

```text
Async/await is non-blocking I/O. It improves scalability by freeing request threads while waiting for DB or external API calls.
```

### 8. Queue System

```text
Queues decouple slow or unreliable work from the request path. They support retries, background processing, and smoother load handling.
```

### 9. Caching

```text
Caching stores hot data to reduce repeated DB calls. In-memory is fastest but per-instance; Redis is shared and better for multi-server deployments.
```

### 10. IEnumerable vs IQueryable

```text
IEnumerable works in memory. IQueryable builds expression trees that EF Core can translate to SQL, so filtering happens in the database.
```

### 11. N+1

```text
N+1 is one query for parents plus one query per parent for children. Fix it with projection, Include, batching, or joins.
```

### 12. SQL Optimization

```text
Filter early, project only needed columns, avoid N+1, add indexes on WHERE/JOIN columns, and verify with execution plan.
```

### 13. Dispose vs GC

```text
GC frees managed memory eventually. Dispose releases external resources like files, sockets, and DB connections immediately.
```

### 14. Throw vs Throw ex

```text
throw preserves the original stack trace. throw ex resets it and hides the true failure location.
```

### 15. Boxing

```text
Boxing copies a value type into an object on the heap, causing allocation and GC pressure. Generics avoid this.
```

### 16. Interface vs Abstract

```text
Interface is a contract. Abstract class can share partial implementation and state.
```

### 17. Liskov

```text
A child class should replace its parent without breaking expected behavior. If a child throws for a parent method, the abstraction is wrong.
```

### 18. Rate Limiting

```text
Rate limiting protects APIs from abuse and overload by restricting requests per user, IP, or token and returning 429 when exceeded.
```

### 19. HttpClientFactory

```text
Creating HttpClient per request can exhaust sockets. IHttpClientFactory manages handlers and connection reuse safely.
```

### 20. Idempotency

```text
Idempotency makes retries safe. Use an idempotency key so duplicate requests return the original result instead of creating duplicates.
```

