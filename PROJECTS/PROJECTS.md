# PROJECTS

Use this file when the Arenaer asks:

- "Tell me about your project."
- "Did you use microservices?"
- "Explain the architecture."
- "What did you actually work on?"
- "How did you handle performance / background jobs / multi-tenancy?"
- "Have you used agentic AI?"
- "Which database did you use and why?"
- "Where did you use dependency injection?"

## 10-Second Project Selector

| Arena angle                                 | Use this project                                              |
| ------------------------------------------- | ------------------------------------------------------------- |
| Backend APIs, logistics, shipments, drivers | ROD                                                           |
| Microservices / integration services        | ROD QuickBooks service                                        |
| React Native, mobile driver flows           | ROD Driver Mobile App                                         |
| Multi-tenant SaaS, cattle/feedlot domain    | Feedlot Manager                                               |
| Background jobs, Hangfire, tenant context   | Both                                                          |
| Real-time notifications / MQTT              | Feedlot Manager                                               |
| EF Core, SQL, performance, reports          | Both                                                          |
| Database design, tenant DBs, reporting      | Both                                                          |
| Dependency injection                        | Both                                                          |
| Agentic AI/dev workflow                     | Dev flow, not production runtime unless specifically verified |

## Architecture Truth: Are These Microservices?

Do not overclaim.

Best answer:

```text
I would not call the whole system pure microservices. The core backend is mostly a modular monolith: one ASP.NET Core API with layered projects for controllers, services, repositories, EF Core, common utilities, and tenant management.

But ROD has a separate QuickBooks integration service, with its own solution, Dockerfile, pipeline, data layer, background processing, and SOAP/message-processing flow. So I describe the architecture as hybrid: modular monolith for the core domain API, plus separate integration services/background workers where isolation and async processing make sense.
```

### Feedlot Manager

```text
Feedlot Manager is not a pure microservices system. It is a modular ASP.NET Core backend with multi-tenancy, EF Core, Hangfire background jobs, MQTT notifications, feature flags, and external integrations.
```

### ROD

```text
ROD is closer to service-oriented architecture. The main dispatch API is modular/layered, while QuickBooks integration is separated into its own deployable service. That gives an independent boundary for accounting sync and background processing.
```

## ROD: RollOnDispatch

### Project Description

```text
ROD is a multi-tenant logistics and dispatch SaaS platform. It helps dispatch teams manage shipments, orders, driver loads, attachments, invoices, customer/broker data, reporting, and accounting sync.

The backend is ASP.NET Core Web API with EF Core and SQL Server/Azure SQL. The main API owns core dispatch workflows, while the separate QuickBooks service handles accounting integration, request/response queues, SOAP/Web Connector flow, and background processing. The system also includes a React web app, React Native driver app, tenant provisioning scripts, Docker/pipeline assets, and integration/background job infrastructure.
```

### 30-Second Pitch

```text
RollOnDispatch is a multi-tenant logistics platform for dispatch and trucking workflows. It manages shipments, driver assignment, load tracking, invoicing, reporting, and QuickBooks integration. The main backend is ASP.NET Core with EF Core and SQL, and it follows controller-service-repository layering. It also has React web and React Native driver apps. For slower or integration-heavy work, it uses background jobs and a separate QuickBooks service.
```

### 90-Second Pitch

```text
ROD is a SaaS logistics system. The main API handles shipment and driver workflows: creating shipments, assigning loads, tracking driver progress, uploading/handling attachments, generating invoices, and supporting tenant-specific data access.

The backend is layered: controllers handle HTTP, services enforce business rules, repositories handle EF Core persistence, and tenant management resolves the correct tenant context/database. Authentication uses JWT, and scoped services use tenant/user context during the request.

The interesting architecture point is that the core API is not split into many microservices. It is a modular monolith. But QuickBooks is separated into its own service, with its own solution, Docker build, pipeline, data layer, Hangfire/background processing, and SOAP endpoint for QuickBooks Web Connector. That isolation makes sense because accounting sync is external-system-heavy, retryable, and operationally different from normal dispatch APIs.
```

### Main Components

```text
dm-api
  RollOnDispatch API
  RollOnDispatch.Data
  RollOnDispatch.Common
  TenantManagement

quickbooks-service
  QuickBooks API/service
  QuickBooks.Data
  QuickBooks.Library
  background/message processing

dm-web
  React web client

dm-driver-mobile-app
  React Native driver app

dm-cicd
  pipelines, tenant provisioning, infrastructure scripts
```

### Request Flow

```text
Client/mobile/web
-> ASP.NET Core middleware
-> JWT authentication
-> tenant/user context
-> controller
-> service validation/business rules
-> repository
-> EF Core
-> tenant/global SQL database
-> response DTO
```

### QuickBooks Service Flow

```text
Dispatch workflow creates invoice/accounting work
-> message/request queue or background process
-> QuickBooks service picks up work
-> builds QuickBooks XML/SOAP request
-> QuickBooks Web Connector / QuickBooks Online flow
-> response stored in response queue/status tables
-> failures retried or surfaced for review
```

Say:

```text
QuickBooks is a good boundary because it talks to an external accounting system, needs retry and status tracking, and has a different operational lifecycle from normal shipment APIs.
```

### Microservices Answer For ROD

```text
ROD is hybrid. The core dispatch backend is a modular monolith, not dozens of microservices. But QuickBooks is separated as its own deployable integration service. We also use async/background processing patterns like Hangfire and Service Bus-style messaging to decouple slow external work from request/response APIs.
```

### What I Worked Around / Can Explain

- Shipment and driver/load workflows.
- API integration between backend, web, and mobile.
- Validation and DTO/service/repository flow.
- EF Core query behavior and performance.
- Tenant-aware backend flows.
- Background jobs and external sync tradeoffs.
- QuickBooks integration at architecture level.

### Strong Technical Talking Points

#### Multi-tenancy

```text
Tenant identity comes from authenticated claims/request context. Tenant-aware services use that context to resolve tenant data access. The benefit is isolation; the tradeoff is migration, connection, reporting, and background-job complexity.
```

#### Background jobs

```text
Slow or retryable work should not block the API request. The request records or enqueues work, returns quickly, and a worker processes it with retry, logging, and idempotency.
```

#### Performance

```text
For list/report APIs, I focus on filtering before materialization, projection with Select, pagination limits, AsNoTracking for reads, indexes on common filters, and avoiding N+1.
```

#### Mobile integration

```text
The driver mobile app consumes API contracts for load/driver workflows. The important backend responsibility is stable DTOs, predictable status transitions, auth, offline/network tolerance, and clear error responses.
```

### ROD Arena Questions

#### Did ROD use microservices?

```text
Partially. The core domain API is a modular monolith, while QuickBooks integration is separated into its own service. I would call it a hybrid architecture rather than pure microservices.
```

#### Why separate QuickBooks?

```text
Because accounting sync is slow, retryable, external-system-dependent, and operationally different from normal dispatch APIs. Separating it reduces coupling and lets failures be retried/monitored independently.
```

#### Why not split everything?

```text
Microservices add deployment, observability, network, data consistency, and debugging complexity. For core CRUD/domain workflows, a modular monolith can be simpler and faster. Split only where the boundary gives real operational value.
```

#### What can go wrong in background sync?

```text
Retries can duplicate side effects, tenant context can be missing, external systems can be down, and partial failures can leave unclear status. The answer is idempotency, correlation IDs, retry/dead-letter handling, and visible sync status.
```

## Feedlot Manager

### Project Description

```text
Feedlot Manager is a multi-tenant cattle feedlot operations platform. It manages feed calls, rations, pens, cattle movement, medical treatments, inventory-style workflows, billing, reports, finance/QuickBooks-related flows, and operational notifications.

The backend is ASP.NET Core 8 with EF Core and SQL Server/Azure SQL. It uses database-per-tenant resolution, a global shared database, tenant-aware request context, Hangfire priority queues, MQTT notifications, OData-style read endpoints, feature flags, raw SQL/stored procedures for reports, and React Native/mobile integration.
```

### 30-Second Pitch

```text
Feedlot Manager is a multi-tenant cattle feedlot management platform. It supports feed operations, cattle movement, medical treatments, billing, reporting, inventory-style workflows, QuickBooks-related finance flows, and real-time notifications. The backend is ASP.NET Core 8 with EF Core, SQL, Hangfire, MQTT, feature flags, and React Native/mobile integration.
```

### 90-Second Pitch

```text
Feedlot Manager is a full-stack SaaS platform for cattle feedlot operations. It manages feed calls, rations, pens, cattle movement, medical treatments, billing, reports, and operational notifications.

The backend is a modular ASP.NET Core API. It uses controller-service-repository layering, EF Core repositories, tenant-aware database resolution, feature flags, OData-style querying for read-heavy endpoints, and Hangfire for background jobs. It also uses MQTT for real-time notifications, where messages can be published per environment, tenant, feedlot, and topic.

Architecturally, it is not pure microservices. It is a modular monolith with distributed integration patterns: background queues, MQTT notifications, QuickBooks/finance messaging, and a separate migration app. That design keeps core domain workflows in one backend while still decoupling slow or external work.
```

### Main Components

```text
FeedlotManager
  Main ASP.NET Core API
  JWT auth
  controllers/routes
  Hangfire dashboard/server
  MQTT startup/integration

FeedlotManager.Data
  EF Core DbContext
  repositories
  migrations
  raw SQL/stored procedure files

FeedlotManager.Common
  feature flags
  constants
  shared utilities
  timezone helpers

TenantManagement
  tenant context
  tenant DB factory
  audit base context
  Hangfire tenant context

FeedlotManager.DataMigration
  migration runner

ngat-fm-app
  React Native app
```

### Request Flow

```text
React Native/web client
-> ASP.NET Core middleware
-> JWT/auth policy
-> route/action filters
-> request context loads tenant/feedlot/user info
-> controller
-> service
-> repository
-> tenant DbContext
-> SQL
-> DTO response
```

### Multi-Tenant Flow

```text
JWT/user context
-> RequestContext stores TenantId, UserId, FeedLotId, timezone, roles
-> TenantDbContextFactory resolves tenant database
-> CCFMContext handles tenant business data
-> AppGlobalContext handles shared/global data
```

Say:

```text
The important design point is that tenant is resolved per request, not hard-coded at startup. That is why tenant-aware DbContext creation and request context matter.
```

### Background Job Flow

```text
API/service identifies slow or async work
-> enqueue Hangfire job
-> preserve tenant/feedlot/audit context
-> worker runs on configured queue
-> update DB/status/logs
```

Queues:

```text
acute, critical, default, minimal, nonessential
```

Say:

```text
The main production risk is context loss. Background jobs run outside the original HTTP request, so tenant/feedlot/user/audit context must be captured and restored.
```

### MQTT Flow

```text
Domain event or operation changes state
-> service publishes notification
-> MQTT topic includes environment/tenant/feedlot/topic
-> clients can react to operational updates
```

Say:

```text
MQTT is used for real-time operational updates. It is not the same as microservices; it is a messaging/notification integration pattern.
```

### Feedlot Manager Microservices Answer

```text
Feedlot Manager is not a pure microservices architecture. It is a modular monolith with distributed pieces. The domain API is one main backend, but it uses Hangfire for background processing, MQTT for real-time notifications, feature flags for controlled rollout, tenant-aware DB resolution, and external integrations like QuickBooks/finance messaging.
```

### Strong Technical Talking Points

#### OData/read-heavy endpoints

```text
For read-heavy list screens, OData-style query support helps with filtering, selecting, ordering, counting, and expanding. The risk is over-fetching or expensive queries, so API limits and query review matter.
```

#### Raw SQL/reports

```text
For report-heavy flows, raw SQL/stored procedures can be useful when EF queries become too complex or need performance tuning. The tradeoff is maintainability and migration/version control.
```

#### Feature flags

```text
Feature flags allow controlled rollout and safer production changes. The tradeoff is flag cleanup and avoiding too many conditional paths.
```

#### Timezone handling

```text
Feedlot operations depend on feedlot-local dates, not just UTC. Shared timezone helpers prevent inconsistent date calculations across validation, billing, reports, and background jobs.
```

### Feedlot Manager Arena Questions

#### Did Feedlot Manager use microservices?

```text
Not in the strict sense. It is mainly a modular monolith. It uses service-style integration patterns like Hangfire, MQTT, and external finance/QuickBooks messaging, but the core business domains live in one backend API.
```

#### Why use Hangfire?

```text
For work that should not block request/response flow: report generation, notifications, finance sync, or scheduled processing. It gives queues, retries, dashboard visibility, and background execution.
```

#### Why use MQTT?

```text
For real-time operational notifications where clients need timely updates. It decouples state changes from client update delivery.
```

#### What was hard technically?

```text
The hard part is keeping tenant/feedlot/timezone context consistent across normal HTTP requests, background jobs, reports, and real-time notifications.
```

## Cross-Project Architecture Summary

## Modular Monolith vs Microservices

```text
Multiple projects in a .NET solution are not automatically microservices. If they compile into one deployable API, they are modules/layers. A microservice boundary usually means independently deployed, independently scalable, with its own runtime/process and often its own data ownership.
```

## What These Projects Actually Use

| Pattern                      | ROD                     | Feedlot Manager  |
| ---------------------------- | ----------------------- | ---------------- |
| ASP.NET Core Web API         | Yes                     | Yes              |
| EF Core / SQL                | Yes                     | Yes              |
| Multi-tenancy                | Yes                     | Yes              |
| Modular layered architecture | Yes                     | Yes              |
| Hangfire background jobs     | Yes                     | Yes              |
| Separate integration service | Yes, QuickBooks service | Not primarily    |
| React Native app             | Yes, driver app         | Yes, ngat-fm-app |
| Real-time/MQTT               | Less central            | Yes              |
| Azure pipelines/Docker       | Yes                     | Yes              |
| Pure microservices           | No                      | No               |

## Arena-Safe Final Answer

```text
Both systems are backend-heavy SaaS products with modular ASP.NET Core APIs. I would not overstate them as pure microservices. The core domain backends are modular monoliths with clean layering and tenant-aware data access. ROD has a clearer microservice-style boundary through the separate QuickBooks integration service. Feedlot Manager uses distributed integration patterns like Hangfire and MQTT but keeps the core domain inside one backend.
```

## Real Arena Add-Ons

## Agentic AI: Have You Used Or Integrated AI Tools?

### Short Answer

```text
I have used agentic AI more in the development workflow than as a production runtime feature in these systems. I would not claim the products are AI-native unless there is an actual shipped AI workflow. In dev flow, AI is useful for understanding legacy code, generating first-draft tests, summarizing flows, creating PR/commit context, and reviewing risky changes. I still treat it as assisted engineering, with human review, because these projects touch tenant data, billing, and external accounting sync.
```

### Project-Safe Answer

```text
In Feedlot Manager there is explicit coding-agent guidance for developers: how an AI coding agent should understand the backend structure, tenant context, commit context, tests, and architecture. That is dev-process integration, not a customer-facing AI feature.

For production, I would only integrate agentic AI behind controlled boundaries: read-only first, strict tool allowlists, human approval for writes, audit logs, tenant isolation, and no direct unsupervised changes to billing, accounting, or cattle/shipment state.
```

### If They Ask "How Would You Add AI?"

```text
I would start with an internal operations assistant, not automatic domain actions.

Example:
User asks a support/debugging question
-> API authenticates tenant/user
-> AI orchestration service retrieves allowed docs/log summaries/status data
-> tool calls are allowlisted and tenant-scoped
-> answer includes evidence and correlation IDs
-> any write action requires explicit human confirmation
-> audit record is stored
```

### Good Use Cases

- Explain failed QuickBooks sync status.
- Summarize background job failures by tenant/correlation ID.
- Suggest likely slow endpoints from logs/query metrics.
- Generate test cases for service/repository changes.
- Create release notes or migration risk summaries.
- Help developers navigate legacy service/repository flows.

### Red Lines

- Do not let AI directly create invoices, post accounting entries, update tenant data, or change cattle/shipment state without approval.
- Do not send secrets, full production data, or cross-tenant data into an AI tool.
- Do not trust generated SQL/migrations without review and test data.
- Do not use AI as a replacement for authorization, validation, audit, or idempotency.

## Database: Which DB And Why?

### Short Answer

```text
Both projects use SQL Server/Azure SQL through EF Core. That fit the domain because the data is highly relational and transactional: tenants, users, roles, shipments, orders, driver loads, invoices, feedlots, pens, cattle, treatments, billing, and reports. We needed joins, foreign keys, transactions, indexes, migrations, reporting queries, and mature EF Core provider support.
```

### Do Not Say

```text
SQL Server is the only database that can do this.
```

### Better Say

```text
Other databases can solve parts of this, but SQL Server was a strong fit because the core source of truth is relational and consistency-heavy. NoSQL would be useful for logs, events, telemetry, or document-style payloads, but the main business workflows need transactional updates, joins, constraints, reports, and tenant-aware relational data access.
```

### Project Database Design

| Area            | What To Say                                                                         |
| --------------- | ----------------------------------------------------------------------------------- |
| Primary DB      | SQL Server/Azure SQL with EF Core                                                   |
| Multi-tenancy   | Tenant-specific database/context resolved from authenticated request context        |
| Global data     | Separate global/shared context for tenant/account/config style data                 |
| ORM             | EF Core repositories and migrations                                                 |
| Heavy reads     | OData-style filtering/sorting/paging; projections; `AsNoTracking` where appropriate |
| Reports         | Raw SQL/stored procedures for complex reporting paths                               |
| Performance     | Indexes, pagination, projection, avoiding N+1, query plan review                    |
| Background jobs | Persist job status/audit; preserve tenant context outside HTTP                      |
| QuickBooks      | Request/response queue tables and sync state tracking                               |
| Audit           | EF Core change tracking/audit context for created/updated/deleted records           |

### Special Things Worth Sharing

```text
The most interesting database part is multi-tenancy. Tenant data is not just filtered by TenantId in one table; the architecture can resolve a tenant database per request through tenant context. That improves isolation, but it makes migrations, background jobs, reports, connection resolution, and debugging more complex.
```

```text
Feedlot Manager also has a global context plus tenant contexts. Some report paths can use a read-only replica behind a feature flag, and raw SQL/stored procedures are used where report queries are too complex or performance-sensitive for normal EF query composition.
```

```text
ROD has accounting sync state around QuickBooks: request queues, response queues, connection details, tenant-specific sync state, and background/message processing. The DB is not only CRUD storage; it also helps make async external integration observable and retryable.
```

### Database Edge Cases

- Tenant context must never leak across requests or background jobs.
- Background jobs run outside HTTP, so tenant/feedlot/user/audit context must be captured and restored.
- OData or flexible filters can accidentally create expensive queries.
- Reports need pagination/limits and query-plan review.
- EF `Include` can create N+1 or over-fetching if used casually.
- Cross-database or external-service workflows need idempotency because one side can succeed while the other fails.
- Read replicas can be stale, so use them for reporting, not critical writes.
- Migrations across many tenant databases need orchestration and rollback discipline.
- Raw SQL must be parameterized and versioned with the application.

### 60-Second Arena Answer

```text
We used SQL Server/Azure SQL with EF Core because the domain is relational and transaction-heavy. In ROD you have shipments, orders, driver loads, invoices, customers, tenants, and QuickBooks sync state. In Feedlot Manager you have feedlots, pens, cattle movement, medical treatment, billing, inventory-style workflows, and reports.

The interesting part is tenant-aware database access. Tenant identity comes from request/auth context, then services/repositories use a tenant DbContext factory to resolve the right database/context. That gives isolation, but it creates edge cases for migrations, background jobs, read replicas, reports, and debugging. For performance, we use indexes, projection, pagination, OData carefully, AsNoTracking for reads, and raw SQL/stored procedures for complex reports.
```

## Dependency Injection: Where Did You Use It?

### Short Answer

```text
DI is used throughout the ASP.NET Core backend. Controllers depend on services, services depend on repositories, repositories depend on EF Core DbContexts, and cross-cutting services like logging, configuration, feature flags, request context, audit context, background job service, email/message integrations, and tenant DbContext factories are registered in the container.
```

### Concrete Examples From Projects

| DI Usage                 | Example Talking Point                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------- |
| Service layer            | `IFMFeedlotService -> FMFeedlotService`, `IBillingService -> BillingService`, shipment/invoice services |
| Repository layer         | Repository interfaces registered to repository implementations                                          |
| Tenant infrastructure    | `IRequestContext`, `ITenantDbContextFactory`, `IAuditContext`                                           |
| EF Core                  | `AddDbContextPool` / tenant DbContext factory for SQL Server contexts                                   |
| Feature flags            | Feature manager abstraction injected into services                                                      |
| Background jobs          | `IBackgroundJobService`; Hangfire activator creates scoped job instances                                |
| Multiple implementations | Audit handlers, email/message integrations, QuickBooks-related services                                 |
| Testing                  | Swap real services with mocks/in-memory contexts in unit/integration tests                              |

### Lifetimes

```text
Most domain services and repositories are scoped because they depend on request-specific tenant context and EF Core DbContext. Singletons are only safe for stateless/shared infrastructure, authorization handlers, or test doubles that do not capture scoped state. Background workers must create a scope before resolving scoped services.
```

### Ways DI Appears

- Constructor injection in controllers, services, repositories, and background processors.
- Interface-to-implementation registration in `IServiceCollection` extension methods.
- DbContext registration/factories for SQL Server and tenant-specific context resolution.
- Multiple implementations for plugin-like behavior such as audit handlers or email/message integrations.
- Scope creation in background processing where there is no active HTTP request.
- Test-time replacement of services with mocks, fake feature managers, or in-memory DbContexts.
- Framework-provided injections: `ILogger<T>`, `IConfiguration`, `IHttpContextAccessor`, AutoMapper, feature flags, cache, and authorization handlers.

### Production Edge Cases

- Do not inject scoped DbContext/request context into a singleton.
- Do not store tenant context in static state.
- Create a DI scope inside hosted services, queue listeners, and Hangfire jobs.
- Be careful with multiple implementations of the same interface; use clear selection logic or `IEnumerable<T>`.
- Avoid service locator patterns except at framework boundaries like job activation.
- Keep controllers thin; inject one service that owns the use case instead of many repositories directly.
- In tests, replace dependencies at the container boundary instead of touching production code paths.

### 60-Second Arena Answer

```text
We used ASP.NET Core DI heavily. Controllers received services through constructor injection. Services received repositories, tenant context, feature flags, loggers, mappers, and background job services. Repositories received EF Core DbContexts or tenant DbContext factories.

The main reason DI mattered was multi-tenancy and testability. Request-scoped services could safely use the current tenant/user/feedlot context. Background jobs were trickier because they run outside HTTP, so they needed a new scope and restored tenant context before resolving scoped services. I would avoid injecting scoped DbContext into singleton services because that can create stale context and cross-request bugs.
```

## Common Resume Defense Lines

### If asked "what did you personally do?"

```text
I worked around these flows and can explain the architecture, integration points, and tradeoffs. For the exact pieces I did not own end-to-end, I separate what I implemented from what I understand.
```

### If asked "why this architecture?"

```text
The architecture keeps core domain logic simple in one backend, while using background jobs or separate services for slow, retryable, or external-system-heavy work.
```

### If asked "what would you improve?"

```text
I would focus on stronger idempotency around external sync, better correlation IDs/logging for background jobs, clearer tenant-context validation, pagination limits, query plan review for reports, and cleanup of old feature flags.
```

### If asked "what production risks do you watch?"

```text
Tenant context leakage, duplicate background work, slow reporting queries, missing pagination, stale mobile state, external system downtime, migration drift, and unclear failure visibility.
```

## 5 Answers To Memorize

### 1. Microservices

```text
Hybrid architecture: modular monolith for core APIs, separate integration service where the boundary gives operational value.
```

### 2. Multi-tenancy

```text
Tenant is resolved from authenticated context, not hard-coded. Tenant-aware data access picks the correct database/context per request.
```

### 3. Background jobs

```text
Use them for slow or retryable work. Preserve tenant context, make work idempotent, log status, and expose failures.
```

### 4. Performance

```text
Filter early, project only needed fields, avoid N+1, paginate, use AsNoTracking for reads, index common filters, and verify SQL plans.
```

### 5. React Native integration

```text
Mobile workflows depend on stable API contracts, auth/session handling, predictable status changes, offline/network tolerance, and clear errors.
```
