# SQL Revision

Merged from the original SQL revision notes and LeetCode SQL 50 patterns.

## Must-Say Lines

- Logical order: `FROM -> JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT`.
- `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation.
- `NULL` is not equal to anything; use `IS NULL` or `IS NOT NULL`.
- `COUNT(*)` counts rows; `COUNT(column)` ignores NULLs.
- `EXISTS` checks presence; `JOIN` combines rows and can duplicate parent rows.
- Indexes speed reads but add write/storage overhead.
- Think in result sets, not loops.

## Execution And Grouping

Query order explains common mistakes:

- SELECT aliases usually cannot be used in `WHERE`.
- Aggregate filters belong in `HAVING`.
- Non-aggregated selected columns must appear in `GROUP BY`.

Example answer:

```text
SQL is declarative. I describe the final dataset: source rows, joins, row filters, groups, group filters, selected columns, and sort order.
```

## Joins

| Join | Meaning |
| --- | --- |
| INNER JOIN | Matching rows only. |
| LEFT JOIN | All left rows plus matching right rows. |
| RIGHT JOIN | All right rows plus matching left rows. |
| CROSS JOIN | All combinations. |

Edge case:

```sql
-- This can turn a LEFT JOIN into INNER JOIN behavior:
SELECT *
FROM Customers c
LEFT JOIN Orders o ON o.CustomerId = c.Id
WHERE o.Amount > 100;
```

Put right-table filters in the `ON` clause if unmatched left rows must stay.

## Ranking

| Function | Tie behavior |
| --- | --- |
| `ROW_NUMBER()` | Unique sequence, no ties. |
| `RANK()` | Same rank for ties, leaves gaps. |
| `DENSE_RANK()` | Same rank for ties, no gaps. |

Third distinct salary:

```sql
SELECT Salary
FROM (
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS r
    FROM Employees
) t
WHERE r = 3;
```

Second highest salary per department:

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

## Presence And Anti-Patterns

Use `EXISTS` when answer shape is "parent rows where child exists":

```sql
SELECT a.Id, a.Name
FROM Associates a
WHERE EXISTS (
    SELECT 1
    FROM Attachments at
    WHERE at.AssociateId = a.Id
);
```

EF Core equivalent:

```csharp
var rows = await _context.Associates
    .Where(a => a.Attachments.Any())
    .Select(a => new { a.Id, a.Name })
    .ToListAsync();
```

## Common LeetCode Patterns

| Pattern | Shape |
| --- | --- |
| Join + count | `LEFT JOIN -> GROUP BY -> COUNT(child.Id)` |
| Top per group | `MAX()` or window rank partitioned by group |
| Duplicate detection | `GROUP BY column HAVING COUNT(*) > 1` |
| Compare to group average | Correlated subquery or window aggregate |
| Consecutive/comparison | Self join or window functions |

Product IDs where all rows are invalid:

```sql
SELECT ProductId
FROM Products
GROUP BY ProductId
HAVING SUM(CASE
    WHEN '2025-03-24' BETWEEN StartDate AND EndDate THEN 1
    ELSE 0
END) = 0;
```

Reason:

```text
The SUM counts valid rows. Zero valid rows means every row for that product is invalid.
```

## Indexes And Performance

Use indexes for:

- `WHERE` filters.
- `JOIN` keys.
- `ORDER BY`.
- Range queries.

Tradeoffs:

- Slower inserts/updates/deletes.
- Extra storage.
- Composite index order matters.
- Execution plan should confirm assumptions.

## DB Concepts

| Topic | Quick answer |
| --- | --- |
| CTE | Readable single-query expression. |
| Temp table | Materialized temporary object for reuse across steps. |
| Stored procedure | Explicitly called operation. |
| Trigger | Automatically runs on DB event; can surprise app behavior. |
| Function | Returns scalar/table, often used inside queries. |
| Primary key | Main row identity, not null. |
| Unique key | Alternate uniqueness, null behavior DB-dependent. |

Common questions:

- SQL execution order?
- `WHERE` vs `HAVING`?
- `RANK` vs `DENSE_RANK`?
- `EXISTS` vs `JOIN`?
- How do indexes help and hurt?
- How would you optimize a slow query?
