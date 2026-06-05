# Mock Interview: SQL Round

## 1. SQL Execution Order

Expected answer:

```text
FROM, JOIN, WHERE, GROUP BY, HAVING, SELECT, ORDER BY.
```

Weak answer:

```text
SELECT runs first.
```

Strong answer:

```text
Logically SQL starts from FROM/JOIN, filters rows with WHERE, groups with GROUP BY, filters groups with HAVING, projects columns in SELECT, and sorts at ORDER BY. This explains why SELECT aliases usually cannot be used in WHERE.
```

## 2. WHERE vs HAVING

Expected answer:

```text
WHERE filters rows before grouping; HAVING filters groups after aggregation.
```

Weak answer:

```text
Both filter data.
```

Strong answer:

```text
Use WHERE for row-level conditions like active employees. Use HAVING when the condition depends on aggregate result, such as departments with COUNT(*) > 5.
```

## 3. Rank vs Dense Rank

Expected answer:

```text
RANK leaves gaps after ties; DENSE_RANK does not.
```

Weak answer:

```text
Both give rank.
```

Strong answer:

```text
If salaries are 100, 100, 90 then RANK gives 1,1,3 while DENSE_RANK gives 1,1,2. For nth distinct salary, DENSE_RANK is often the cleaner choice.
```

## 4. Third Highest Salary

Strong answer:

```sql
SELECT Salary
FROM (
    SELECT Salary,
           DENSE_RANK() OVER (ORDER BY Salary DESC) AS r
    FROM Employees
) t
WHERE r = 3;
```

## 5. Second Highest Salary Per Department

Strong answer:

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

## 6. EXISTS vs JOIN

Expected answer:

```text
EXISTS checks presence; JOIN combines rows and may duplicate parent rows.
```

Weak answer:

```text
JOIN is always better.
```

Strong answer:

```text
For presence checks, EXISTS is usually clearer and avoids duplicates. JOIN is needed when I actually need columns from both tables. I would choose based on result shape and execution plan.
```

## 7. What Is an Index?

Expected answer:

```text
Data structure that speeds lookup/filter/sort at write/storage cost.
```

Weak answer:

```text
Index makes query fast.
```

Strong answer:

```text
An index helps SQL locate rows without scanning the whole table, especially on WHERE, JOIN, and ORDER BY columns. The tradeoff is extra storage and slower writes because indexes must be maintained.
```

## 8. Product IDs Where All Date Ranges Are Invalid

Strong answer:

```sql
SELECT ProductId
FROM Products
GROUP BY ProductId
HAVING SUM(CASE
    WHEN '2025-03-24' BETWEEN StartDate AND EndDate THEN 1
    ELSE 0
END) = 0;
```

Explanation:

```text
The SUM counts valid rows. If valid rows are zero, every row for that product is invalid.
```

