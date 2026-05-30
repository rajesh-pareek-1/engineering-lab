# Last 30 Minutes Before Interview

Use this when the interview is close. Do not wander. Read, speak, close.

## 1. Opening Pitch

```text
Hi, I am Rajesh Pareek. I am a software developer with hands-on experience across ASP.NET Core, EF Core, SQL, React, React Native, and Azure DevOps. I have worked on SaaS/logistics systems involving REST APIs, shipment and driver workflows, multi-tenant backend design, database optimization, background jobs, and web/mobile integrations. My strongest area is backend/product engineering where I can connect API design, data flow, performance, and production tradeoffs clearly.
```

## 2. RollOnDispatch Pitch

```text
RollOnDispatch is a multi-tenant logistics platform for trucking workflows. It handles shipment creation, driver assignment, load tracking, invoicing, reports, and QuickBooks sync. The backend follows controller-service-repository layering with EF Core and SQL. Tenant context comes from JWT/request context and resolves tenant-specific data access. Heavy work such as invoice generation and external sync is handled through background jobs and queue-style processing so APIs stay responsive.
```

## 3. Strongest Technical Story

```text
One strong area I can explain is multi-tenancy. Tenant identity comes from authenticated claims, flows into a scoped RequestContext, and tenant-aware services use that to resolve the correct database. The benefit is strong isolation and smaller blast radius. The tradeoff is operational complexity: migrations, connection pooling, cross-tenant reporting, and background job tenant safety must be designed carefully.
```

## 4. Top 25 One-Line Answers

1. Request lifecycle: `Client -> Kestrel -> middleware -> routing -> controller/action -> response back through middleware`.
2. Middleware: pipeline component for cross-cutting concerns; order matters.
3. Filters: MVC/action-level hooks; middleware is broader.
4. Global exception handling: central middleware returns consistent errors and logs once.
5. DI lifetimes: transient = new, scoped = per request, singleton = app lifetime.
6. DbContext: scoped because it tracks a unit of work and is not thread-safe.
7. JWT: middleware validates token and attaches claims to `HttpContext.User`.
8. OAuth vs OpenID: OAuth is access; OpenID Connect is login identity.
9. Auth vs authz: authentication proves identity; authorization checks permission.
10. Async/await: non-blocking I/O, not automatic parallelism.
11. `.Result`/`.Wait()`: blocks threads and can deadlock.
12. `Task.WhenAll`: start tasks first, await together for concurrency.
13. Queue: decouples slow/retryable work from request path.
14. Idempotency: retry-safe API using request/idempotency key.
15. Rate limiting: protects API from abuse/overload, returns 429.
16. In-memory vs Redis: local fast cache vs shared distributed cache.
17. `IEnumerable`: in-memory iteration.
18. `IQueryable`: expression tree translated by provider/DB.
19. N+1: one parent query plus N child queries; fix with projection/Include.
20. `AsNoTracking`: faster read-only EF queries.
21. Index: faster reads, slower writes, extra storage.
22. `WHERE` vs `HAVING`: rows before grouping vs groups after aggregation.
23. `throw` vs `throw ex`: preserve stack trace vs reset stack trace.
24. Dispose vs GC: resource cleanup now vs managed memory cleanup later.
25. SOLID: keep code testable, replaceable, and change-safe.

## 5. SQL Traps

```sql
-- 3rd highest salary
SELECT Salary
FROM (
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS r
    FROM Employees
) t
WHERE r = 3;
```

```text
WHERE filters rows before GROUP BY.
HAVING filters aggregate groups after GROUP BY.
EXISTS is best for presence checks.
Use projection and indexes before blaming the database.
```

## 6. C# Traps

```text
Assignment copies reference, mutation changes shared object.
string is immutable.
Boxing copies value type into heap object.
Multicast delegates return only the last method's value.
Closures capture variables, not values.
async void exceptions escape unless top-level event handler.
```

## 7. Resume Defense Lines

If asked "Did you really build this end-to-end?":

```text
I worked around this flow and can explain how it behaves end-to-end. For the parts I did not own completely, I understand the design, integration points, and tradeoffs.
```

If asked "What would you improve?":

```text
I would enforce pagination limits, improve tenant validation, make background jobs idempotent, monitor failures, and add explicit migration orchestration for tenant databases.
```

## 8. Closing Questions To Ask

- What are the biggest backend reliability challenges here?
- How do you handle observability for APIs and background jobs?
- How do you manage migrations and deployments?
- What would success look like in the first 90 days?

