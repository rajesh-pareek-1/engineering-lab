# Priority Roadmap

Use this as the home page for revision.

Fastest path:

1. `last-minute-interview.md`
2. `notes/question-bank-prioritized.md`
3. `experience/roll-on-dispatch.md`
4. `mock-interviews/resume-based-round.md`

## Phase Order

1. Multi-tenancy and request flow
2. Query optimization and EF Core
3. Concurrency, async, deadlocks, and background jobs
4. Caching, rate limiting, and high-request handling
5. Hangfire, queues, and idempotency
6. CI/CD, Docker, deployment, and migrations
7. Observability, logging, exception handling, and production debugging

## Top 15 Topics To Speak Out Loud

1. ASP.NET Core request lifecycle
2. Middleware order and custom middleware
3. Global exception handling
4. Dependency injection lifetimes
5. JWT, OAuth, OpenID Connect, auth vs authz
6. Async/await, Task.WhenAll, and why .Result is dangerous
7. IEnumerable vs IQueryable
8. EF Core N+1, Include, Select, AsNoTracking
9. DbContext lifetime and connection pooling
10. SQL indexes, WHERE vs HAVING, execution order
11. Garbage collection, Dispose vs Finalize
12. Boxing/unboxing and generics performance
13. SOLID with real project examples
14. RollOnDispatch architecture and tradeoffs
15. Multi-tenant database-per-tenant architecture

## Daily 45 Minute Loop

1. 10 minutes: Read one notes file.
2. 10 minutes: Speak answers without looking.
3. 10 minutes: Solve two coding/output traps.
4. 10 minutes: Explain one project flow end-to-end.
5. 5 minutes: Write weak topics for tomorrow.

## Answer Template

```text
Definition:
Insight:
Project example:
Tradeoff:
```

Never answer as a dictionary definition only. Always add the production reason.
