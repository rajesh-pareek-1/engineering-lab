# Fundamentals

- Logical order: FROM -> JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT.
- SQL is declarative: describe the final dataset, not loops.
- `WHERE` filters rows before grouping. `HAVING` filters groups after aggregation.
- `NULL` is unknown. Use `IS NULL` / `IS NOT NULL`, never `= NULL`.
- `COUNT(*)` counts rows. `COUNT(column)` ignores nulls.
- `EXISTS` checks presence. `JOIN` combines rows and can duplicate parents.
- Indexes speed reads but cost writes/storage.

# Frequently Asked Questions

## Execution order

FROM/JOIN builds row source, WHERE filters rows, GROUP BY forms buckets, HAVING filters buckets, SELECT projects columns, DISTINCT removes duplicates, ORDER BY sorts, LIMIT/TOP returns subset.

## WHERE vs HAVING

Use WHERE for row-level filters like active employees. Use HAVING when the condition uses aggregates like `COUNT(*) > 5`.

## INNER vs LEFT JOIN

- INNER JOIN: matching rows only.
- LEFT JOIN: all left rows, matching right rows, nulls when missing.
- Trap: filtering right table in WHERE can turn LEFT JOIN behavior into INNER JOIN behavior.

## RANK vs DENSE_RANK vs ROW_NUMBER

- ROW_NUMBER: unique sequence.
- RANK: ties share rank and leave gaps.
- DENSE_RANK: ties share rank and no gaps.
- Use DENSE_RANK for nth distinct salary.

## CTE vs temp table

- CTE: readable single-query expression.
- Temp table: materialized and reusable across multiple steps.

## Transaction isolation

- Read uncommitted: dirty reads possible.
- Read committed: avoids dirty reads.
- Repeatable read: same row stays stable.
- Serializable: strongest, prevents phantom ranges, more blocking.
- Snapshot: version-based consistency, less blocking, version-store cost.

# Production Scenarios

## Slow listing API

Check filters, projection, pagination, indexes, joins, N+1 from ORM, generated SQL, execution plan, row counts, and sort strategy.

## Duplicate parent rows

A JOIN to child rows can multiply parents. Use `EXISTS` for presence checks or aggregate/group when needed.

## All child rows invalid

Group by parent and count valid rows. If valid count is zero, all rows are invalid.

## Reporting query

Use CTEs for readability, window functions for ranks/totals, indexes on filter/join columns, and verify plan before guessing.

## Concurrency update conflict

Use transactions, row version/optimistic concurrency, correct isolation level, and retry strategy where safe.

# Performance Concepts

- Index columns used in WHERE, JOIN, ORDER BY.
- Composite index order follows query pattern; leading column matters.
- Avoid functions on indexed columns in predicates when possible.
- Select only needed columns.
- Filter before grouping when possible.
- Avoid correlated subquery if it runs per row and can be rewritten.
- Window functions are often cleaner than self joins for ranking.
- Execution plan beats intuition.
- Over-indexing slows writes and increases storage.
- Pagination needs deterministic ORDER BY.

# Edge Cases

- `NULL != NULL`; even null comparisons are unknown.
- `NOT IN` with nulls can return surprising empty results; prefer `NOT EXISTS`.
- `LEFT JOIN` + `WHERE right_table.column = ...` removes unmatched rows.
- SELECT alias usually cannot be used in WHERE.
- Every non-aggregated selected column must be in GROUP BY.
- `DISTINCT city, country` deduplicates the pair, not only city.
- `BETWEEN` is inclusive.
- Ties matter in salary/rank questions.
- Missing ORDER BY means no guaranteed row order.

# Tricky Questions

## Third highest distinct salary

Use DENSE_RANK and filter rank 3. If no rank 3 exists, return no row/null depending on platform requirement.

## Second highest salary per department

Partition by department and rank salary descending.

## EXISTS vs JOIN

Use EXISTS when the output is only parent rows and child presence matters. Use JOIN when child columns are needed.

## Index always improves?

No. It improves some reads but slows writes, consumes storage, and may not be used if selectivity/query shape is poor.

## CTE improves performance?

Not automatically. It mainly improves readability unless optimizer/materialization behavior changes.

# Syntax Refreshers

```sql
SELECT DepartmentId, COUNT(*) AS Total
FROM Employees
WHERE IsActive = 1
GROUP BY DepartmentId
HAVING COUNT(*) > 5
ORDER BY Total DESC;
```

```sql
SELECT *
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerId = c.Id
);
```

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

```sql
SELECT ProductId
FROM Products
GROUP BY ProductId
HAVING SUM(CASE
    WHEN @Today BETWEEN StartDate AND EndDate THEN 1
    ELSE 0
END) = 0;
```

```sql
SELECT Email
FROM Person
GROUP BY Email
HAVING COUNT(*) > 1;
```

# Real Project Examples

- Shipment/list APIs: filter by tenant/status/date, project DTOs, paginate, index common filters.
- Attachment expiry check: use EXISTS or EF `.Any()` instead of joining and duplicating associates.
- Reporting/invoice flows: use background jobs for heavy reporting and inspect SQL plans for slow queries.
- Multi-tenant data: every tenant query must be scoped by resolved tenant database/context, not user-provided route values.

# 30-Minute Rapid Revision

1. Recite SQL execution order.
2. Write WHERE vs HAVING example.
3. Write DENSE_RANK second salary per department.
4. Write EXISTS presence check.
5. Explain LEFT JOIN filter trap.
6. Explain COUNT(*) vs COUNT(column).
7. Explain index benefit/cost.
8. Explain CTE vs temp table.
9. Review transaction isolation names.
10. Say "execution plan before guessing."

# Questions To Ask Interviewer

- What database engine and ORM patterns do you use?
- How do you review slow query plans?
- What are the most common production SQL bottlenecks here?
- How do you manage migrations and rollback?
- Are reports served from OLTP tables, replicas, or a warehouse?
