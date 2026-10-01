# Pratham Software - one-day SQL crash sprint

> **Goal for tomorrow:** write common SQL from a blank editor, explain each choice, and connect query performance to EF Core/API behavior.
>
> **Rule:** spend 70% of time typing SQL, 20% explaining it aloud, and 10% reviewing corrections. Do not spend today passively reading every backend sheet.

## The SQL answer engine: S-H-A-P-E

```text
S = Shape the rows: FROM and JOIN
H = Hide unwanted rows: WHERE
A = Aggregate: GROUP BY and aggregate functions
P = Post-filter groups: HAVING
E = Expose/order result: SELECT and ORDER BY
```

For performance answers, use:

```text
Measure -> execution plan -> smallest query/index fix -> re-measure
```

---

# Block 0 - setup and speaking warm-up (15 min)

Open SQL Server Management Studio, Azure Data Studio, a local SQL Server container, or a browser SQL editor.

Use this mental schema throughout:

```text
Tenants(TenantId, Name)
Drivers(DriverId, TenantId, Name, Email, IsActive)
Shipments(ShipmentId, TenantId, DriverId, Status, CreatedAt, Amount)
Attachments(AttachmentId, DriverId, Type, Expiry, CreatedAt)
```

Say aloud:

```text
Driver 1 -> many Shipments
Driver 1 -> many Attachments
Tenant 1 -> many Drivers and Shipments
```

- [ ] **Done when:** You can name the join keys without looking at notes.

---

# Block 1 - joins, group, having, CASE, and DELETE (90 min)

## Drill 1 - joins

Write from blank:

1. `INNER JOIN` shipments with drivers.
2. `LEFT JOIN` drivers who have no shipments.
3. All unassigned shipments, newest first.

Interview lines:

```text
INNER JOIN -> only matches on both sides
LEFT JOIN  -> preserve every left-side row, even without a match
```

## Drill 2 - grouping

Write:

1. Shipment count per driver.
2. Drivers with more than five shipments.
3. Total shipment amount per tenant.

```text
WHERE  -> filters rows before GROUP BY
HAVING -> filters aggregate groups after GROUP BY
```

## Drill 3 - CASE

Write a query that shows:

```text
Amount >= 10000 -> High
Amount >= 5000  -> Medium
otherwise       -> Low
```

Then write conditional aggregation:

```text
count assigned shipments
count delivered shipments
count pending shipments
per tenant
```

## Drill 4 - duplicates and DELETE safely

```sql
WITH DuplicateUsers AS
(
    SELECT Id,
           ROW_NUMBER() OVER
           (
               PARTITION BY Email
               ORDER BY Id
           ) AS RowNumber
    FROM Users
)
DELETE FROM DuplicateUsers
WHERE RowNumber > 1;
```

Say aloud:

```text
First run the CTE as SELECT.
Then wrap destructive work in a transaction.
Keep the lowest Id.
Then add a UNIQUE constraint/index to prevent recurrence.
```

- [ ] **Done when:** You can write every drill without copying and explain `WHERE` versus `HAVING`.

---

# Block 2 - window functions (90 min, highest priority)

## The mental model

```text
GROUP BY
-> collapses rows into one row per group

Window function
-> keeps every row but calculates across its related rows
```

```sql
Function() OVER
(
    PARTITION BY GroupColumn
    ORDER BY SortColumn
)
```

## Must-write queries

1. `ROW_NUMBER()` - latest attachment per driver/type.
2. `RANK()` - salary ranking with gaps after ties.
3. `DENSE_RANK()` - eighth highest distinct salary.
4. `LAG()` - compare this year's student score to previous year.
5. `LEAD()` - next shipment date for a driver.
6. Running total of shipment amount per tenant.

Rules:

```text
ROW_NUMBER  -> unique sequence, even when values tie
RANK        -> ties share rank and later ranks have gaps: 1, 1, 3
DENSE_RANK  -> ties share rank with no gaps: 1, 1, 2
LAG         -> previous row value
LEAD        -> next row value
```

Core query:

```sql
WITH RankedSalaries AS
(
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS SalaryRank
    FROM Employees
)
SELECT Salary
FROM RankedSalaries
WHERE SalaryRank = 8;
```

- [ ] **Done when:** You can explain why window functions do not collapse rows like `GROUP BY`.

---

# Block 3 - CTEs, stored objects, and pagination (60 min)

## CTE

```sql
WITH DriverShipmentCounts AS
(
    SELECT DriverId, COUNT(*) AS ShipmentCount
    FROM Shipments
    GROUP BY DriverId
)
SELECT *
FROM DriverShipmentCounts
WHERE ShipmentCount > 5;
```

```text
CTE = named temporary query expression
Scope = only the next single SQL statement
Use = readability, multi-step query logic, recursion
Not = a permanently stored table or automatic performance improvement
```

## Stored procedure versus function versus view

```text
Stored procedure -> data operation, parameters, transaction, result sets
Function         -> reusable calculation/table expression; returns value
View             -> stored reusable SELECT query
```

## Keyset pagination

```sql
SELECT TOP (50) *
FROM Shipments
WHERE TenantId = @TenantId
  AND (CreatedAt < @LastCreatedAt
       OR (CreatedAt = @LastCreatedAt AND ShipmentId < @LastShipmentId))
ORDER BY CreatedAt DESC, ShipmentId DESC;
```

Say aloud:

> “Offset pagination can skip or duplicate records when new rows arrive. Keyset pagination uses the last seen stable sort key, so it is more reliable for large changing data.”

- [ ] **Done when:** You can explain CTE scope and write keyset pagination with a unique tie-breaker.

---

# Block 4 - indexes and query optimization (90 min)

## Index creation

```sql
-- Usually the Primary Key already has the clustered index.
CREATE CLUSTERED INDEX CX_Shipments_Id
ON Shipments(ShipmentId);

CREATE NONCLUSTERED INDEX IX_Shipments_Tenant_Status_CreatedAt
ON Shipments(TenantId, Status, CreatedAt DESC);
```

```text
Clustered index
-> leaf level is the table data; one per table

Non-clustered index
-> separate lookup structure; many per table

Trade-off
-> faster reads, but extra storage and slower inserts/updates/deletes
```

## Optimize an eight-second query

```text
1. Capture the actual execution plan.
2. Check duration, rows read, scans, joins, sorts, key lookups.
3. Inspect generated EF SQL and parameter values.
4. Return only needed columns; avoid SELECT *.
5. Make predicates SARGable.
6. Add/reorder a targeted index for real filter/join/order columns.
7. Remove N+1, paginate, and batch where required.
8. Re-run with comparable data and compare before/after metrics.
```

Bad for an index on `CreatedAt`:

```sql
WHERE YEAR(CreatedAt) = 2026
```

Better:

```sql
WHERE CreatedAt >= '2026-01-01'
  AND CreatedAt < '2027-01-01'
```

Composite-index rule:

```text
Equality filters first -> range/sort columns later

WHERE TenantId = @TenantId
  AND Status = @Status
  AND CreatedAt >= @Date

Index: (TenantId, Status, CreatedAt)
```

- [ ] **Done when:** You can say “I inspect the actual execution plan before adding an index” and name the write-cost trade-off.

---

# Block 5 - 45-minute no-notes SQL mock

Set a timer and write all of these:

1. `INNER JOIN` and `LEFT JOIN` query.
2. `GROUP BY` plus `HAVING`.
3. `CASE` status bucket.
4. Duplicate detection and safe deletion plan.
5. Latest attachment per type using `ROW_NUMBER()`.
6. Eighth highest salary using `DENSE_RANK()`.
7. Previous score using `LAG()`.
8. CTE with aggregate result.
9. Keyset pagination.
10. Index for a tenant/status/date query.

Score each answer:

```text
2 = wrote it correctly from blank
1 = had the right approach but needed syntax correction
0 = could not start
```

Anything scored `0` is the only material to revise before sleep.

---

# Final 30-minute backend revision

Only after SQL mock, revise:

```text
ROD architecture
JWT + tenant context
EF Core: AsNoTracking, Include, N+1, AsSplitQuery
global exception middleware
one document-expiry-reminder STAR story
```

## Interview answer for SQL confidence

> “I start from the data shape and required result, write the query clearly, then consider volume and indexes. For a slow query, I inspect the actual execution plan and generated SQL, reduce rows and columns early, keep predicates index-friendly, and add only targeted indexes after measuring. I also consider application issues such as N+1 queries and excessive EF tracking, not only SQL syntax.”
