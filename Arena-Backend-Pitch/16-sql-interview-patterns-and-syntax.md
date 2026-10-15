# SQL Interview Patterns and SQL Server Syntax

> Consolidated interview notes: query patterns, explanations, and SQL Server syntax.

---

Absolutely. For tomorrow, I’d turn those 9 patterns into **interview-ready notes** rather than textbook notes. The goal is: **recognize the pattern → write the query → explain it confidently → handle the follow-up.**

# SQL Interview Notes — 9 High-Value Patterns

---

## 1. JOINs

### What is a JOIN?

A `JOIN` combines rows from two or more tables based on a related column.

Example:

**Employees**

| Id | Name | DepartmentId |
| -- | ---- | -----------: |
| 1  | Raj  |           10 |
| 2  | Amit |           20 |
| 3  | John |           10 |

**Departments**

| Id | Name |
| -- | ---- |
| 10 | IT   |
| 20 | HR   |

### INNER JOIN

Returns only matching records from both tables.

```sql
SELECT
    e.Name,
    d.Name AS DepartmentName
FROM Employees e
INNER JOIN Departments d
    ON e.DepartmentId = d.Id;
```

Result:

| Name | DepartmentName |
| ---- | -------------- |
| Raj  | IT             |
| Amit | HR             |
| John | IT             |

### LEFT JOIN

Returns **all rows from the left table**, even if there is no match.

```sql
SELECT
    e.Name,
    d.Name AS DepartmentName
FROM Employees e
LEFT JOIN Departments d
    ON e.DepartmentId = d.Id;
```

If an employee has no department:

```text
Employee → Department = NULL
```

### Interview question

**INNER JOIN vs LEFT JOIN?**

> INNER JOIN returns only matching records from both tables. LEFT JOIN returns every record from the left table and matching records from the right table; if there is no match, the right-side columns become NULL.

### Very important trick

Find employees without a department:

```sql
SELECT e.*
FROM Employees e
LEFT JOIN Departments d
    ON e.DepartmentId = d.Id
WHERE d.Id IS NULL;
```

This pattern is extremely common.

### Learn from this

**JOIN types + NULL handling + unmatched records**

---

# 2. GROUP BY + HAVING

This is one of the most important SQL concepts.

Suppose:

**Employees**

| Name | Department | Salary |
| ---- | ---------- | -----: |
| Raj  | IT         |  80000 |
| Amit | IT         |  70000 |
| John | HR         |  60000 |
| Sam  | HR         |  65000 |
| Bob  | Sales      |  50000 |

### GROUP BY

Used to group rows so aggregate functions can operate on each group.

```sql
SELECT
    Department,
    COUNT(*) AS EmployeeCount
FROM Employees
GROUP BY Department;
```

Result:

```text
IT       2
HR       2
Sales    1
```

---

### HAVING

`HAVING` filters the **groups**.

```sql
SELECT
    Department,
    COUNT(*) AS EmployeeCount
FROM Employees
GROUP BY Department
HAVING COUNT(*) > 1;
```

Result:

```text
IT
HR
```

Sales is removed because it has only one employee.

---

### WHERE vs HAVING

This is a **must-know interview question**.

### WHERE

Filters individual rows **before grouping**.

```sql
SELECT Department, COUNT(*)
FROM Employees
WHERE Salary > 60000
GROUP BY Department;
```

### HAVING

Filters groups **after grouping**.

```sql
SELECT Department, COUNT(*)
FROM Employees
GROUP BY Department
HAVING COUNT(*) > 1;
```

### Interview answer

> `WHERE` filters rows before aggregation, whereas `HAVING` filters groups after aggregation.

### Learn from this

**Aggregate functions:**

```sql
COUNT()
SUM()
AVG()
MIN()
MAX()
```

And understand:

```text
WHERE → GROUP BY → HAVING
```

---

# 3. Second Highest Salary

Classic interview question.

Suppose:

```text
100000
90000
80000
70000
```

We want:

```text
90000
```

### Approach 1 — MAX + subquery

```sql
SELECT MAX(Salary) AS SecondHighestSalary
FROM Employees
WHERE Salary < (
    SELECT MAX(Salary)
    FROM Employees
);
```

### How it works

First:

```sql
SELECT MAX(Salary)
FROM Employees;
```

returns:

```text
100000
```

Then:

```sql
WHERE Salary < 100000
```

removes the highest salary.

Then `MAX()` gives:

```text
90000
```

---

## Better approach: DENSE_RANK

```sql
SELECT Salary
FROM
(
    SELECT
        Salary,
        DENSE_RANK() OVER (ORDER BY Salary DESC) AS RankNo
    FROM Employees
) x
WHERE RankNo = 2;
```

Result:

```text
90000
```

### Why DENSE_RANK?

Suppose salaries are:

```text
100000
90000
90000
80000
```

`DENSE_RANK()`:

```text
100000 → 1
90000  → 2
90000  → 2
80000  → 3
```

Therefore:

```sql
WHERE RankNo = 2
```

returns both employees earning 90000.

### ROW_NUMBER vs RANK vs DENSE_RANK

Suppose:

```text
100
90
90
80
```

#### ROW_NUMBER

```text
100 → 1
90  → 2
90  → 3
80  → 4
```

Every row gets a unique number.

#### RANK

```text
100 → 1
90  → 2
90  → 2
80  → 4
```

There is a gap after the tie.

#### DENSE_RANK

```text
100 → 1
90  → 2
90  → 2
80  → 3
```

No gap.

### Interview line

> `ROW_NUMBER` gives every row a unique sequence. `RANK` gives the same rank to ties but skips subsequent ranks. `DENSE_RANK` also gives the same rank to ties but doesn't skip ranks.

### Learn from this

**Window functions + ranking**

This is a major topic.

---

# 4. Top N Per Group

This is where `PARTITION BY` becomes extremely important.

Question:

> Find the top 3 highest-paid employees from every department.

You **cannot simply use `TOP 3`**, because that gives only 3 employees overall.

Use:

```sql
WITH RankedEmployees AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY DepartmentId
            ORDER BY Salary DESC
        ) AS rn
    FROM Employees
)
SELECT *
FROM RankedEmployees
WHERE rn <= 3;
```

### Understand this part

```sql
PARTITION BY DepartmentId
```

means:

> "Create a separate ranking for every department."

For example:

```text
IT
  Raj     100000 → 1
  Amit     90000 → 2
  John     80000 → 3

HR
  Sam      95000 → 1
  Bob      85000 → 2
  Mike     75000 → 3
```

### Interview question

**What does PARTITION BY do?**

> `PARTITION BY` divides the result set into logical groups for a window function, while still keeping the individual rows.

### GROUP BY vs PARTITION BY

This is important.

`GROUP BY`:

```sql
SELECT DepartmentId, MAX(Salary)
FROM Employees
GROUP BY DepartmentId;
```

reduces multiple rows into one row per department.

`PARTITION BY`:

```sql
MAX(Salary) OVER (PARTITION BY DepartmentId)
```

keeps the individual employee rows.

### Learn from this

**Window functions + PARTITION BY + Top-N-per-group**

---

# 5. Find Duplicates

Suppose:

```text
Email
----------------
raj@gmail.com
amit@gmail.com
raj@gmail.com
john@gmail.com
amit@gmail.com
```

Question:

> Find duplicate emails.

```sql
SELECT
    Email,
    COUNT(*) AS Count
FROM Users
GROUP BY Email
HAVING COUNT(*) > 1;
```

Result:

```text
raj@gmail.com   2
amit@gmail.com  2
```

### Why?

`GROUP BY Email` creates:

```text
raj@gmail.com → 2
amit@gmail.com → 2
john@gmail.com → 1
```

Then:

```sql
HAVING COUNT(*) > 1
```

keeps only duplicates.

### Interview follow-up

**How would you delete duplicates while keeping one record?**

One SQL Server approach:

```sql
WITH Duplicates AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY Email
            ORDER BY Id
        ) AS rn
    FROM Users
)
DELETE FROM Duplicates
WHERE rn > 1;
```

This is a very useful pattern.

### Learn from this

**GROUP BY + HAVING + ROW_NUMBER**

---

# 6. Employee Earns More Than Manager

This introduces **SELF JOIN**.

Suppose:

| Id | Name | ManagerId | Salary |
| -: | ---- | --------: | -----: |
|  1 | Raj  |      NULL | 100000 |
|  2 | Amit |         1 | 120000 |
|  3 | John |         1 |  90000 |

Question:

> Find employees whose salary is greater than their manager's salary.

The Employees table needs to be joined with itself.

```sql
SELECT
    e.Name AS Employee,
    e.Salary AS EmployeeSalary,
    m.Name AS Manager,
    m.Salary AS ManagerSalary
FROM Employees e
INNER JOIN Employees m
    ON e.ManagerId = m.Id
WHERE e.Salary > m.Salary;
```

Result:

```text
Amit
```

### What's happening?

We treat the same table as two different logical tables:

```text
Employees e → employee
Employees m → manager
```

Then:

```sql
e.ManagerId = m.Id
```

connects them.

### Interview answer

> A self join is when a table is joined with itself. It's useful when rows in the same table have relationships with other rows in that table, such as employees and managers.

### Learn from this

**Self Join + hierarchical relationships**

---

# 7. Customers Who Never Placed an Order

This is a very important SQL interview pattern.

Tables:

```text
Customers
Orders
```

Question:

> Find customers who have never placed an order.

## Method 1 — LEFT JOIN

```sql
SELECT c.*
FROM Customers c
LEFT JOIN Orders o
    ON c.Id = o.CustomerId
WHERE o.CustomerId IS NULL;
```

### Logic

LEFT JOIN gives:

```text
Customer → Order
Raj      → 101
Amit     → NULL
John     → 102
```

Then:

```sql
WHERE o.CustomerId IS NULL
```

returns Amit.

---

# Method 2 — NOT EXISTS

```sql
SELECT c.*
FROM Customers c
WHERE NOT EXISTS
(
    SELECT 1
    FROM Orders o
    WHERE o.CustomerId = c.Id
);
```

Meaning:

> Return the customer if there does NOT exist an order for that customer.

### EXISTS

```sql
WHERE EXISTS
(
    SELECT 1
    FROM Orders o
    WHERE o.CustomerId = c.Id
)
```

means:

> Keep the customer if at least one matching order exists.

### Why `SELECT 1`?

Inside `EXISTS`, SQL only cares whether a row exists.

So:

```sql
SELECT 1
```

is conventional.

You could technically use:

```sql
SELECT *
```

but the value isn't what matters.

### Interview question

**LEFT JOIN vs NOT EXISTS?**

Good answer:

> Both can be used to find unmatched records. `LEFT JOIN ... IS NULL` expresses the relationship through a join, while `NOT EXISTS` explicitly checks for the absence of a matching row. For existence checks, I generally find `EXISTS` or `NOT EXISTS` clearer.

Don't claim one is **always faster**. Performance depends on the query, indexes, data distribution, and execution plan.

### Learn from this

**EXISTS / NOT EXISTS + anti-join pattern**

---

# 8. Consecutive Records — LAG / LEAD

This is a slightly more advanced concept and worth learning.

Suppose:

| Date  | Temperature |
| ----- | ----------: |
| Jan 1 |          20 |
| Jan 2 |          25 |
| Jan 3 |          30 |
| Jan 4 |          22 |

Question:

> Find days where temperature was higher than the previous day.

Use `LAG()`.

```sql
SELECT
    Date,
    Temperature,
    LAG(Temperature) OVER (ORDER BY Date) AS PreviousTemperature
FROM Weather;
```

Result:

```text
Jan 1 → 20 → NULL
Jan 2 → 25 → 20
Jan 3 → 30 → 25
Jan 4 → 22 → 30
```

Then:

```sql
WITH WeatherData AS
(
    SELECT
        Date,
        Temperature,
        LAG(Temperature) OVER (ORDER BY Date) AS PreviousTemperature
    FROM Weather
)
SELECT *
FROM WeatherData
WHERE Temperature > PreviousTemperature;
```

Returns:

```text
Jan 2
Jan 3
```

---

## LEAD

`LEAD()` looks forward.

```sql
LEAD(Temperature) OVER (ORDER BY Date)
```

Conceptually:

```text
LAG  → previous row
LEAD → next row
```

### Interview answer

> `LAG` allows me to access a value from a previous row without performing a self join, while `LEAD` allows me to access a value from a following row.

### Learn from this

**Window functions + previous/next row analysis**

---

# 9. CTE — Common Table Expression

CTE stands for:

**Common Table Expression**

It allows you to define a temporary named result set that can be referenced by the following query.

Example:

```sql
WITH HighSalaryEmployees AS
(
    SELECT *
    FROM Employees
    WHERE Salary > 80000
)
SELECT *
FROM HighSalaryEmployees;
```

Think of it as:

```text
WITH
    ↓
Build temporary logical result
    ↓
Use it in main query
```

---

## Why CTE?

It makes complicated queries easier to read.

Example:

```sql
WITH RankedEmployees AS
(
    SELECT
        *,
        DENSE_RANK() OVER
        (
            ORDER BY Salary DESC
        ) AS SalaryRank
    FROM Employees
)
SELECT *
FROM RankedEmployees
WHERE SalaryRank = 2;
```

Without CTE, you'd need a derived table:

```sql
SELECT *
FROM
(
    SELECT
        *,
        DENSE_RANK() OVER
        (
            ORDER BY Salary DESC
        ) AS SalaryRank
    FROM Employees
) x
WHERE SalaryRank = 2;
```

Both approaches are valid.

---

# CTE vs Temporary Table

Very likely follow-up for a .NET/backend interview.

### CTE

```sql
WITH Data AS (...)
SELECT ...
```

Generally useful for:

* readability
* complex queries
* recursive queries
* one logical query operation

### Temp table

```sql
CREATE TABLE #Data
(
    Id INT
);
```

Useful when:

* you need to store intermediate results
* you need to reference them multiple times
* you want to index the temporary data
* the intermediate dataset is useful across multiple statements

### Interview answer

> A CTE is mainly a query-scoped logical result set that improves readability and can support recursion. A temporary table physically stores intermediate data in tempdb and can be reused across multiple statements and indexed.

Don't say **"CTE is always faster"** or **"temp table is always faster."** That's not correct.

### Learn from this

**CTE + derived tables + temporary tables + recursive CTE**

---

# Your 9-Topic Mental Map

This is what I want you to remember tonight:

```text
1. JOIN
   ↓
Combine tables

2. GROUP BY
   ↓
Create groups

3. HAVING
   ↓
Filter groups

4. ROW_NUMBER / RANK / DENSE_RANK
   ↓
Rank rows

5. PARTITION BY
   ↓
Rank/calculation separately within groups

6. SELF JOIN
   ↓
Compare rows within same table

7. EXISTS / NOT EXISTS
   ↓
Check whether related rows exist

8. LAG / LEAD
   ↓
Look at previous / next row

9. CTE
   ↓
Break complex query into readable steps
```

## The 5 queries I'd memorize as patterns

If you have limited time tonight, make sure you can write these **without looking**:

### Second highest

```sql
SELECT Salary
FROM
(
    SELECT
        Salary,
        DENSE_RANK() OVER (ORDER BY Salary DESC) AS rn
    FROM Employees
) x
WHERE rn = 2;
```

### Top 3 per department

```sql
WITH Ranked AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY DepartmentId
            ORDER BY Salary DESC
        ) AS rn
    FROM Employees
)
SELECT *
FROM Ranked
WHERE rn <= 3;
```

### Duplicate records

```sql
SELECT Email, COUNT(*)
FROM Users
GROUP BY Email
HAVING COUNT(*) > 1;
```

### Employees earning more than manager

```sql
SELECT e.Name
FROM Employees e
JOIN Employees m
    ON e.ManagerId = m.Id
WHERE e.Salary > m.Salary;
```

### Customers with no orders

```sql
SELECT c.*
FROM Customers c
WHERE NOT EXISTS
(
    SELECT 1
    FROM Orders o
    WHERE o.CustomerId = c.Id
);
```

And one final rule for tomorrow:

> **Don't just give the query. Explain the pattern.**

If they ask *"Why did you use `DENSE_RANK()`?"*, don't say *"because that's the solution."*

Say:

> "I'm using `DENSE_RANK` because I want equal salaries to receive the same rank, and I don't want gaps in the ranking. That lets me correctly identify the second distinct-highest salary."

That kind of explanation is what separates **knowing SQL syntax** from demonstrating that you understand SQL.

---

Absolutely. For the interview, keep these as **syntax patterns** in your head. Assuming **SQL Server / T-SQL**.

# SQL Server — Simplest Syntax Mind Map

```text
                         SQL SERVER
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
   TABLE OPS              QUERIES              DATABASE OBJECTS
       │                      │                      │
       ├─ CREATE              ├─ DELETE             ├─ PROCEDURE
       ├─ UPDATE              ├─ OFFSET             ├─ VIEW
       └─ FOREIGN KEY         └─ FETCH              └─ FUNCTION
                              │
                         INDEXES
                              │
                    ┌─────────┴─────────┐
                    │                   │
                CLUSTERED          NON-CLUSTERED
```

---

# 1. CREATE TABLE

### Simplest

```sql
CREATE TABLE Employees
(
    Id INT,
    Name VARCHAR(100),
    Salary DECIMAL(10,2)
);
```

### With Primary Key

```sql
CREATE TABLE Employees
(
    Id INT PRIMARY KEY,
    Name VARCHAR(100),
    Salary DECIMAL(10,2)
);
```

### Mind map

```text
CREATE TABLE
     ↓
TableName
     ↓
(columns + datatypes)
```

---

# 2. FOREIGN KEY

Suppose:

```text
Departments
    Id

Employees
    DepartmentId
```

### While creating table

```sql
CREATE TABLE Departments
(
    Id INT PRIMARY KEY,
    Name VARCHAR(100)
);

CREATE TABLE Employees
(
    Id INT PRIMARY KEY,
    Name VARCHAR(100),
    DepartmentId INT,

    FOREIGN KEY (DepartmentId)
        REFERENCES Departments(Id)
);
```

### Add later

```sql
ALTER TABLE Employees
ADD CONSTRAINT FK_Employee_Department
FOREIGN KEY (DepartmentId)
REFERENCES Departments(Id);
```

### Mind map

```text
FOREIGN KEY
     ↓
Child Table
     ↓
ChildColumn
     ↓
REFERENCES
     ↓
ParentTable(PrimaryKey)
```

### Interview line

> A foreign key maintains referential integrity between a child table and a parent table.

---

# 3. DELETE FROM TABLE

### Delete specific rows

```sql
DELETE FROM Employees
WHERE Id = 10;
```

### Delete all rows

```sql
DELETE FROM Employees;
```

### Very important

Never forget:

```sql
DELETE FROM Employees
WHERE Id = 10;
```

vs.

```sql
DELETE FROM Employees;
```

The second one deletes **all rows**.

### DELETE vs TRUNCATE

```text
DELETE
  ↓
Can use WHERE
  ↓
Row-by-row operation
  ↓
Can be rolled back inside transaction

TRUNCATE
  ↓
Removes all rows
  ↓
Cannot use WHERE
  ↓
Generally faster
```

---

# 4. UPDATE TABLE

Technically, you update **rows**, not the table structure.

```sql
UPDATE Employees
SET Salary = 80000
WHERE Id = 10;
```

### Multiple columns

```sql
UPDATE Employees
SET
    Salary = 80000,
    Name = 'Raj'
WHERE Id = 10;
```

### ⚠️ Interview trap

```sql
UPDATE Employees
SET Salary = 80000;
```

This updates **every employee**.

---

# 5. STORED PROCEDURE

### Simplest

```sql
CREATE PROCEDURE GetEmployees
AS
BEGIN
    SELECT *
    FROM Employees;
END;
```

Execute:

```sql
EXEC GetEmployees;
```

---

### With parameter

```sql
CREATE PROCEDURE GetEmployee
    @Id INT
AS
BEGIN
    SELECT *
    FROM Employees
    WHERE Id = @Id;
END;
```

Execute:

```sql
EXEC GetEmployee @Id = 10;
```

### Mind map

```text
CREATE PROCEDURE
       ↓
ProcedureName
       ↓
Parameters
       ↓
AS
       ↓
BEGIN
       ↓
   SQL QUERY
       ↓
END
```

---

# 6. VIEW

A view is basically a **saved SELECT query**.

### Simplest

```sql
CREATE VIEW EmployeeView
AS
SELECT
    Id,
    Name,
    Salary
FROM Employees;
```

Use it:

```sql
SELECT *
FROM EmployeeView;
```

### With JOIN

```sql
CREATE VIEW EmployeeDepartmentView
AS
SELECT
    e.Name AS EmployeeName,
    d.Name AS DepartmentName
FROM Employees e
JOIN Departments d
    ON e.DepartmentId = d.Id;
```

### Mind map

```text
CREATE VIEW
     ↓
ViewName
     ↓
AS
     ↓
SELECT QUERY
```

### Interview line

> A view is a virtual table based on a SELECT query. It generally stores the query definition rather than a separate copy of the underlying data.

---

# 7. CLUSTERED INDEX

### Simplest syntax

```sql
CREATE CLUSTERED INDEX IX_Employees_Id
ON Employees(Id);
```

Think:

```text
CLUSTERED
    ↓
Physical/logical ordering of table's data pages
    ↓
Usually one per table
```

### Important

A table can have **only one clustered index** because the data can only have one clustered ordering.

---

# 8. NON-CLUSTERED INDEX

```sql
CREATE NONCLUSTERED INDEX IX_Employees_Name
ON Employees(Name);
```

You can have **multiple** non-clustered indexes.

```sql
CREATE NONCLUSTERED INDEX IX_Employees_Name_Salary
ON Employees(Name, Salary);
```

### Mind map

```text
INDEX
 │
 ├── CLUSTERED
 │      ↓
 │   1 per table
 │
 └── NON-CLUSTERED
        ↓
     Multiple allowed
```

### Interview line

> A clustered index determines the physical organization of the table's data, while a non-clustered index is a separate structure that contains indexed keys and pointers to the underlying rows.

---

# 9. LIMIT / OFFSET

Here's an important **SQL Server** point:

SQL Server doesn't traditionally use:

```sql
LIMIT 10
```

Instead, use:

```sql
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
```

### Example

```sql
SELECT *
FROM Employees
ORDER BY Id
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
```

This means:

```text
OFFSET 0
   ↓
Skip 0 rows

FETCH NEXT 10
   ↓
Return next 10 rows
```

### Page 2

```sql
SELECT *
FROM Employees
ORDER BY Id
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;
```

### Page 3

```sql
SELECT *
FROM Employees
ORDER BY Id
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;
```

### Formula

```text
OFFSET = (PageNumber - 1) × PageSize
```

Example:

```text
Page = 3
Size = 10

OFFSET = (3 - 1) × 10
       = 20
```

### Interview trap

`OFFSET/FETCH` requires an `ORDER BY`.

---

# 10. FUNCTION

There are two major types you should know for interviews:

```text
FUNCTION
   │
   ├── Scalar Function
   │       ↓
   │    Returns ONE value
   │
   └── Table-Valued Function
           ↓
        Returns TABLE
```

---

## Scalar Function

Example: Add two numbers.

```sql
CREATE FUNCTION AddNumbers
(
    @A INT,
    @B INT
)
RETURNS INT
AS
BEGIN
    RETURN @A + @B;
END;
```

Use:

```sql
SELECT dbo.AddNumbers(10, 20);
```

Result:

```text
30
```

### Mind map

```text
CREATE FUNCTION
      ↓
Parameters
      ↓
RETURNS datatype
      ↓
AS
      ↓
BEGIN
      ↓
RETURN value
      ↓
END
```

---

# 11. Table-Valued Function

Returns a table.

```sql
CREATE FUNCTION GetEmployeesByDepartment
(
    @DepartmentId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Employees
    WHERE DepartmentId = @DepartmentId
);
```

Use:

```sql
SELECT *
FROM dbo.GetEmployeesByDepartment(10);
```

Think:

```text
Scalar Function
      ↓
ONE VALUE

Table-Valued Function
      ↓
TABLE
```

---

# FINAL 30-SECOND MEMORY SHEET

If you're walking into the interview, memorize this:

```text
CREATE TABLE
────────────────────────
CREATE TABLE Employees
(
    Id INT PRIMARY KEY,
    Name VARCHAR(100)
);


FOREIGN KEY
────────────────────────
FOREIGN KEY (DepartmentId)
REFERENCES Departments(Id)


DELETE
────────────────────────
DELETE FROM Employees
WHERE Id = 10;


UPDATE
────────────────────────
UPDATE Employees
SET Salary = 80000
WHERE Id = 10;


PROCEDURE
────────────────────────
CREATE PROCEDURE GetEmployees
AS
BEGIN
    SELECT * FROM Employees;
END;


VIEW
────────────────────────
CREATE VIEW EmployeeView
AS
SELECT * FROM Employees;


CLUSTERED INDEX
────────────────────────
CREATE CLUSTERED INDEX IX_Name
ON Employees(Name);


NON-CLUSTERED INDEX
────────────────────────
CREATE NONCLUSTERED INDEX IX_Name
ON Employees(Name);


PAGINATION
────────────────────────
SELECT *
FROM Employees
ORDER BY Id
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;


SCALAR FUNCTION
────────────────────────
CREATE FUNCTION AddNumbers
(
    @A INT,
    @B INT
)
RETURNS INT
AS
BEGIN
    RETURN @A + @B;
END;


TABLE FUNCTION
────────────────────────
CREATE FUNCTION GetEmployees(@Id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Employees
    WHERE DepartmentId = @Id
);
```

## The interview traps I'd specifically prepare

```text
1. DELETE vs TRUNCATE vs DROP

2. WHERE vs HAVING

3. INNER JOIN vs LEFT JOIN

4. CLUSTERED vs NON-CLUSTERED INDEX

5. PRIMARY KEY vs FOREIGN KEY

6. VIEW vs STORED PROCEDURE

7. STORED PROCEDURE vs FUNCTION

8. ROW_NUMBER vs RANK vs DENSE_RANK

9. CTE vs TEMP TABLE

10. OFFSET/FETCH pagination

11. Why indexes improve SELECT but can hurt INSERT/UPDATE/DELETE

12. Can a table have multiple clustered indexes?
    → NO

13. Can a table have multiple non-clustered indexes?
    → YES

14. Can a foreign key reference a non-primary unique key?
    → YES, provided the referenced column(s) have a suitable UNIQUE constraint/index.

15. Does a VIEW store the actual data?
    → A normal view stores the query definition, not a separate copy of the underlying data.
```

For your **Pratham .NET round**, I would put **indexes, joins, stored procedures, functions, transactions, and EF Core ↔ SQL interaction** immediately after these syntax patterns. Those are where a .NET interviewer can quickly move from "write this query" into "do you actually understand SQL Server?"

