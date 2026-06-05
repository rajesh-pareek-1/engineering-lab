# SQL Revision

## Execution Order

Logical SQL execution order:

```text
FROM -> JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
```

Memory trick:

```text
F J W G H S O
```

## NULL Handling

Never use `= NULL`.

```sql
SELECT *
FROM Employees
WHERE ManagerId IS NULL;
```

## WHERE vs HAVING

| Clause | Filters |
| --- | --- |
| WHERE | Rows before grouping |
| HAVING | Groups after aggregation |

Example:

```sql
SELECT DepartmentId, COUNT(*) AS EmployeeCount
FROM Employees
WHERE IsActive = 1
GROUP BY DepartmentId
HAVING COUNT(*) > 5;
```

## JOIN Rules

- `INNER JOIN`: only matching rows.
- `LEFT JOIN`: all left rows plus matches.
- `RIGHT JOIN`: all right rows plus matches.
- `CROSS JOIN`: all combinations, no `ON` needed.

```sql
SELECT *
FROM Orders o
LEFT JOIN Customers c ON c.Id = o.CustomerId;
```

## DISTINCT and ORDER BY

```sql
SELECT DISTINCT AuthorId AS Id
FROM Books
ORDER BY Id;
```

`ORDER BY` comes last.

## GROUP BY Mental Model

```text
GROUP BY creates buckets. Aggregates calculate per bucket. HAVING filters buckets.
```

## Indexing

Index benefits:

- Faster reads on WHERE, JOIN, ORDER BY columns.
- Helps lookups and range queries.

Tradeoff:

- Slower inserts/updates/deletes.
- Extra storage.

Composite index:

```text
(AssociateId, ExpiryDate)
```

Order matters. Put high-value filtering/join columns first based on query pattern.

## RANK vs DENSE_RANK

| Function | Behavior with ties |
| --- | --- |
| `RANK()` | Leaves gaps |
| `DENSE_RANK()` | No gaps |

Correct nth salary pattern:

```sql
SELECT Salary
FROM (
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS r
    FROM Employees
) t
WHERE r = 3;
```

## Second Highest Salary Per Department

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

Without ranking functions:

```sql
SELECT *
FROM Employees e
WHERE 1 = (
    SELECT COUNT(DISTINCT e2.Salary)
    FROM Employees e2
    WHERE e2.DepartmentId = e.DepartmentId
      AND e2.Salary > e.Salary
);
```

## Salary Greater Than Department Average

```sql
SELECT *
FROM Employees e
WHERE Salary > (
    SELECT AVG(e2.Salary)
    FROM Employees e2
    WHERE e2.DepartmentId = e.DepartmentId
);
```

## EXISTS vs JOIN

Use `EXISTS` when checking presence:

```sql
SELECT a.Id, a.Name
FROM Associates a
WHERE EXISTS (
    SELECT 1
    FROM Attachments at
    WHERE at.AssociateId = a.Id
      AND at.ExpiryDate BETWEEN GETDATE() AND DATEADD(DAY, 3, GETDATE())
);
```

EF Core equivalent:

```csharp
var result = await _context.Associates
    .Where(a => a.Attachments.Any(at =>
        at.ExpiryDate >= DateTime.Today &&
        at.ExpiryDate <= DateTime.Today.AddDays(3)))
    .Select(a => new { a.Id, a.Name })
    .ToListAsync();
```

## Product IDs Where All Rows Are Invalid

Problem:

```text
For each productId, return it only if today's date is not between startDate and endDate for every row.
```

Preferred solution:

```sql
SELECT ProductId
FROM Products
GROUP BY ProductId
HAVING SUM(CASE
    WHEN '2025-03-24' BETWEEN StartDate AND EndDate THEN 1
    ELSE 0
END) = 0;
```

Why it works:

```text
SUM(valid rows) = 0 means no row is valid, so all rows are invalid.
```

## CTE vs Temp Table

| Topic | CTE | Temp table |
| --- | --- | --- |
| Lifetime | Single query | Session/scope |
| Storage | Logical expression | Materialized temp object |
| Best for | Readable query decomposition | Reuse across multiple steps |

## Stored Procedure vs Trigger

| Topic | Stored procedure | Trigger |
| --- | --- | --- |
| Execution | Called explicitly | Runs automatically on event |
| Use | Business/data operation | Audit, validation, reactive DB logic |
| Risk | Overuse hides logic in DB | Can surprise app behavior |

## Stored Procedure vs Function

- Stored procedure can perform actions and return result sets/output params.
- Function returns a value/table and is usually used inside queries.
- In many SQL systems, functions cannot perform side-effect operations the same way procedures can.

## DBMS vs RDBMS

- DBMS stores data.
- RDBMS stores relational data in tables with keys and relationships.

## Primary Key vs Unique Key

| Topic | Primary key | Unique key |
| --- | --- | --- |
| Nulls | Not allowed | DB-dependent, often allows one/nulls |
| Count | One primary key per table | Multiple unique constraints possible |
| Purpose | Main row identity | Enforce alternate uniqueness |

## Ready-To-Say Lines

- "I would push filtering to SQL instead of looping in C#."
- "I would use EXISTS for presence checks to avoid duplicate rows."
- "I would inspect the execution plan before guessing at performance."
- "Indexes speed up reads but add write overhead."
- "WHERE filters rows, HAVING filters groups."

