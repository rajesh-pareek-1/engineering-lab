# Last-Minute Revision Path

## 1 Day Before Interview

Goal: confidence and retrieval speed. No new topic hunting.

### Morning: Backend Core

- Read `question-bank.md`.
- Speak these without looking: request lifecycle, middleware, global exception handling, DI lifetimes, JWT, async, queues, idempotency.
- Repair weak areas with `backend-webapi.md`.

### Midday: Data Layer

- Read `ef-core-linq.md` and `sql.md`.
- Write from memory: second highest salary per department, `EXISTS`, invalid date ranges, `IQueryable` vs `IEnumerable`, N+1 fix.
- Edge checks: `COUNT(*)` vs `COUNT(column)`, `LEFT JOIN` filtered in `WHERE`, `Any()` vs `Count()`.

### Afternoon: Project Defense

- Read `project-defense.md`.
- Speak the RollOnDispatch 90-second pitch.
- Speak multi-tenancy flow and tradeoffs.
- Prepare one honest line for work you understand but did not fully own.

### Evening: Mock Only

- Run `../mock-arenas/resume-based-round.md`.
- Run `../mock-arenas/backend-round.md`.
- Run `../mock-arenas/sql-round.md` if SQL is expected.
- Stop deep reading. Sleep matters.

## 3 Day Preparation

### Day 1: Backend And C#

- `backend-webapi.md`
- `csharp-runtime.md`
- `csharp-oop-solid.md`
- Mock: `../mock-arenas/backend-round.md`

Speak:

- Request lifecycle
- Middleware vs filters
- DI lifetimes and captive dependency
- `throw` vs `throw ex`
- Dispose vs Finalize
- Async vs threading

### Day 2: Data And Performance

- `ef-core-linq.md`
- `sql.md`
- `../coding-drills/csharp-output-traps.md`
- Mock: `../mock-arenas/sql-round.md`

Speak:

- `IQueryable` vs `IEnumerable`
- N+1
- Include vs Select
- AsNoTracking
- Index tradeoffs
- Query optimization checklist

### Day 3: Projects And React Native

- `project-defense.md`
- `react-native.md`
- `../mock-arenas/resume-based-round.md`
- `last-30-minutes.md`

Speak:

- Tell me about yourself
- RollOnDispatch project pitch
- Multi-tenancy request flow
- Background jobs and idempotency
- React Native lifecycle and FlatList performance

## 7 Day Preparation

### Day 1: Web API

- Read `backend-webapi.md`.
- Mock request lifecycle, middleware, exception handling, auth.

### Day 2: C# Runtime

- Read `csharp-runtime.md`.
- Practice output traps from `../coding-drills/csharp-output-traps.md`.

### Day 3: OOP/SOLID

- Read `csharp-oop-solid.md`.
- Prepare examples from project work, not only textbook definitions.

### Day 4: EF Core And SQL

- Read `ef-core-linq.md` and `sql.md`.
- Solve the SQL patterns without looking.

### Day 5: Project Deep Dive

- Read `project-defense.md`.
- Read `../projects-explained/roll-on-dispatch.md`.
- Read `../projects-explained/multitenancy-deep-dive.md`.

### Day 6: React Native And Coding

- Read `react-native.md`.
- Practice C# drills and JavaScript callback traps.

### Day 7: Mock Arenas

- Run backend, SQL, .NET, and resume mock packs.
- Use only `last-30-minutes.md` for the final pass.
