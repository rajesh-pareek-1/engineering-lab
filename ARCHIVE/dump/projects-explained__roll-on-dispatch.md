# RollOnDispatch Interview Story

## 30 Second Introduction

```text
Hi, I am Rajesh. I work as a software developer at In Time Tec with experience across ASP.NET Core APIs, React/React Native, EF Core, SQL, and Azure-based product systems. I have worked on production workflows involving multi-tenant APIs, shipment and driver workflows, database optimization, background processing, and mobile/web integrations.
```

## 60-90 Second Project Pitch

```text
RollOnDispatch is a multi-tenant SaaS platform for trucking and livestock logistics. It manages the shipment lifecycle: creating shipments, assigning drivers, tracking delivery status, generating invoices, reports, and syncing accounting data with QuickBooks.

The backend follows a layered architecture: controllers receive HTTP requests, services handle validation and business logic, repositories handle persistence, and EF Core maps domain entities to SQL. Tenant context comes from authenticated claims and resolves tenant-specific database access.

For scalability, heavy work such as invoice generation and external QuickBooks sync is moved out of the request path using Hangfire and Azure Service Bus. I worked mainly around shipment APIs, driver/load workflows, validation, async processing, and query performance improvements.
```

## Architecture

```text
Controller -> Service -> Repository -> EF Core -> SQL
```

Responsibilities:

- Controller: HTTP request, response, status codes.
- Service: business rules, validation, orchestration.
- Repository: data access and reusable persistence methods.
- EF Core: ORM, tracking, queries, migrations.
- Background jobs: slow work outside request path.

## Create Shipment API Flow

1. Request reaches controller.
2. Authentication middleware validates JWT.
3. Tenant/user context is available to scoped services.
4. Controller calls service.
5. Service validates DTO, maps to entity, applies business rules.
6. Repository adds entity using EF Core.
7. `SaveChangesAsync` persists data.
8. Activity logging captures changes from EF ChangeTracker.
9. Response returns shipment ID/status.

Interview line:

```text
I explain APIs as flow, reason, and tradeoff: what happens, why we designed it that way, and what can go wrong.
```

## Key Concepts

### Repository Pattern

```text
Repository separates data access from business logic and centralizes common operations like Add, Update, GetList, and Delete.
```

Tradeoff:

```text
Too generic a repository can hide EF Core's query power, so optimized queries should still allow projection and filtering.
```

### Generic CRUD

```text
Generic base services/repositories reduce duplicate CRUD logic across entities. Business-specific service logic calls common base operations after validation.
```

### FluentValidation

```text
Validation stays in the service/application layer instead of making controllers large. It also allows conditional rules based on shipment status or workflow state.
```

### Activity Logging

```text
Activity logging can use EF ChangeTracker to record what changed during SaveChangesAsync.
```

Tradeoff:

```text
If audit logging failure is swallowed, the main operation succeeds but audit trail may have gaps. If audit logging is in the same transaction, reliability improves but failures can block business operations.
```

### TransactionScope

```text
TransactionScope is useful when multiple DB operations must succeed or rollback together.
```

## Performance Talking Points

### Pagination

Use `Skip` and `Take`, but enforce maximum page size.

Tradeoff:

```text
No max limit can still allow huge responses and DB pressure.
```

### Projection

Use `Select` to fetch only needed columns.

```text
Projection reduces memory usage, network transfer, and EF tracking overhead.
```

### Async/Await

```text
Async APIs prevent request threads from blocking while waiting for DB or external calls.
```

Trap:

```text
Avoid sync DB calls inside async flows.
```

### Indexes

Add indexes on fields frequently used by shipment, associate, driver, status, and date filters.

## Async Systems

### Hangfire

Used for background jobs such as invoice generation, notifications, and scheduled processing.

### Azure Service Bus

Used to decouple QuickBooks sync or other external integration work.

Flow:

```text
API creates work -> message/job queued -> background processor handles it -> retry/log on failure
```

### Invoice Flow

```text
API request -> background job -> generate invoice/report -> send email -> publish QuickBooks sync message
```

## Tradeoffs To Mention

- No optimistic concurrency can lead to last-write-wins.
- Activity logging may have gaps if failures are ignored.
- Pagination needs max limits.
- Double `SaveChanges` can increase DB overhead.
- Background jobs need tenant context isolation.
- External sync must be idempotent because retries can happen.

## Common Questions

### Why Service Bus?

```text
To decouple the API from slow or unavailable external systems. It gives asynchronous processing and retry support.
```

### Why Hangfire?

```text
To process heavy or scheduled work outside the request path and avoid request timeouts.
```

### How Does Multi-Tenancy Work?

```text
The authenticated request carries tenant identity. Scoped request context exposes TenantId, and tenant-aware data access resolves the correct tenant database.
```

### What Would You Improve?

```text
I would enforce pagination limits, add optimistic concurrency where update conflicts matter, make audit logging reliability explicit, and strengthen tenant validation before DB access.
```

## Safety Lines

Use these when you know the area but did not own all of it:

- "I worked around this flow and understand the high-level design."
- "I did not implement that end-to-end, but the way it works is..."
- "The tradeoff I would watch for is..."

