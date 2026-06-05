# SQL Execution + Syntax Cheat Sheet

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
