# SQL Problem: Identify Product IDs with All Invalid Date Ranges

## 🧨 Problem Statement

We have a table:

```
productId | price | startDate   | endDate
------------------------------------------
1         | 10    | 2025-01-20  | 2025-08-20
1         | 20    | 2025-07-10  | 2025-10-05
2         | 25    | 2025-04-20  | 2025-07-10
```

Assume today's date is:

```
2025-03-24
```

### 🎯 Goal

Find all `productId` such that:

> **For that productId, ALL rows have invalid date ranges (i.e., today's date is NOT within startDate and endDate for every row).**

### ⚠️ Important Rule

- If even **one row is valid**, exclude that `productId`.

---

## ✅ Expected Output

```
productId
----------
2
```

---

# 🧠 Solution 1 — COUNT vs COUNT (Advanced Logic)

```sql
SELECT productId
FROM products
GROUP BY productId
HAVING COUNT(*) = COUNT(CASE 
    WHEN NOT ('2025-03-24' BETWEEN startDate AND endDate) 
    THEN 1 
END);
```

## 🔍 Explanation

### Step 1: GROUP BY
Group rows by `productId`.

### Step 2: COUNT(*)
Counts total rows in each group.

### Step 3: COUNT(CASE ...)
- Returns `1` for invalid rows
- Returns `NULL` for valid rows
- COUNT ignores NULLs

### Step 4: HAVING condition
```
COUNT(*) = COUNT(invalid rows)
```

👉 Means:
> All rows are invalid

---

## 🧠 Key Insight

> COUNT(expression) ignores NULL, enabling conditional counting.

---

# 🧠 Solution 2 — SUM with CASE (Cleaner & Preferred)

```sql
SELECT productId
FROM products
GROUP BY productId
HAVING SUM(CASE 
    WHEN '2025-03-24' BETWEEN startDate AND endDate THEN 1 
    ELSE 0 
END) = 0;
```

## 🔍 Explanation

### Step 1: CASE Logic
- Valid row → 1
- Invalid row → 0

### Step 2: SUM
Counts how many valid rows exist.

### Step 3: HAVING condition
```
SUM(valid rows) = 0
```

👉 Means:
> No valid rows exist → all are invalid

---

## 🧠 Key Insight

> SUM + CASE converts boolean logic into numeric aggregation.

---

# ⚔️ Comparison

| Approach | Logic | Readability |
|----------|------|-------------|
| COUNT vs COUNT | All rows invalid | Medium |
| SUM + CASE | No valid rows | High (preferred) |

---

# 🔥 Final Takeaway

> Aggregation + CASE lets you evaluate conditions across entire groups instead of individual rows.
