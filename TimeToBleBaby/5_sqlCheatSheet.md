🧠 1. Core Mental Models

```text
JOIN      → combine tables
GROUP BY  → per group calculation
HAVING    → filter groups
SUBQUERY  → compare with derived value
EXISTS    → check presence
```

---

# ⚡ 2. Golden Rules

```text
Avoid N+1 → no loop + query
Push logic to DB → not C#
DISTINCT → remove duplicates (JOIN case)
EXISTS → better for presence check
```

---

# 🧠 3. Index Basics

```text
Index = faster reads
Use on: WHERE, JOIN columns

Composite Index:
(AssociateId, ExpiryDate) ✅
Order matters!
```

---

# 🔥 4. MUST-KNOW QUESTIONS

---

# ✅ 1. 2nd Highest Salary per Department

---

## 🔹 Correlated Subquery

```sql
SELECT *
FROM employee e
WHERE 1 = (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employee e2
    WHERE e2.deptid = e.deptid
    AND e2.salary > e.salary
);
```

---

## 🔹 JOIN Version

```sql
SELECT e.*
FROM employee e
JOIN (
    SELECT deptid, MAX(salary) AS second_highest
    FROM employee
    WHERE salary < (
        SELECT MAX(salary) FROM employee e2
        WHERE e2.deptid = employee.deptid
    )
    GROUP BY deptid
) t
ON e.deptid = t.deptid AND e.salary = t.second_highest;
```

---

## 🔹 CTE Version

```sql
WITH DeptMax AS (
    SELECT deptid, MAX(salary) AS max_sal
    FROM employee
    GROUP BY deptid
),
SecondMax AS (
    SELECT e.deptid, MAX(e.salary) AS second_highest
    FROM employee e
    JOIN DeptMax d ON e.deptid = d.deptid
    WHERE e.salary < d.max_sal
    GROUP BY e.deptid
)
SELECT e.*
FROM employee e
JOIN SecondMax s
ON e.deptid = s.deptid AND e.salary = s.second_highest;
```

---

# ✅ 2. Salary > Department Avg

```sql
SELECT *
FROM employee e
WHERE salary > (
    SELECT AVG(e2.salary)
    FROM employee e2
    WHERE e2.deptid = e.deptid
);
```

---

# ✅ 3. Highest in Dept BUT not Highest in Company

```sql
SELECT *
FROM employee e
WHERE e.salary = (
    SELECT MAX(salary)
    FROM employee e2
    WHERE e2.deptid = e.deptid
)
AND e.salary < (
    SELECT MAX(salary) FROM employee
);
```

---

# ✅ 4. Associates with Expiring Attachments

---

## 🔹 EXISTS (Best)

```sql
SELECT a.Id, a.Name
FROM Associates a
WHERE EXISTS (
    SELECT 1
    FROM Attachments at
    WHERE at.AssociateId = a.Id
    AND at.ExpiryDate BETWEEN GETDATE()
        AND DATEADD(DAY, 3, GETDATE())
);
```

---

## 🔹 JOIN Version

```sql
SELECT DISTINCT a.Id, a.Name
FROM Associates a
JOIN Attachments at
    ON at.AssociateId = a.Id
WHERE at.ExpiryDate BETWEEN GETDATE()
    AND DATEADD(DAY, 3, GETDATE());
```

---

## 🔹 LINQ (EF Core)

```csharp
var result = await _context.Associates
    .Where(a => a.Attachments.Any(at =>
        at.ExpiryDate >= DateTime.Today &&
        at.ExpiryDate <= DateTime.Today.AddDays(3)))
    .Select(a => new { a.Id, a.Name })
    .ToListAsync();
```

---

# 🧠 5. Key Conversions (VERY IMPORTANT)

| SQL    | EF Core             |
| ------ | ------------------- |
| EXISTS | `.Any()`            |
| JOIN   | Navigation property |
| WHERE  | `.Where()`          |

---

# 🧠 6. Ready-to-Say Lines

- “I’ll use correlated subquery for per-row comparison”
- “I’ll avoid N+1 queries by using single query”
- “EXISTS is better here to avoid duplicates”
- “I’d use composite index on (AssociateId, ExpiryDate)”

---

# 🧘 Final 10-Second Mindset

```text
Think → Explain → Write
Not → Panic → Rush
```
