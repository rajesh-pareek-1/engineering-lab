# 7. EF Core, LINQ, and Async/Await

## EF Core mind map

```text
DbContext = unit of work
├── DbSet<TEntity>
├── model mapping
├── LINQ expression
├── SQL translation
├── change tracker
├── SaveChanges transaction
└── migrations
```

## `DbContext`

> `DbContext` represents a session/unit of work with the database. It translates LINQ expression trees, tracks entity changes, and saves them. It is normally scoped per request, is not thread-safe, and should not be held globally.

## Interview answer: explain EF Core

> Entity Framework Core is Microsoft's cross-platform ORM for .NET. It maps C# entity classes and relationships to relational database tables, lets us compose queries using LINQ, translates supported expression trees into SQL, tracks entity state, persists changes through `SaveChanges`, and manages schema evolution through migrations. In ROD, repositories use EF Core with SQL Server for shipments, driver loads, attachments, users, and tenant-aware data.

Mnemonic: **M-Q-T-S-M**

- **M - Mapping:** classes/properties/relationships to tables/columns/keys.
- **Q - Query translation:** LINQ expression to parameterized SQL.
- **T - Tracking:** Added, Modified, Deleted, Unchanged, Detached.
- **S - Save:** unit of work and transactional persistence.
- **M - Migrations:** version-controlled schema changes.

### End-to-end example

```csharp
var shipment = await db.Shipments
    .Include(x => x.DriverLoads)
    .SingleAsync(
        x => x.ShipmentId == shipmentId &&
             x.TenantId == tenantId,
        cancellationToken);

shipment.LoadBoardLastUpdatedTime = DateTime.UtcNow;

await db.SaveChangesAsync(cancellationToken);
```

> EF translates the LINQ predicate into SQL, materializes and tracks the shipment plus loads, detects the modified property, creates a parameterized `UPDATE`, and executes it when `SaveChangesAsync` is called. One `SaveChanges` is transactional for its generated database commands.

### Benefits and trade-offs

Benefits:

- productive, type-safe application queries;
- relationship mapping and change tracking;
- parameterization reduces SQL injection risk;
- provider integration, async methods, migrations;
- unit-of-work behavior through `DbContext`.

Trade-offs:

- poorly shaped LINQ can generate slow SQL;
- `Include` can over-fetch or create large joins;
- lazy loading can cause N+1 queries;
- tracking large read results costs memory;
- provider-specific SQL knowledge is still necessary.

Cross-question: **Is EF Core a replacement for SQL knowledge?**

> No. I inspect generated SQL and execution plans, understand indexes, joins, transactions, and database constraints, and use raw SQL or stored procedures when a measured case justifies it.

## Tracking vs no tracking

> Tracking queries are useful when loaded entities will be modified and saved. `AsNoTracking` avoids change-tracker overhead for read-only operations. Projection to DTOs is often even better because it selects only needed data.

Cross-question: **Does `AsNoTracking` always make everything faster?**

> It reduces tracking overhead for reads, but performance depends on query shape and result size. Tracking can provide identity resolution and is needed for convenient updates. Measure the actual workload.

## Loading related data: **E-E-L**

- **Eager:** `Include`; load relationships in the query.
- **Explicit:** load a relationship deliberately later.
- **Lazy:** automatic on navigation access; convenient but can hide N+1 queries.

> I prefer deliberate eager loading or projection for APIs. I inspect generated SQL and avoid large Cartesian results from excessive includes. Split queries may help some multi-collection includes but add round trips and consistency considerations.

### Eager loading vs lazy loading - interview-ready code

Eager loading asks EF Core for the relationship as part of the query:

```csharp
var shipments = await db.Shipments
    .AsNoTracking()
    .Include(s => s.Driver)
    .Where(s => s.Status == ShipmentStatus.Ready)
    .ToListAsync();
```

> I use eager loading when I already know the response needs the relationship. It makes database access visible, but multiple collection includes can create large joins. For APIs, projection is often better than loading complete graphs.

```csharp
var shipments = await db.Shipments
    .AsNoTracking()
    .Where(s => s.Status == ShipmentStatus.Ready)
    .Select(s => new ShipmentListItem
    {
        Id = s.Id,
        Reference = s.Reference,
        DriverName = s.Driver.Name
    })
    .ToListAsync();
```

Lazy loading automatically queries a navigation when it is first accessed. It normally requires the proxies package, proxy configuration, and a `virtual` navigation:

```csharp
services.AddDbContext<AppDbContext>(options =>
    options.UseLazyLoadingProxies()
           .UseSqlServer(connectionString));

public class Shipment
{
    public int Id { get; set; }
    public int DriverId { get; set; }
    public virtual Driver Driver { get; set; } = default!;
}
```

```csharp
var shipments = await db.Shipments.ToListAsync(); // query 1

foreach (var shipment in shipments)
{
    Console.WriteLine(shipment.Driver.Name);       // may run N more queries
}
```

**One-line comparison:**

> Eager loading is explicit at query time; lazy loading is implicit at navigation-access time. Lazy loading is convenient but can hide N+1 queries, so for REST APIs I prefer projection or deliberate eager loading.

Explicit loading is the controlled third option:

```csharp
var shipment = await db.Shipments.FindAsync(id);
await db.Entry(shipment!).Reference(s => s.Driver).LoadAsync();
```

## N+1 problem

> N+1 occurs when one query loads parents and then one additional query runs for each parent's related data. It increases latency and database load. Fix with projection, suitable `Include`, joining/aggregation, or batching.

## LINQ execution route

Mnemonic: **F-S-P-M**

1. **F - Filter** at database (`Where`).
2. **S - Sort** deterministically (`OrderBy`).
3. **P - Project** required columns (`Select`).
4. **M - Materialize** once (`ToListAsync`).

Bad:

```csharp
var all = await db.Shipments.ToListAsync();
var result = all.Where(x => x.Status == "Ready");
```

Better:

```csharp
var result = await db.Shipments
    .AsNoTracking()
    .Where(x => x.Status == ShipmentStatus.Ready)
    .Select(x => new ShipmentDto(x.Id, x.Reference))
    .ToListAsync(cancellationToken);
```

## `First`, `Single`, and `Find`

- `First`: first match; throws if absent.
- `FirstOrDefault`: first or default/null.
- `Single`: exactly one; throws if zero or multiple.
- `SingleOrDefault`: zero or one; throws if multiple.
- `Find/FindAsync`: primary-key lookup; can use tracked local entity first.

> I use `Single` when uniqueness is an invariant and preferably enforce it with a database unique constraint. I use `First` when several matches are legitimate and ordering defines which one.

## `IEnumerable` vs `IQueryable`

> `IQueryable` composes an expression for database translation. Calling `AsEnumerable`, `ToList`, or using an untranslatable operation moves subsequent work to memory or fails translation. I keep data-reducing work in SQL and materialize at the boundary.

## `SaveChanges` and transactions

> One `SaveChanges` call is transactional for its database writes by default. Use an explicit transaction when multiple `SaveChanges` calls or additional database operations must succeed together. Keep transactions short and avoid network calls inside them when possible.

Cross-question: **Why avoid external calls inside SQL transactions?**

> External latency keeps locks and connections open longer, increases contention, and still cannot be rolled back atomically. Use outbox/compensation or carefully order operations.

## Optimistic concurrency

> Add a row-version/concurrency token. EF includes the original token in the update condition. If another writer changed the row, zero rows are updated and EF throws `DbUpdateConcurrencyException`. The API can reload, merge when safe, retry, or return `409 Conflict`.

## Migrations

> EF migrations version schema changes. Generate and review the migration, inspect SQL for production impact, test with realistic data, deploy in a backward-compatible sequence, and plan rollback or forward-fix. Large index/table changes may require special operational handling.

## Async/await mental model

```text
start I/O
  → await yields thread
  → I/O completes
  → continuation resumes
  → response continues
```

> `async`/`await` does not automatically create a new thread. For database or network I/O, awaiting frees the request thread to serve other work, improving scalability. For CPU-heavy work, async alone does not reduce CPU cost.

## `Task` vs thread

> A `Task` represents an asynchronous operation and may not occupy a thread while waiting for I/O. A thread is an execution resource. The runtime and task scheduler manage continuations.

## Async rules: **A-C-N-W**

- **A - Async all the way:** avoid `.Result` and `.Wait()`.
- **C - Cancellation:** accept and pass `CancellationToken`.
- **N - No `async void`:** except event handlers.
- **W - WhenAll:** use for independent operations, not parallel use of one `DbContext`.

Cross-question: **Can two EF queries run concurrently on one context?**

> No. `DbContext` is not thread-safe and does not support overlapping operations. Use sequential queries, combine them, or use separate contexts when truly justified.

Cross-question: **`Task.WhenAll` vs sequential awaits?**

> `WhenAll` can reduce latency when operations are independent and safe to run concurrently. Sequential awaits are required when later work depends on earlier results or resources are not concurrency-safe.

## Cancellation

> Pass `HttpContext.RequestAborted` or action cancellation tokens through EF and HTTP calls. Cancellation saves resources when the client disconnects, but business operations that must complete independently should be handed to a durable background job rather than tied to the request.

## Common EF performance checklist: **N-P-I-R-T**

- **N - No tracking** for read-only.
- **P - Projection and pagination.**
- **I - Indexes** matching filters/sorts.
- **R - Round trips** and N+1 reduction.
- **T - Translated SQL** and execution plan inspection.
