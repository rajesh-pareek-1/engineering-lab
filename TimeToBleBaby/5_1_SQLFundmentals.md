
# ⚡ SQL Cheat Sheet (Crisp & Crunchy)

## 🔹 1. NULL Handling (LT-584)

* ❌ Never use `=` with `NULL`
* ✅ Use `IS NULL` / `IS NOT NULL`

```sql
SELECT *
FROM table_name
WHERE referee_id IS NULL OR referee_id != 2;
```

---

## 🔹 2. DISTINCT + ORDER BY (LT-1148)

* `DISTINCT` removes duplicates
* `ORDER BY` always comes **last**

```sql
SELECT DISTINCT author_id AS id
FROM table_name
ORDER BY id;
```

---

## 🔹 3. SQL Execution Order (VERY IMPORTANT 🔥)

Actual execution order:

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
```

👉 This explains:

* Why `WHERE` comes before `GROUP BY`
* Why aliases don’t work in `WHERE`

---

## 🔹 4. String Functions (LT-1683)

* Use `LENGTH()` for string size

```sql
SELECT *
FROM users
WHERE LENGTH(name) > 1;
```

---

## 🔹 5. JOIN Rules (LT-1378)

* `LEFT` / `RIGHT JOIN` **must have condition**
* Use:

  * `ON` (common)
  * `USING` (shortcut)

```sql
SELECT *
FROM A
LEFT JOIN B
ON A.id = B.id;
```

⚠️ Multiple conditions:

```sql
ON A.id = B.id AND A.type = B.type;
```

---

## 🔹 6. WHERE vs HAVING

* `WHERE` → filters rows (before grouping)
* `HAVING` → filters groups (after grouping)

```sql
SELECT dept, COUNT(*)
FROM emp
WHERE salary > 50000
GROUP BY dept
HAVING COUNT(*) > 5;
```

---

## 🔹 7. Date Functions (LT-197)

* `DATEDIFF(date1, date2)`

```sql
DATEDIFF(w1.recordDate, w2.recordDate) = 1
```

👉 Useful for consecutive dates

---

## 🔹 8. ENUM / String Comparison (LT-1661)

* Compare like normal strings

```sql
a1.activity_type = 'start'
```

---

## 🔹 9. Aggregate Functions + ROUND

* `AVG()` is aggregate
* Use `ROUND()` for precision

```sql
ROUND(AVG(a2.timestamp - a1.timestamp), 3)
```

---

## 🔹 10. CROSS JOIN (LT-1280)

* Used when **no common column**
* Produces all combinations

```sql
SELECT *
FROM students
CROSS JOIN subjects;
```

---

## 🔹 11. Golden Rules 🧠

✔️ `WHERE` always before `GROUP BY`
✔️ `ORDER BY` always last
✔️ `ON` defines join condition
✔️ `CROSS JOIN` → no `ON` needed
✔️ Never use `=` with `NULL`
✔️ Use `AND` for multiple conditions (not “an”)

---

## 🔥 Ultra-Short Memory Trick

👉 **F J W G H S O**
(FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY)

