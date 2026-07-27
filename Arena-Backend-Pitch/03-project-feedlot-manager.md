# 3. Feedlot Manager - Project Pitch and Cross-Questions

## 60-second project pitch

> Feedlot Manager is a multi-tenant agricultural SaaS platform supporting feedlot operations through web and mobile clients. Its backend is a .NET 8 ASP.NET Core application using EF Core and SQL Server. The domain includes feedlots, lots and pens, receiving and moving cattle, feeding, rations, medical workflows, inventory, shipping, billing, reports, and tenant management.
>
> I contributed within the existing layered backend by working with domain APIs, validation, tenant-aware data access, and reusable service and repository patterns. The main engineering challenge is that operational actions affect related records - for example moving cattle changes head counts and history - so validation and transactional consistency matter. The platform also uses JWT authorization, background processing, logging, tests, and Azure-oriented deployment practices.

## Mnemonic: **FARM-T**

- **F - Feedlot domain:** cattle, pens, feed, medical operations.
- **A - APIs:** web/mobile contracts and validation.
- **R - Reliable data:** EF Core, SQL Server, transactions.
- **M - Multi-tenancy:** tenant-aware context and isolation.
- **T - Test and trace:** tests, logs, monitoring.

## Domain mind map

```text
Feedlot Manager
├── Tenant and users
├── Cattle lifecycle
│   ├── receive
│   ├── assign to lot/pen
│   ├── move / treat / feed
│   └── ship or record mortality
├── Feed operations
│   ├── commodities and inventory
│   ├── rations and schedules
│   └── feed calls, routes, trucks
├── Finance
│   ├── billing and invoices
│   └── reports / QuickBooks
└── Platform
    ├── JWT and roles
    ├── background jobs
    ├── logging / monitoring
    └── web and mobile APIs
```

## How to explain multi-tenancy

> Multi-tenancy means one application serves multiple customer organizations while keeping their users, configuration, and business data isolated. A tenant is resolved from trusted authenticated context, not accepted blindly from the request body. The tenant identifier influences the database context or query filters, service rules, cache keys, jobs, and logs. Authorization still applies inside the tenant.

### Common storage models

1. **Shared database/shared schema:** every tenant-owned row has `TenantId`.
2. **Shared server/separate database:** a tenant resolver selects the connection/database.
3. **Hybrid:** shared management data plus isolated operational databases.

Safe project phrasing:

> The project contains tenant-management and tenant-aware context patterns. My responsibility was to work inside that established architecture, ensuring service operations used the resolved tenant context. I did not invent the entire multi-tenant architecture.

### Cross-questions

**Why not accept `TenantId` from the client?**

> A malicious user could change it and attempt cross-tenant access. Tenant identity should come from validated JWT claims, hostname, or another trusted mapping and be checked against the user's access.

**What can leak data even with a query filter?**

> Raw SQL, incorrectly configured entities, background jobs without tenant context, shared caches without tenant-prefixed keys, logs/exports, and administrative endpoints.

**How should Hangfire jobs carry tenant context?**

> Pass a tenant identifier as job data, validate it when the job starts, create a tenant-scoped service/context, and include it in logs. Do not rely on HTTP-scoped context because no HTTP request exists.

## Example domain flow: move cattle

This is a representative way to explain an operational API even if your exact feature differed.

```text
POST move request
  → authenticate user and resolve tenant
  → validate source, destination, date, and head count
  → load source/destination with required data
  → begin SQL transaction
  → reduce source count
  → increase destination count
  → create movement/history record
  → SaveChanges and commit
  → invalidate/update cache
  → return DTO and structured log
```

Cross-question: **Why a transaction?**

> The count changes and movement history represent one business operation. If one succeeds and another fails, the database becomes inconsistent. A transaction gives all-or-nothing behavior for those SQL changes.

Cross-question: **How do you handle two users moving cattle simultaneously?**

> Use optimistic concurrency with a row-version token or carefully chosen isolation/locking. Validate the available count again inside the transaction. If the version changed, return a conflict so the user refreshes rather than overwriting another operation.

## API validation layers

Mnemonic: **S-B-D**

- **S - Shape:** required fields, ranges, formats at DTO level.
- **B - Business:** domain rules in service/domain layer.
- **D - Database:** foreign keys, unique constraints, check constraints.

> Validation is strongest when each layer enforces what it knows best. A client check improves usability but is never a security or integrity boundary.

## Layered architecture answer

> The controller owns HTTP concerns: model binding, status codes, and calling the application service. The service owns the use case and business coordination. Repositories or the EF Core context own persistence queries. Dependency injection connects interfaces to implementations. DTOs prevent exposing persistence entities directly. This separation improves testability and keeps business rules out of controllers.

### Clean Architecture correction

> The resume uses the term Clean Architecture. The projects have layered separation and dependency-injection patterns. I would describe my hands-on work as layered architecture influenced by clean-architecture principles, rather than claiming the codebase follows every strict Clean Architecture rule.

## SQL Server correction

> My Feedlot Manager work used SQL Server. PostgreSQL on the resume is an editing mistake. My genuine experience is with relational design, EF Core, LINQ, transactions, indexing, and SQL Server execution behavior.

## Production-debugging story template

Use **TRACE**:

- **T - Trigger:** what input or workflow caused it?
- **R - Reproduce:** logs, request, tenant, data conditions.
- **A - Analyze:** controller → service → EF SQL → external dependency.
- **C - Correct:** smallest safe change plus data handling.
- **E - Evaluate:** tests, logs, deployment, monitoring.

Spoken answer:

> I start with a correlation ID, tenant, endpoint, timestamp, and expected versus actual behavior. I reproduce with safe data, trace the request into the service and generated SQL, and isolate whether the issue is validation, data, concurrency, or integration related. I make the smallest safe correction, add a regression test, validate in a non-production environment, and watch logs after deployment.

