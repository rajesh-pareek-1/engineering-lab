# 8. .NET, EF Core, and SQL - The Full-Stack Bridge

## Request path

```text
POST /api/loads
  → authentication / authorization
  → controller binds request DTO
  → service validates shipment and tenant
  → repository / EF Core
  → SQL transaction
  → response DTO / status
  → RTK Query cache update
```

## Controller-service-repository

> The controller owns HTTP concerns, the service coordinates the use case and business rules, and the repository/EF Core context handles persistence. Transactions belong at the use-case boundary that knows which writes form one operation.

```csharp
[HttpPost("{driverLoadId:int}/attachments")]
[Authorize]
public async Task<ActionResult<AttachmentDto>> Upload(
    int driverLoadId,
    AttachmentRequest request,
    CancellationToken cancellationToken)
{
    var result = await attachmentService.UploadAsync(
        driverLoadId,
        request,
        cancellationToken);

    return Ok(result);
}
```

## DTO connection

Backend:

```csharp
public sealed record ShipmentSummaryDto(
    int ShipmentId,
    string Reference,
    string Status);
```

Frontend:

```ts
export interface ShipmentSummaryDto {
    shipmentId: number;
    reference: string;
    status: string;
}
```

> OpenAPI generation can produce the TypeScript shape, reducing manual mismatch. Runtime compatibility and backward-compatible deployment still matter.

## EF Core query

```csharp
var shipments = await db.Shipments
    .AsNoTracking()
    .Where(x => x.TenantId == tenantId && x.Status == status)
    .OrderByDescending(x => x.CreatedAt)
    .Skip(offset)
    .Take(limit)
    .Select(x => new ShipmentSummaryDto(
        x.ShipmentId,
        x.Reference,
        x.Status.Name))
    .ToListAsync(cancellationToken);
```

Mnemonic: **F-S-P-M** - Filter, Sort, Project, Materialize.

## Eager vs lazy loading

```csharp
var shipment = await db.Shipments
    .Include(x => x.DriverLoads)
        .ThenInclude(x => x.Associate)
    .SingleAsync(x => x.ShipmentId == id);
```

> Eager loading explicitly retrieves related data. Lazy loading retrieves it when navigation is accessed and can hide N+1 queries. For APIs, explicit projection is often the most predictable.

## Transaction example

```csharp
await using var transaction =
    await db.Database.BeginTransactionAsync(cancellationToken);

try
{
    driverLoad.Status = DriverLoadStatus.Dispatched;
    shipment.LoadBoardLastUpdatedTime = DateTime.UtcNow;

    await db.SaveChangesAsync(cancellationToken);
    await transaction.CommitAsync(cancellationToken);
}
catch
{
    await transaction.RollbackAsync(cancellationToken);
    throw;
}
```

> One `SaveChanges` is transactional by default. Use explicit transaction control for multiple database operations/saves that form one business unit. Keep transactions short and avoid network calls inside them.

## Ambient transaction

> A `TransactionScope` provides an ambient transaction through `Transaction.Current`. Supported database connections opened inside can automatically enlist. With `await`, use `TransactionScopeAsyncFlowOption.Enabled`. Not calling `Complete()` causes rollback on disposal.

## SQL performance

> Start from the slow endpoint and parameters, inspect generated SQL and actual execution plan, check returned rows/columns, N+1 behavior, indexes, joins, sorts, and logical reads, then retest. A scan is not automatically wrong and an index is not automatically helpful.

## Change tracker logging

```csharp
db.ChangeTracker.DetectChanges();

foreach (var entry in db.ChangeTracker.Entries()
             .Where(x => x.State != EntityState.Unchanged))
{
    logger.LogDebug(
        "Tracking {Entity} in state {State}; changed {Properties}",
        entry.Metadata.ClrType.Name,
        entry.State,
        entry.Properties.Where(x => x.IsModified)
            .Select(x => x.Metadata.Name));
}
```

> Log entity type, key, state, and changed property names; avoid sensitive values. EF command logging answers what SQL was sent, while ChangeTracker answers what EF believes changed.

## Full-stack consistency

> The server is authoritative for business state. The UI can optimistically represent low-risk changes, but critical shipment or financial status should be confirmed by the API. Concurrency conflicts should return a clear status such as 409 so the client can refresh rather than silently overwrite newer work.

