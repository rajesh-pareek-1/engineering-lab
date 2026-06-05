# SQL_DEEP

Deep SQL source material. Use after `REVISION/MASTER_SQL.md`.

## SQL Interview Source

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

## SQL LeetCode Patterns

(For LeetCode SQL 50 + Backend Arenas)

---

# 1. REAL SQL EXECUTION ORDER

Very Important:
SQL does NOT execute top-to-bottom.

You write:
SELECT
FROM
JOIN
WHERE
GROUP BY
HAVING
ORDER BY

But SQL internally executes like this:

1. FROM
2. JOIN
3. WHERE
4. GROUP BY
5. HAVING
6. SELECT
7. DISTINCT
8. ORDER BY
9. LIMIT

---

# WHY THIS MATTERS

Example:

SELECT department_id, COUNT( _)
FROM employees
WHERE salary > 5000
GROUP BY department_id
HAVING COUNT(_ ) > 3

Execution:

1. Take employees table
2. Filter rows salary > 5000
3. Group remaining rows by department
4. Keep groups having count > 3
5. Return final columns

---

# BIGGEST SQL CONFUSION

## WHERE vs HAVING

WRONG:

SELECT department_id, COUNT( _)
FROM employees
WHERE COUNT(_ ) > 5
GROUP BY department_id

Why wrong?
Because WHERE runs BEFORE grouping.

CORRECT:

SELECT department_id, COUNT( _)
FROM employees
GROUP BY department_id
HAVING COUNT(_ ) > 5

Rule:

- WHERE → row filtering
- HAVING → group filtering

---

# 2. BASIC SELECT SYNTAX

SELECT column1, column2
FROM table_name
WHERE condition
ORDER BY column1;

Example:

SELECT name, salary
FROM employees
WHERE salary > 5000
ORDER BY salary DESC;

---

# 3. JOINS

## INNER JOIN

SELECT a.name, b.order_id
FROM customers a
INNER JOIN orders b
ON a.id = b.customer_id;

Meaning:
Only matching rows.

---

## LEFT JOIN

SELECT a.name, b.order_id
FROM customers a
LEFT JOIN orders b
ON a.id = b.customer_id;

Meaning:
Keep ALL customers.
If no order exists → NULL.

Important Edge Case:
LEFT JOIN + WHERE on right table can accidentally behave like INNER JOIN.

BAD:

SELECT \*
FROM customers c
LEFT JOIN orders o
ON c.id = o.customer_id
WHERE o.amount > 100

Why bad?
NULL rows removed.

BETTER:

SELECT \*
FROM customers c
LEFT JOIN orders o
ON c.id = o.customer_id
AND o.amount > 100

---

# 4. GROUP BY

SELECT department_id, COUNT(\*) as total
FROM employees
GROUP BY department_id;

Rule:
Every non-aggregated selected column must be in GROUP BY.

WRONG:

SELECT name, COUNT(\*)
FROM employees
GROUP BY department_id

Why wrong?
name is not grouped or aggregated.

---

# 5. AGGREGATE FUNCTIONS

COUNT(\*)
COUNT(column)
SUM(column)
AVG(column)
MIN(column)
MAX(column)

Important:

COUNT(\*) counts NULL rows too.
COUNT(column) ignores NULLs.

Example:

Values:
1
2
NULL

COUNT(\*) = 3
COUNT(value) = 2

---

# 6. DISTINCT

SELECT DISTINCT country
FROM users;

Meaning:
Remove duplicate rows.

Edge Case:
DISTINCT applies to entire selected combination.

SELECT DISTINCT city, country

Duplicates removed based on BOTH columns together.

---

# 7. SUBQUERY

SELECT name
FROM employees
WHERE salary = (
SELECT MAX(salary)
FROM employees
);

Meaning:
Inner query executes first.

---

# 8. CORRELATED SUBQUERY

SELECT e1.name
FROM employees e1
WHERE salary > (
SELECT AVG(salary)
FROM employees e2
WHERE e1.department_id = e2.department_id
);

Meaning:
Inner query runs for EACH outer row.

Slow sometimes.

---

# 9. WINDOW FUNCTIONS

## ROW_NUMBER()

SELECT name,
ROW_NUMBER() OVER(
PARTITION BY department_id
ORDER BY salary DESC
) as rn
FROM employees;

Meaning:
Give unique sequence per department.

---

## RANK()

Ties skip numbers.

100 → rank 1
100 → rank 1
90 → rank 3

---

## DENSE_RANK()

No skipped ranks.

100 → 1
100 → 1
90 → 2

---

# 10. SELF JOIN

SELECT e.name, m.name
FROM employees e
JOIN employees m
ON e.manager_id = m.id;

Meaning:
Table joined with itself.

Used for:

- manager hierarchy
- consecutive rows
- comparisons

---

# 11. CASE WHEN

SELECT name,
CASE
WHEN salary > 10000 THEN 'High'
WHEN salary > 5000 THEN 'Medium'
ELSE 'Low'
END as category
FROM employees;

Meaning:
if-else logic inside SQL.

---

# 12. CTE (VERY IMPORTANT)

WITH temp AS (
SELECT department_id,
COUNT(\*) as total
FROM employees
GROUP BY department_id
)

SELECT \*
FROM temp
WHERE total > 5;

Why useful?
Breaks huge query into readable pieces.

Modern SQL standard.

---

# 13. ORDER BY

SELECT \*
FROM employees
ORDER BY salary DESC, age ASC;

Meaning:

1. salary descending
2. if same salary → age ascending

---

# 14. NULL BEHAVIOR

Important:
NULL is NOT equal to anything.

WRONG:

WHERE salary = NULL

CORRECT:

WHERE salary IS NULL

OR

WHERE salary IS NOT NULL

---

# 15. COMMON LEETCODE PATTERNS

## Pattern A — JOIN + GROUP BY

SELECT c.name,
COUNT(o.id)
FROM customers c
LEFT JOIN orders o
ON c.id = o.customer_id
GROUP BY c.id;

Most common pattern.

---

## Pattern B — Top Salary Per Group

SELECT department_id,
MAX(salary)
FROM employees
GROUP BY department_id;

---

## Pattern C — Ranking

SELECT \*,
DENSE_RANK() OVER(
PARTITION BY department_id
ORDER BY salary DESC
)
FROM employees;

---

## Pattern D — Duplicate Detection

SELECT email
FROM person
GROUP BY email
HAVING COUNT(\*) > 1;

---

# 16. SQL THINKING MODEL

When reading a problem ask:

1. Need another table?
   → JOIN
2. Need summarization?
   → GROUP BY
3. Need filtering before grouping?
   → WHERE
4. Need filtering after grouping?
   → HAVING
5. Need ranking?
   → WINDOW FUNCTION
6. Need comparison inside same table?
   → SELF JOIN
7. Need reusable intermediate result?
   → CTE
8. Need top value?
   → MAX / ORDER BY / RANK

---

# FINAL IMPORTANT THING

SQL is NOT procedural programming.

Do NOT think:
"loop through rows"

Think:
"describe the final dataset I want"

That mindset changes everything.
