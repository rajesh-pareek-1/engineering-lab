# EF Core And LINQ Revision

## Must-Say Lines

- `IQueryable` builds expression trees that EF Core can translate to SQL.
- `IEnumerable` means in-memory iteration.
- LINQ has deferred execution; queries run when enumerated/materialized.
- Prefer projection with `Select` for API DTOs.
- Use `AsNoTracking` for read-only queries.
- Avoid N+1 with projection, `Include`, batching, or explicit joins.
- DbContext should be scoped; it tracks a unit of work and is not thread-safe.

## Query Shape

Bad:

```csharp
var users = await _context.Users.ToListAsync();
var active = users.Where(x => x.IsActive);
```

Good:

```csharp
var active = await _context.Users
    .Where(x => x.IsActive)
    .Select(x => new UserDto { Id = x.Id, Name = x.Name })
    .ToListAsync();
```

Edge cases:

- Calling `ToList()` too early moves work to memory.
- Multiple enumeration can repeat DB queries.
- EF cannot translate every C# method; rewrite or intentionally switch to memory after filtering.

## Execution Triggers

- `foreach`
- `ToList()` / `ToArray()`
- `First()` / `Single()`
- `Count()`
- `Any()`

Use `Any()` for existence checks because it can stop early.

## First, Single, Any, Count

| Method | Use | Trap |
| --- | --- | --- |
| `First()` | Need first row | Throws if none |
| `FirstOrDefault()` | First or none | Default can hide missing data |
| `Single()` | Exactly one | Throws on zero or many |
| `SingleOrDefault()` | Zero or one | Throws on many |
| `Any()` | Existence | Best for yes/no |
| `Count()` | Total count | May scan/count all matches |

## Loading And Tracking

| Tool | Use |
| --- | --- |
| `Include` | Load related entities when entity graph is needed. |
| `Select` | Project only required fields. Prefer for API responses. |
| Lazy loading | Convenient but can cause N+1. |
| `AsNoTracking` | Faster read-only queries. |

N+1 answer:

```text
N+1 is one query for parent rows plus one query per parent for children. I fix it with projection, Include, batching, or joins depending on result shape.
```

## SaveChanges And Transactions

- `SaveChangesAsync` detects tracked changes, sends SQL, and updates states.
- Many providers wrap a single SaveChanges batch in a transaction.
- Avoid multiple SaveChanges in one workflow unless partial commit is intentional.
- Use explicit transactions when multiple operations must succeed/fail together.

ACID:

- Atomicity: all or nothing.
- Consistency: valid state.
- Isolation: concurrent transactions do not corrupt each other.
- Durability: committed data survives failure.

## DbContext Lifetime

Strong answer:

```text
DbContext is scoped because it represents a unit of work, tracks changes, and is not thread-safe. In web APIs, one request usually maps naturally to one scoped context.
```

Edge cases:

- Do not share DbContext across threads.
- Long-lived contexts grow tracking memory and stale state.
- Tenant-specific systems may need runtime factory creation instead of startup-registered DbContext.

## Repository Pattern

Good:

- Encapsulate persistence details.
- Reuse common query helpers.
- Test service layer.

Risk:

- Generic repositories can hide `IQueryable` too early.
- Do not force all queries through unoptimized CRUD methods.

## Production Query Checklist

1. Filter early.
2. Project only needed columns.
3. Avoid N+1.
4. Use `AsNoTracking` for read-only.
5. Add indexes on `WHERE`, `JOIN`, `ORDER BY` columns.
6. Add pagination/max limits.
7. Avoid early `ToList()`.
8. Check generated SQL and execution plan.

Common questions:

- `IEnumerable` vs `IQueryable`?
- Include vs Select?
- Lazy vs eager loading?
- Why scoped DbContext?
- How do you optimize EF Core queries?
