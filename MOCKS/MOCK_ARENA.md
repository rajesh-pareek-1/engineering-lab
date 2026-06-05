# MOCK_ARENA

Answer first. Then read the strong answer. Then answer again in fewer words.

## Backend Round

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

## .NET Deep Dive

## 1. C# vs .NET

Expected answer:

```text
C# is a language. .NET is the runtime/platform/framework ecosystem where C# code runs.
```

Weak answer:

```text
Both are same.
```

Strong answer:

```text
C# is the programming language. .NET includes the runtime, base class libraries, SDK, tooling, ASP.NET Core, EF Core ecosystem, and execution model through CLR/JIT. C# code compiles to IL, and .NET executes it.
```

## 2. CLR, IL, and JIT

Expected answer:

```text
C# compiles to IL, CLR loads it, JIT compiles to machine code at runtime.
```

Weak answer:

```text
CLR runs the program.
```

Strong answer:

```text
The C# compiler produces IL inside an assembly. The CLR provides services like GC, exception handling, security, and type safety. When code executes, JIT compiles IL into machine code for the current platform.
```

## 3. Value Type vs Reference Type

Expected answer:

```text
Value types copy values. Reference types copy references to objects.
```

Weak answer:

```text
Value is stack, reference is heap.
```

Strong answer:

```text
The important behavior is copying. With value types, assignment copies the data. With reference types, assignment copies the reference, so two variables can point to the same object. Mutation through one reference is visible through the other, but reassignment changes only that variable unless passed by ref.
```

## 4. Boxing and Unboxing

Expected answer:

```text
Boxing converts a value type into object; unboxing casts it back.
```

Weak answer:

```text
It changes type.
```

Strong answer:

```text
Boxing copies a value type into a heap object, which causes allocation and GC pressure. Unboxing extracts the value back with a runtime cast. Generics avoid boxing for value types, which is why List<int> is better than ArrayList.
```

## 5. Dispose vs Finalize

Expected answer:

```text
Dispose releases resources deterministically; Finalize runs later through GC.
```

Weak answer:

```text
Both clean memory.
```

Strong answer:

```text
GC handles managed memory, but resources like files, DB connections, and sockets need deterministic release. Dispose is called explicitly, often through using. Finalize is non-deterministic and should be for unmanaged cleanup safety, not normal resource management.
```

## 6. throw vs throw ex

Expected answer:

```text
throw preserves original stack trace; throw ex resets it.
```

Weak answer:

```text
Both throw exception.
```

Strong answer:

```text
Inside catch, using throw preserves the original failure stack trace. throw ex rethrows the same exception object but resets the stack trace from the rethrow line, hiding the real source and making production debugging harder.
```

## 7. Interface vs Abstract Class

Expected answer:

```text
Interface is contract; abstract class can share partial implementation/state.
```

Weak answer:

```text
Interface has only methods, abstract has methods with body.
```

Strong answer:

```text
I use interfaces for capabilities and dependencies, especially for DI and testing. I use abstract classes when related types share base behavior or state. A class can implement multiple interfaces but only inherit one base class, so interfaces keep design more flexible.
```

## 8. Liskov Substitution Principle

Expected answer:

```text
Child type should replace parent without breaking behavior.
```

Weak answer:

```text
It is about inheritance.
```

Strong answer:

```text
If code expects a parent type, any child type should work without surprises. Example: if Bird has Fly(), a Kiwi child that throws NotSupportedException violates LSP. Better design is Bird for common behavior and ICanFly only for birds that can fly.
```

## SQL Round

## 1. SQL Execution Order

Expected answer:

```text
FROM, JOIN, WHERE, GROUP BY, HAVING, SELECT, ORDER BY.
```

Weak answer:

```text
SELECT runs first.
```

Strong answer:

```text
Logically SQL starts from FROM/JOIN, filters rows with WHERE, groups with GROUP BY, filters groups with HAVING, projects columns in SELECT, and sorts at ORDER BY. This explains why SELECT aliases usually cannot be used in WHERE.
```

## 2. WHERE vs HAVING

Expected answer:

```text
WHERE filters rows before grouping; HAVING filters groups after aggregation.
```

Weak answer:

```text
Both filter data.
```

Strong answer:

```text
Use WHERE for row-level conditions like active employees. Use HAVING when the condition depends on aggregate result, such as departments with COUNT(*) > 5.
```

## 3. Rank vs Dense Rank

Expected answer:

```text
RANK leaves gaps after ties; DENSE_RANK does not.
```

Weak answer:

```text
Both give rank.
```

Strong answer:

```text
If salaries are 100, 100, 90 then RANK gives 1,1,3 while DENSE_RANK gives 1,1,2. For nth distinct salary, DENSE_RANK is often the cleaner choice.
```

## 4. Third Highest Salary

Strong answer:

```sql
SELECT Salary
FROM (
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS r
    FROM Employees
) t
WHERE r = 3;
```

## 5. Second Highest Salary Per Department

Strong answer:

```sql
WITH Ranked AS (
    SELECT e.*,
           DENSE_RANK() OVER (
               PARTITION BY DepartmentId
               ORDER BY Salary DESC
           ) AS SalaryRank
    FROM Employees e
)
SELECT *
FROM Ranked
WHERE SalaryRank = 2;
```

## 6. EXISTS vs JOIN

Expected answer:

```text
EXISTS checks presence; JOIN combines rows and may duplicate parent rows.
```

Weak answer:

```text
JOIN is always better.
```

Strong answer:

```text
For presence checks, EXISTS is usually clearer and avoids duplicates. JOIN is needed when I actually need columns from both tables. I would choose based on result shape and execution plan.
```

## 7. What Is an Index?

Expected answer:

```text
Data structure that speeds lookup/filter/sort at write/storage cost.
```

Weak answer:

```text
Index makes query fast.
```

Strong answer:

```text
An index helps SQL locate rows without scanning the whole table, especially on WHERE, JOIN, and ORDER BY columns. The tradeoff is extra storage and slower writes because indexes must be maintained.
```

## 8. Product IDs Where All Date Ranges Are Invalid

Strong answer:

```sql
SELECT ProductId
FROM Products
GROUP BY ProductId
HAVING SUM(CASE
    WHEN '2025-03-24' BETWEEN StartDate AND EndDate THEN 1
    ELSE 0
END) = 0;
```

Explanation:

```text
The SUM counts valid rows. If valid rows are zero, every row for that product is invalid.
```

## Resume-Based Round

## 1. Tell Me About Yourself

Expected answer:

```text
Clear role positioning, current company, tech stack, project domains, strongest area.
```

Weak answer:

```text
My name is Rajesh and I know .NET and React.
```

Strong answer:

```text
I am Rajesh Pareek, a software developer with hands-on experience across ASP.NET Core, EF Core, SQL, React, React Native, and Azure DevOps. At In Time Tec I have worked on SaaS/logistics workflows including REST APIs, shipment and driver features, multi-tenant backend systems, SQL performance, background jobs, and web/mobile integration. My strength is backend/product engineering: understanding flow, tradeoffs, and production behavior.
```

## 2. Explain RollOnDispatch

Strong answer:

```text
RollOnDispatch is a logistics platform for trucking workflows. It manages shipment creation, driver assignment, load status, invoicing, reporting, and QuickBooks sync. The backend follows controller-service-repository layering with EF Core and SQL. Tenant context is resolved per request, and heavier work is handled through background jobs/queue-style processing.
```

## 3. What Exactly Did You Work On?

Expected answer:

```text
Be specific and honest: APIs, validation, integration, performance, debugging, support.
```

Strong answer:

```text
I worked around API and product workflows such as shipment/driver-related features, validation, integration with frontend/mobile clients, query behavior, and production-style debugging. For areas I did not fully own, I can still explain the architecture and integration points because I worked around those flows.
```

## 4. Explain a Backend API You Built

Strong answer:

```text
For a create/update workflow, the request reaches the controller, model binding maps the DTO, the service validates and applies business rules, repository persists via EF Core, SaveChangesAsync commits, and the API returns a typed response. Cross-cutting concerns like auth, exception handling, and logging are handled outside the controller.
```

## 5. What Performance Improvement Did You Make?

Strong answer:

```text
The main pattern was reducing unnecessary DB and memory work: pagination, projection with Select, avoiding early ToList, using AsNoTracking for reads, checking indexes on filter/join columns, and avoiding N+1 query patterns. The idea is to push work to SQL and fetch only what the screen/API needs.
```

## 6. Explain Multi-Tenancy From Your Resume

Strong answer:

```text
Tenant identity comes from authenticated claims and flows into a scoped request context. Tenant-aware services use that TenantId to resolve the correct tenant database/connection and create a DbContext for that request. This gives strong isolation, but migrations, connection pooling, cross-tenant reporting, and background job context must be handled carefully.
```

## 7. What Is Your Strongest Backend Concept?

Strong answer:

```text
I am strongest at explaining API request flow and data access performance: how middleware/auth/model binding/controller/service/repository/EF Core work together, and how to avoid common production issues like blocking async calls, N+1 queries, missing pagination, and weak exception handling.
```

## 8. What Would You Improve In Your Project?

Strong answer:

```text
I would enforce pagination limits, add optimistic concurrency where conflicts matter, strengthen tenant validation before DB access, make background jobs explicitly idempotent, improve migration orchestration across tenant databases, and ensure logs/metrics make failures easy to diagnose.
```

## 9. React Native Resume Question

Strong answer:

```text
On React Native/mobile, I worked with TypeScript, navigation, API integration, Redux-style state management, secure storage, push notifications, geolocation/timezone flows, document/image handling, and offline-aware workflows. The main challenge is keeping UI state, API state, and network failures predictable.
```

## 10. When You Do Not Know Something

Use:

```text
I have not implemented that exact piece end-to-end, but my understanding is...
```

Then answer with:

```text
Flow -> reason -> tradeoff
```
