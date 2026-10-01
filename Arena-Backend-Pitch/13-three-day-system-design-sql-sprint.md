# Three-day system design + SQL hands-on sprint

> **Goal:** answer a design prompt with a clear structure and write common SQL from a blank editor, without depending on notes.
>
> **Assumption:** three focused core hours plus a mandatory 30-45 minute Production Scenario Layer each day. If more time is available, use it for the hands-on drills--not more passive reading.

## The answer engine: C-L-E-A-R

```text
C = Clarify users, workflow, rules, scale, and constraints
L = Lay out entities, relationships, and database ownership
E = Expose API contracts and layer responsibilities
A = Add async work, auth, validation, failures, and observability
R = Review indexes, transactions, reliability, and trade-offs
```

Use C-L-E-A-R for every design answer. Do not start by naming Docker, Redis, or microservices.

## Checkpoint protocol

After completing a checkpoint:

1. Say the checkpoint ID aloud and explain its answer without notes.
2. Save the SQL/design attempt, even if it is imperfect.
3. Tell Codex: `CP-<number> done`.
4. Add a concise correction note under `Arena-Backend-Pitch/Checkpoints/CP-<number>.md`:
   - prompt;
   - your first answer or query;
   - correction/learning;
   - final interview answer;
   - one remaining doubt, if any.

The note is proof of learning, not a polished article.

## Production Scenario Layer

These are not definition questions. The interviewer gives an incomplete production problem and evaluates engineering judgement.

```text
Clarify the actual requirement
-> identify the source of truth / bottleneck
-> choose the smallest reliable design
-> name the scale or failure risk
-> state how you will measure and verify success
```

Never begin with a tool name such as Redis, Docker, or AI. Begin with the problem and evidence.

---

# Day 1 - design foundation + SQL joins

## CP-01 - Turn a requirement into a design (45 min)

**Prompt:** Design a Student Document system where new document types and expiry rules can be added without changing existing core code.

```text
Business flow
Student -> uploads document -> validation -> approval/rejection -> expiry reminder

Core entities
Student | DocumentType | StudentDocument | DocumentRule | DocumentAudit

Key relationship
Student 1 -> many StudentDocuments
DocumentType 1 -> many StudentDocuments
```

Hands-on output on paper/Excalidraw/plain Markdown:

- five entities with primary and foreign keys;
- cardinalities;
- `POST /students/{id}/documents` and `GET /students/{id}/documents`;
- one OCP extension point, such as `IDocumentRule` strategies;
- one rule for expired and missing documents.

- [ ] **Done when:** You can give the C-L-E-A-R answer in five minutes and explain why a giant `switch(documentType)` is weak.

## CP-02 - SQL core from a blank editor (90 min)

Create a small practice schema mentally or in SQL Server:

```text
Tenants(TenantId, Name)
Drivers(DriverId, TenantId, Name, IsActive)
Shipments(ShipmentId, TenantId, DriverId, Status, CreatedAt)
Attachments(AttachmentId, DriverId, Type, Expiry, CreatedAt)
```

Write these **without copying**:

1. Active drivers for one tenant.
2. `INNER JOIN` shipments with drivers.
3. `LEFT JOIN` drivers with no shipments.
4. Shipment count per driver.
5. Drivers with more than five shipments using `HAVING`.
6. Latest attachment of each type for a driver.
7. Duplicate driver email/phone values.
8. Unassigned shipments ordered by newest first.

- [ ] **Done when:** You can explain `WHERE` versus `HAVING`, and `INNER JOIN` versus `LEFT JOIN`, with a Driver/Shipment example.

## CP-03 - ROD architecture story (45 min)

Read:

- `High-End-Topics/02-rod-backend-architecture.md`
- `06-aspnet-core-rest-api.md`

Say this flow from memory:

```text
HTTP request -> middleware -> controller -> service -> repository ->
tenant DbContext factory -> SQL Server -> response
```

- [ ] **Done when:** You can explain why controllers stay thin and identify one responsibility in every layer.

## PS-01 - AI honesty + SignalR threshold state (45 min)

### Card A - AI, ML, GenAI, and LLM

Say the hierarchy without using buzzwords:

```text
AI -> broad intelligent systems
ML -> AI that learns patterns from data
Generative AI -> creates content
LLM -> large ML model for language/token generation
```

Practice a truthful project answer:

```text
AI-assisted development use -> validate output with tests/review/security
Product LLM design -> backend keeps provider key, authorization/rate limit,
safe logging, grounded data only when required
```

Do not say ROD has a production LLM feature unless the source proves it.

### Card B - 50,000-user red/blue dashboard

**Prompt:** A dashboard turns red above 50,000 active users and blue below the lower threshold.

```text
Event/API -> Redis atomic counter and durable state -> transition service
-> state changed? -> SignalR tenant/dashboard group -> browser UI
```

Decide and explain:

- SignalR is delivery, not the source of truth;
- use hysteresis: red above 50,000; blue at or below 49,000;
- broadcast only state transitions, not every event;
- use Azure SignalR Service or a Redis backplane when application instances scale out;
- persist/restore the current state after process restart.

- [ ] **Done when:** You can answer the prompt in three minutes, including why one server's memory is unsafe at scale.

---

# Day 2 - reliable workflows + SQL transactions and performance

## CP-04 - Design an assignment transaction (60 min)

**Prompt:** A Dispatcher assigns a driver to a shipment. The system must prevent double assignment and record an audit entry.

Hands-on:

1. Write the API: `POST /shipments/{id}/assign-driver`.
2. List validation rules: dispatcher role, active driver, unassigned shipment.
3. Write a SQL `BEGIN TRY / BEGIN TRANSACTION / COMMIT / ROLLBACK` script.
4. Add a unique constraint or concurrency approach that prevents two requests winning.
5. Decide whether the client gets `400`, `404`, or `409` for each failure.

- [ ] **Done when:** You can explain atomicity, race condition, deadlock avoidance, and why the transaction is short.

## CP-05 - SQL power set (75 min)

Write from a blank editor:

1. A CTE for drivers with shipment counts.
2. Eighth highest **distinct** salary using `DENSE_RANK()`.
3. Current and previous year score using `LAG()`.
4. A parameterized stored procedure for assigning a driver.
5. A reusable scalar function.
6. A view for active drivers.
7. Clustered and non-clustered index creation statements.
8. Keyset pagination using `(CreatedAt, ShipmentId)`.

- [ ] **Done when:** You can state when a stored procedure, function, view, index, transaction, CTE, and window function is appropriate.

## CP-06 - Document-expiry reminder as a production workflow (60 min)

Read:

- `High-End-Topics/05-document-expiry-reminder-star.md`
- `High-End-Topics/06-hangfire-in-rod.md`

Draw this system:

```text
Hangfire recurring job
-> tenant context restoration
-> selected mobile-app drivers
-> attachment lookup
-> latest document per type
-> expiry rule
-> notification request
-> notification provider
```

Then answer:

- Where is N+1 risk?
- How would batching remove it?
- How do we avoid duplicate daily notifications?
- What happens if one driver notification fails?
- Why is this not an HTTP request?

- [ ] **Done when:** You can give the business value, technical flow, failure plan, and one scale improvement in two minutes.

## PS-02 - Slow API: telemetry before optimization (45 min)

**Prompt:** The API is fast locally but slow in production.

Use this response order:

```text
Measure -> trace -> isolate -> fix smallest cause -> verify before/after

Measure: p50/p95/p99 latency, error rate, route, tenant, traffic
Trace: controller, SQL, external calls, serialization, CPU/memory
Isolate: N+1, missing index, payload size, lock, dependency, timeout
Fix: projection, AsNoTracking, index, pagination, batching, queue, cache
Verify: latency/error/dependency/query metrics before versus after
```

Hands-on:

1. Write one structured `ILogger` statement containing `TraceId`, tenant, route, and duration.
2. Explain how EF-generated SQL and a SQL execution plan identify a database bottleneck.
3. Name one case where caching is the wrong first fix.
4. State the difference between application logs, traces, and metrics.
5. Explain why code can work locally but fail in production: environment variables/secrets, database permissions, network/DNS, configuration, container/runtime version, traffic, and external dependencies.
6. Design a third-party-call policy: timeout, retry only transient failures, exponential backoff with jitter, fallback or queue where valid, and dependency telemetry.
7. Explain global exception middleware versus feature-level business-error handling.
8. Explain when three independent downstream calls can use `Task.WhenAll`, and why concurrent EF queries cannot share one `DbContext`.

- [ ] **Done when:** You can answer without saying “I will immediately add Redis” or “I will increase server size.”

---

# Day 3 - tenant security, delivery, and interview simulation

## CP-07 - Design tenant-safe document upload (60 min)

**Prompt:** Build document upload/download for a database-per-tenant SaaS application.

Use this sequence:

```text
JWT -> authenticated tenant claim -> RequestContext -> authorization ->
tenant database metadata -> blob/document storage -> audit log -> response
```

Hands-on decisions:

- multipart request model versus direct Blob upload;
- document metadata table;
- tenant-scoped storage path/key;
- allowed type and size validation;
- expiry/retention;
- `401` versus `403` versus `404`;
- short-lived download access and audit logging.

Read `High-End-Topics/01-multitenancy.md` and `High-End-Topics/07-jwt-authentication-in-rod.md`.

- [ ] **Done when:** You can explain why the tenant comes from trusted JWT claims, not the request body.

## CP-08 - Release, migration, rollback (45 min)

Read the actual ROD pipeline and say this accurately:

```text
dev/test/main branch trigger
-> tests and feature flags
-> migration-source artifact
-> multi-stage Docker build
-> branch:BuildId image tag
-> Azure Container Registry
-> external release approval/deployment
-> migration execution (external release configuration)
-> health verification / rollback to prior image tag
```

Key truths:

- image tag is branch plus Azure DevOps `BuildId`, not commit SHA or `latest`;
- this repository builds and pushes the image, but does not prove the Azure hosting service or approval configuration;
- migrations are packaged as an artifact, but their execution command is outside this YAML.

- [ ] **Done when:** You can explain CI versus CD, artifact versus image, ACR versus AKS, and how immutable tags support rollback.

## CP-09 - final 45-minute mock (75 min)

Set a timer. No notes for the first answer.

### Design prompt A - one million row import

```text
Upload -> validate -> durable job -> chunk/batch -> staging -> upsert ->
error report -> progress status -> idempotency -> monitoring
```

### Design prompt B - slow API

```text
Trace/metrics -> dependency timing -> generated SQL -> execution plan ->
indexes -> EF materialization -> payload -> cache only when justified
```

### SQL sprint

Write, explain, and review:

1. `LEFT JOIN` unmatched rows.
2. Duplicate values.
3. Second-largest number/salary.
4. `DENSE_RANK()` eighth salary.
5. `LAG()` previous result.
6. Transactional driver assignment.
7. Composite index for a tenant/status/date query.

- [ ] **Done when:** You can answer each design prompt in seven minutes and write all seven SQL exercises without looking up syntax.

## PS-03 - data correctness under load (45 min)

### Card A - remove duplicate users

Write and explain:

```text
ROW_NUMBER() OVER (PARTITION BY Email ORDER BY Id)
-> keep row 1
-> delete rows above 1
-> add unique index so the issue cannot return
```

Then answer why a large table should be cleaned database-side rather than loaded into EF Core memory.

### Card B - two requests update the same resource

Practice these protections:

```text
database unique constraint
transaction for related changes
optimistic concurrency/version column
idempotency key for retried command
409 Conflict for an already-changed resource
```

### Card C - downstream rate limit

One provider permits 100 requests/minute and another permits 10,000.

```text
per-provider client policy
bounded queue
rate limiter
retry only transient failures
backoff + jitter
dead-letter/failure report
metrics and alerting
```

- [ ] **Done when:** You can distinguish duplicate cleanup, duplicate prevention, race conditions, retries, and rate limiting.

### Card D - cache design

**Prompt:** An expensive tenant hierarchy is read repeatedly but changes occasionally.

```text
cache-aside
-> key includes tenant ID and resource/version
-> cache hit returns value
-> miss reads database and stores value with TTL
-> write invalidates/refreshes affected key
```

Explain:

- `IMemoryCache` for one application instance;
- distributed Redis/`IDistributedCache` for multiple instances;
- expiry, invalidation, cache stampede, stale-data trade-off;
- cache is never the source of truth;
- never use unsafe user input or omit tenant identity from a cache key.

---

## Rapid coverage rotation - every prompt in the question bank

The core checkpoints teach the reusable architecture. These short cards ensure the wording of every common interview prompt is also familiar. Spend **six minutes per card**: two minutes to structure, three minutes to answer aloud, one minute to record the missing point.

| Category              | Deep checkpoint            | Rapid cards to rotate                                                                                      |
| --------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Entity/OOP design     | CP-01                      | City/country tax strategy; leave management; order placement; document audit/cardinality                   |
| REST/API design       | CP-01, CP-03               | CRUD; filtering/sorting; API versioning; three independent APIs with`Task.WhenAll`                       |
| Database/data flow    | CP-02, CP-04, CP-05        | tables/indexes; 10,000 files; duplicate prevention; changing-data/keyset pagination                        |
| Async/scale           | CP-06, CP-09, PS-01, PS-03 | PDF export; one-million-row import; retries/dead letter/correlation IDs; rate-limited downstream providers |
| Security/tenant       | CP-07                      | tenant onboarding; JWT refresh; role/policy authorization; body tenant-ID tampering                        |
| Production operations | PS-02, CP-08, PS-03        | local versus production; third-party outage; global exception handling; health checks; rollback            |

### Day 1 rapid cards - API and OOP (24 min)

1. City/country tax calculator using Strategy and OCP.
2. Leave system: entities, approval workflow, balance transaction.
3. `GET /shipments`: filtering, sorting, pagination, validation.
4. API versioning for old mobile clients.

### Day 2 rapid cards - data and async operations (24 min)

1. One-million-row import.
2. PDF export that must not time out.
3. 10,000-file processing with bounded concurrency.
4. Retry, dead-letter, idempotency, and correlation ID.

### Day 3 rapid cards - tenant and production failure (24 min)

1. Tenant onboarding from subscription to provisioned database/admin/jobs.
2. JWT expiry, refresh-token rotation, and a valid token receiving `403`.
3. Third-party outage and a request that works locally but fails in production.
4. Global middleware versus local/business error handling.

---

## Final confidence test

You are ready when you can say:

> “I start by clarifying the workflow and constraints, model the data and ownership, expose focused APIs, put business logic in services, then design for authorization, tenant isolation, transactions, async work, observability, and scale. I use measured evidence--queries, execution plans, metrics, and logs--before introducing complexity.”

## Do not spend these three days on

```text
- random framework trivia;
- memorizing every Azure service;
- implementing microservices for the sake of it;
- passive reading without writing SQL or speaking answers aloud.
```
