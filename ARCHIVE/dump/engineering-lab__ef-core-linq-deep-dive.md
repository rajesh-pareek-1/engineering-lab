# EF Core and LINQ

## IEnumerable vs IEnumerator

| Topic | Meaning |
| --- | --- |
| `IEnumerable` | Represents something that can be iterated. |
| `IEnumerator` | Holds iteration state: `MoveNext`, `Current`. |

`foreach` uses an enumerator internally.

## IEnumerable vs IQueryable

| Topic | IEnumerable | IQueryable |
| --- | --- | --- |
| Executes | In memory | Provider/database |
| Query form | Delegates | Expression tree |
| Risk | Pulls too much data if used early | Provider translation limits |

Interview line:

```text
IQueryable lets EF Core translate filtering/projection into SQL. IEnumerable means the data is already in memory.
```

Bad:

```csharp
var users = await _context.Users.ToListAsync();
var active = users.Where(x => x.IsActive);
```

Better:

```csharp
var active = await _context.Users
    .Where(x => x.IsActive)
    .ToListAsync();
```

## Deferred Execution

LINQ queries run when enumerated.

Execution triggers:

- `foreach`
- `ToList()`
- `First()`
- `Count()`
- `Any()`

Trap:

```text
Multiple enumeration can repeat expensive work or repeat DB queries.
```

## Expression Trees

`IQueryable` captures query logic as an expression tree. EF Core translates it into SQL.

If EF cannot translate an expression, rewrite it or explicitly move to memory only after filtering.

## First, Single, Any, Count

| Method | Meaning |
| --- | --- |
| `First()` | Returns first match, throws if none. |
| `FirstOrDefault()` | Returns first match or default. |
| `Single()` | Requires exactly one match, throws if zero or many. |
| `SingleOrDefault()` | Allows zero or one, throws if many. |
| `Any()` | Existence check, stops early. |
| `Count()` | Counts all matching rows/items. |

Use `Any()` for existence checks.

## Include vs Select

| Method | Use |
| --- | --- |
| `Include` | Eager-load related entities. |
| `Select` | Project only required fields. |

Prefer projection for API DTOs:

```csharp
var shipments = await _context.Shipments
    .Where(x => x.Status == ShipmentStatus.Open)
    .Select(x => new ShipmentListItem
    {
        Id = x.Id,
        Number = x.Number,
        DriverName = x.Driver.Name
    })
    .ToListAsync();
```

## Lazy vs Eager Loading

- Lazy loading loads related data on demand.
- Eager loading loads related data upfront.
- Lazy loading can cause N+1 queries.

## N+1 Problem

Problem:

```text
1 query loads parent rows. Then N extra queries load children for each parent.
```

Fixes:

- Projection with `Select`
- `Include`
- Batching
- Explicit joins where needed

## AsNoTracking

Use for read-only queries:

```csharp
var rows = await _context.Shipments
    .AsNoTracking()
    .Where(x => x.TenantId == tenantId)
    .ToListAsync();
```

Benefit:

```text
No change tracking means less memory and faster read queries.
```

## SaveChanges

`SaveChanges` / `SaveChangesAsync`:

- Detects tracked entity changes.
- Wraps operations in a transaction by default for many providers.
- Sends SQL to DB.
- Updates entity states.

Avoid multiple `SaveChanges` in one workflow unless the partial commit is intentional.

## DbContext Lifetime

Use scoped lifetime.

Reasons:

- DbContext is not thread-safe.
- Tracks changes per unit of work/request.
- One request usually equals one transaction boundary.

## Transactions and ACID

ACID:

- Atomicity: all or nothing.
- Consistency: valid state.
- Isolation: concurrent transactions do not corrupt each other.
- Durability: committed data survives failure.

Use transactions when multiple operations must succeed or fail together.

## Repository Pattern

Repository separates data access from business logic.

Good use:

- Shared query helpers.
- Encapsulating DB details.
- Testing service layer.

Risk:

```text
Do not hide IQueryable too early if callers need composition. Avoid generic repository that prevents optimized queries.
```

## ORM, Code First, DB First

- ORM maps objects to relational data.
- EF Core is an ORM.
- Code First: classes drive schema/migrations.
- DB First: existing DB drives models.

## Production Query Checklist

Before saying "I optimized the query", mention:

1. Filter early.
2. Project only needed columns.
3. Avoid N+1.
4. Add indexes on WHERE/JOIN/ORDER columns.
5. Use `AsNoTracking` for read-only.
6. Check execution plan.
7. Add pagination/max limits.
8. Avoid unnecessary `ToList()`.

