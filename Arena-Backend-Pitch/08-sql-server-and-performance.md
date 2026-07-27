# 8. SQL Server, Transactions, and Performance

## SQL mind map

```text
SQL reliability
├── data model and constraints
├── joins and aggregation
├── indexes and execution plans
├── transactions and isolation
├── stored procedures
└── secure, measured optimization
```

## Join mnemonic: **I-L-R-F**

- **INNER:** matched rows only.
- **LEFT:** every left row plus matches/null.
- **RIGHT:** every right row plus matches/null.
- **FULL:** rows from either side.

Example:

```sql
SELECT s.Id, s.Reference, d.Name AS DriverName
FROM Shipments AS s
LEFT JOIN Drivers AS d ON d.Id = s.DriverId
WHERE s.TenantId = @TenantId;
```

Cross-question: **`WHERE` filter on the right table after `LEFT JOIN`?**

> A condition such as `WHERE d.IsActive = 1` removes null right-side rows and effectively behaves like an inner join. Put it in the `ON` clause if unmatched left rows must remain.

## `WHERE` vs `HAVING`

> `WHERE` filters rows before grouping; `HAVING` filters groups after aggregation.

```sql
SELECT TenantId, COUNT(*) AS ShipmentCount
FROM Shipments
WHERE CreatedAt >= @Start
GROUP BY TenantId
HAVING COUNT(*) > 100;
```

## Keys and constraints

- Primary key: unique row identity.
- Foreign key: referential integrity.
- Unique constraint/index: enforce business uniqueness.
- Check constraint: valid domain condition.
- Not null: required value.

> Application validation improves messages, but database constraints protect integrity against concurrency and alternate writers.

## Index mental model

> An index is an ordered access structure that can replace scanning many rows with seeking a smaller range. It speeds suitable reads but consumes storage and makes inserts/updates/deletes more expensive.

### Clustered vs nonclustered

> A clustered index determines the table's row organization at the leaf level; a table has one. A nonclustered index is a separate structure containing key values and a row locator, optionally with included columns.

**Why use a clustered index?**

> Its leaf level contains the actual data rows, so primary-key lookups and range scans over the clustered key can be efficient. It also gives the table one physical row-ordering strategy. A narrow, unique, stable, increasing key such as an identity is often a practical clustered key because it reduces page splits and keeps nonclustered row locators small.

**Clustered-index tradeoffs:**

- Only one per table.
- A wide clustered key is copied into nonclustered indexes and increases their size.
- Random or frequently changing keys cause page splits, fragmentation, and row movement.
- A clustered index does not guarantee result order; SQL still requires `ORDER BY`.

**Disadvantages of nonclustered indexes:**

- Every index consumes storage and memory/cache.
- Inserts, updates, and deletes must maintain every affected index.
- A non-covering index may require many key lookups to fetch remaining columns.
- Too many or overlapping indexes increase write latency and maintenance.
- Poor column order can make an index useless for the target predicate.

> The clustered index is not universally faster. I choose keys from workload and execution plans, and I balance read improvement against write cost.

### Composite-index rule

> Column order matters. Design around actual predicates and sorting. Equality columns often lead, followed by range/sort columns, but verify with the execution plan and workload.

Example:

```sql
CREATE INDEX IX_Shipments_Tenant_Status_Created
ON Shipments (TenantId, Status, CreatedAt DESC)
INCLUDE (Reference, DriverId);
```

This may help a tenant/status/date listing, but it is not automatically correct for every query.

## Sargability

> A sargable predicate allows efficient index seeking. Avoid wrapping indexed columns in functions when an equivalent range predicate exists.

Less efficient:

```sql
WHERE CAST(CreatedAt AS date) = @Date
```

Better:

```sql
WHERE CreatedAt >= @Date
  AND CreatedAt < DATEADD(day, 1, @Date)
```

## Execution plan

Mnemonic: **S-J-E-L**

- **S - Scan or seek?**
- **J - Join type and order?**
- **E - Estimated vs actual rows?**
- **L - Lookups, sorts, spills, warnings?**

> I capture the slow query and parameters, inspect the actual execution plan, IO/time statistics, row estimates, indexes, and returned columns. A scan is not always bad - for a small table or a query returning most rows, it may be optimal.

## Query-optimization answer: **MEASURE**

- **M - Measure** duration, CPU, logical reads.
- **E - Examine** generated SQL and execution plan.
- **A - Amount** of data returned and filtered.
- **S - Shape** joins, projection, pagination, N+1.
- **U - Useful indexes** and constraints.
- **R - Retest** with representative parameters.
- **E - Evaluate** write/storage cost and production impact.

## Transactions and ACID

Mnemonic: **A-C-I-D**

- **Atomicity:** all or none.
- **Consistency:** constraints/invariants remain valid.
- **Isolation:** concurrent work has controlled interaction.
- **Durability:** committed work survives failure.

> In the driver-load attachment flow, the SQL transaction protects related database records. It cannot roll back Azure Blob Storage, so the external side needs compensation or reconciliation.

## Isolation levels

- Read Uncommitted: permits dirty reads.
- Read Committed: prevents dirty reads; SQL Server default, behavior depends on configuration.
- Repeatable Read: protects read rows from change until transaction ends.
- Serializable: strongest traditional isolation; range protection and more blocking.
- Snapshot: reads row versions; reduces reader/writer blocking but can produce update conflicts and uses version storage.

Cross-question: **Which level should you always use?**

> There is no universal choice. Use the weakest level that preserves the business invariant, keep transactions short, and consider the database's row-versioning configuration and contention.

## Deadlock

> A deadlock occurs when transactions wait in a cycle for resources. SQL Server chooses a victim. Reduce risk by accessing resources in a consistent order, keeping transactions short, using suitable indexes, and avoiding unnecessary locks. Retry a deadlock victim only when the operation is safe/idempotent.

## Stored procedure vs EF Core

> EF Core is productive for composable CRUD and domain queries with type-safe application code. Stored procedures can be useful for established database APIs, complex set-based operations, security boundaries, or carefully tuned work. I choose based on maintainability and measured need, not ideology.

## Window-function examples

Latest row per driver:

```sql
WITH ranked AS (
    SELECT d.*,
           ROW_NUMBER() OVER (
               PARTITION BY DriverId
               ORDER BY UpdatedAt DESC
           ) AS rn
    FROM DriverDocuments AS d
    WHERE TenantId = @TenantId
)
SELECT * FROM ranked WHERE rn = 1;
```

### `LAG()` - compare each student's last 10 years with the previous year

Assume multiple results can exist per student and year, so first calculate the yearly score:

```sql
WITH YearlyPerformance AS
(
    SELECT
        StudentId,
        ExamYear,
        AVG(CAST(Score AS decimal(10, 2))) AS CurrentScore
    FROM StudentResults
    WHERE ExamYear >= YEAR(GETDATE()) - 9
    GROUP BY StudentId, ExamYear
), Compared AS
(
    SELECT
        StudentId,
        ExamYear,
        CurrentScore,
        LAG(CurrentScore) OVER
        (
            PARTITION BY StudentId
            ORDER BY ExamYear
        ) AS PreviousScore
    FROM YearlyPerformance
)
SELECT
    StudentId,
    ExamYear,
    CurrentScore,
    PreviousScore,
    CurrentScore - PreviousScore AS ScoreChange,
    CASE
        WHEN PreviousScore IS NULL THEN 'No previous result'
        WHEN CurrentScore > PreviousScore THEN 'Improved'
        WHEN CurrentScore < PreviousScore THEN 'Declined'
        ELSE 'No change'
    END AS Performance
FROM Compared
ORDER BY StudentId, ExamYear;
```

> `LAG` reads a value from a previous row without a self-join. `PARTITION BY StudentId` restarts the comparison for every student, and `ORDER BY ExamYear` defines what previous means. The first row has `NULL` because no previous row exists.

Important cross-question:

> If a student has results in 2023 and 2025 but not 2024, `LAG` compares 2025 with the previous available year, 2023. If the requirement means exact previous calendar year, join on `previous.ExamYear = current.ExamYear - 1` or generate a calendar set before applying `LAG`.

## Common interview queries

### Second-highest salary

```sql
SELECT MAX(Salary)
FROM Employees
WHERE Salary < (SELECT MAX(Salary) FROM Employees);
```

Clarify whether “second highest” means distinct salary and what to return if it does not exist.

### Duplicates

```sql
SELECT Email, COUNT(*)
FROM Users
GROUP BY Email
HAVING COUNT(*) > 1;
```

### Delete duplicates safely

> First define the survivor deterministically, preview inside a transaction, preserve foreign keys/audit needs, and preferably prevent recurrence with a unique constraint.

## SQL injection

> Use parameterized queries or EF Core parameterization. Never concatenate untrusted input into SQL. For dynamic sorting, allow-list known column names because identifiers cannot be handled like normal value parameters.

## PostgreSQL correction

> My hands-on project database is SQL Server. PostgreSQL appeared on the resume by mistake. I understand transferable relational concepts, but I would need to learn PostgreSQL-specific indexing, tooling, and SQL differences before claiming proficiency.
