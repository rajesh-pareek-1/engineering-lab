# 22-Day Hands-On Engineering Sprint

> **Outcome:** You can write SQL under pressure, walk through a small system design clearly, navigate a .NET production codebase confidently, and explain a CI/CD release without guessing.

## Operating rules

```text
Every study session = 20% learn + 70% type/build + 10% speak from memory.
No video without a typed output.
No query copied before attempting it yourself for 10 minutes.
Every Sunday: one mock interview, one weak-area repair.
```

### Daily baseline

| Block | Weekday | Weekend / free day |
|---|---:|---:|
| SQL hands-on | 45 min | 90 min |
| Build/design/.NET | 60 min | 120 min |
| Recall aloud + notes | 15 min | 30 min |

Use SQL Server 2019 practice setup already in:

[SQL Server 2019 Practice](/Users/RajeshPareek/Downloads/engineering-lab-fresh/Arena-Backend-Pitch/Hands-On/SQL-Server-2019-Practice/README.md)

---

## Phase 1 — SQL muscle memory (Days 1–5)

**Checkpoint:** without notes, write joins, group/having, CTE/window functions, transactions, indexes, pagination, and explain the plan.

### Day 1 — Setup + core reads

- Start local SQL Server practice environment.
- Run schema and seed scripts.
- Type: `SELECT`, `WHERE`, `ORDER BY`, `TOP`, `DISTINCT`, `IN`, `BETWEEN`, `LIKE`, `CASE`.
- Write five queries without copying.

**Deliverable:** `day-01.sql` with comments explaining each query.

### Day 2 — Joins + aggregation

- Write `INNER JOIN`, `LEFT JOIN`, self join (employee → manager).
- Find records with no related row using `LEFT JOIN ... WHERE right.Id IS NULL`.
- Write `GROUP BY`, `HAVING`, `COUNT`, `SUM`, `AVG`.

**Speak:** “`WHERE` filters rows before grouping; `HAVING` filters groups after aggregation.”

### Day 3 — Window functions + duplicates

- Write `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`.
- Get second/third highest salary.
- Delete duplicate emails but keep newest ID—first `SELECT`, then use a rollback transaction.

**Deliverable:** one query for each window function plus a duplicate-safe deletion script.

### Day 4 — CTEs, procedures, views, transactions

- Build one CTE and one recursive CTE (employee hierarchy).
- Create a stored procedure with parameters and a view with a join.
- Write `BEGIN TRANSACTION → UPDATE → SELECT verify → ROLLBACK / COMMIT`.

**Speak:** “A transaction makes related DB changes atomic; `ReadCommitted` prevents dirty reads.”

### Day 5 — Index and execution-plan lab

- Create an intentionally slow filtered/sorted query.
- Enable **Actual Execution Plan** and `SET STATISTICS IO, TIME ON`.
- Identify scan/lookup/sort/estimated-vs-actual issue.
- Add one justified composite/covering index; compare before/after logical reads.

**Deliverable:** screenshot or notes: query → old plan → index → measured improvement → write-cost tradeoff.

Reference: [SQL patterns](/Users/RajeshPareek/Downloads/engineering-lab-fresh/Arena-Backend-Pitch/16-sql-interview-patterns-and-syntax.md)

---

## Phase 2 — System design from zero (Days 6–10)

**Checkpoint:** You can answer any basic design question with requirements, API, data model, scale, failure path, and tradeoffs.

### The answer framework: `R-A-D-S-F-T`

```text
R = Requirements: users, actions, non-functional needs
A = APIs: endpoint + request/response + auth
D = Data: entities, cardinality, indexes, consistency
S = Sequence: normal request flow
F = Failure + scale: retries, rate limits, queue/cache, observability
T = Tradeoffs: why this simple version now; next scale step
```

### Day 6 — Design language + first API

- Draw a request: React/mobile → API gateway/load balancer → .NET API → SQL.
- Design **Document Upload**: requirements, API, `Attachment` data model, Blob vs SQL metadata.
- Explain authentication, tenant isolation, validation, error response.

### Day 7 — Database design

- Design **Cart + Checkout**: User, Product, Cart, CartItem, Order, OrderItem, Inventory.
- State cardinality: one Cart → many CartItems; one Product → many OrderItems.
- Add indexes and explain what must be transactional (stock/order).

### Day 8 — Scale + async design

- Design **document-expiry reminders for 100k drivers**.
- Decide daily scheduler → chunked processing → queue → workers → notification provider.
- Add idempotency, retries, dead-letter queue, correlation ID.

### Day 9 — Real-time design

- Design **user count turns flag red above 50,000**.
- Event source → counter/Redis → threshold evaluator → SignalR group broadcast.
- Explain why SignalR is notification/display, not the authoritative count.

### Day 10 — Mock design round

Pick one at random: rate limiter, URL shortener, file upload, notification platform, order checkout.

**Deliverable:** 10-minute whiteboard answer using `R-A-D-S-F-T`, then record yourself explaining it.

---

## Phase 3 — .NET environment and production mechanics (Days 11–15)

**Checkpoint:** You can create, debug, test, profile, package, and inspect a small .NET API instead of only describing one.

### Day 11 — IDE and solution anatomy

- Use Visual Studio or Rider: breakpoints, conditional breakpoint, watch window, call stack, exception settings, search all files, Git diff.
- Create a `.NET 8` Web API solution with controller, service, repository, DTO, EF `DbContext`.
- Trace one request end-to-end in debugger.

### Day 12 — EF Core lab

- Add SQL Server, migration, entity configuration, seed data.
- Implement `AsNoTracking`, projection, `Include`, `AsSplitQuery`, pagination.
- Deliberately cause N+1, log generated SQL, then fix it.

### Day 13 — Security + error handling

- Add JWT authentication and role policy to mini API.
- Add global exception middleware / problem details.
- Add input validation and never return raw exception details to client.

### Day 14 — Logging, telemetry, testing

- Inject `ILogger<T>`; write structured logs with safe correlation/tenant identifiers.
- Add one unit test with xUnit + Moq and one integration-style API test.
- Add a simple OpenTelemetry/Activity trace design; distinguish it from current ROD source-backed logging.

### Day 15 — Background + file processing

- Add a simple scheduled/background workflow; explain `IHostedService` versus Hangfire.
- Implement a file metadata flow: validate → store → DB transaction boundary → response.
- Draw failure/retry/idempotency decision.

---

## Phase 4 — Azure/DevOps audit, not vocabulary (Days 16–18)

**Checkpoint:** You can read a pipeline YAML and state exactly what it proves, what it does not prove, and how a safe release works.

### Day 16 — Docker

- Read a Dockerfile line by line: base image, restore/build/publish stage, runtime stage, port, environment variables.
- Build and run your mini API container locally.
- Explain image vs container, tag vs digest, and why secrets do not belong in an image.

### Day 17 — Azure pipeline audit

- Read ROD `azure-pipeline.yml` line by line.
- Map: trigger → restore → test → feature config → migration artifact → Docker build → tag → ACR push.
- Write one sentence for each stage: input, output, failure effect.

### Day 18 — Release + operations

- Draw: immutable image + artifact → approval → migration compatibility → deployment → health check → monitoring → rollback.
- Learn Azure meanings: ACR, App Service/AKS conceptually, Blob, Notification Hubs, Service Bus, Application Insights.
- Practice this honesty line: “The repository proves CI and image publication; I only claim a deployed service when I have environment evidence.”

---

## Phase 5 — Join it together (Days 19–22)

**Checkpoint:** You have a portfolio-quality mini API, a repeatable project story, and can survive follow-ups.

### Day 19 — Build a vertical slice

Choose **Shipment Search** or **Document Upload**.

```text
Endpoint → validation → service → EF query/repository → SQL
        → structured log → response DTO → unit test
```

Include filtering, pagination, authorization, and safe error handling.

### Day 20 — Production hardening

- Add index justified by the search query.
- Add trace/log context and timing.
- Add rate-limit design and response codes.
- Add Docker build; write README request/response samples.

### Day 21 — Interview rehearsal

Run three 20-minute rounds:

1. SQL live coding: duplicate delete, top-N-per-group, join, index explanation.
2. System design: document reminder or checkout.
3. Project deep dive: architecture, tenant flow, expiry reminder, CI/CD, one incident.

For every missed question, add a 3-line correction note—not a new 10-page note.

### Day 22 — Final proof day

- Rebuild/run API from clean state.
- Explain its request flow without opening notes.
- Explain one SQL execution plan and index tradeoff.
- Explain CI → artifact → image → release flow.
- Update resume/GitHub README only with claims you can demonstrate.

---

## Weekly scoreboard

| Skill | Evidence you should have by Day 22 |
|---|---|
| SQL | 20+ typed queries, duplicate-delete transaction, one plan/index comparison |
| System design | 5 one-page designs using `R-A-D-S-F-T` |
| .NET | One runnable vertical slice with auth, EF, error handling, logs, tests |
| DevOps | One Docker run, one pipeline audit, one release diagram |
| Interview | Two recorded mocks + a weak-question correction list |

## The only question at the end of each day

> “What can I now build, write, debug, or explain without looking at notes?”

If the answer is only “I watched a video,” the day does not count.
