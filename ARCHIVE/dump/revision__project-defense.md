# Project Defense Revision

## Opening Pitch

```text
I am Rajesh Pareek, a software developer with hands-on experience across ASP.NET Core, EF Core, SQL, React, React Native, and Azure DevOps. I have worked on SaaS/logistics systems involving REST APIs, shipment and driver workflows, multi-tenant backend design, database optimization, background jobs, and web/mobile integrations. My strongest area is backend/product engineering where I can connect API design, data flow, performance, and production tradeoffs clearly.
```

## RollOnDispatch Pitch

```text
RollOnDispatch is a multi-tenant logistics platform for trucking workflows. It manages shipment creation, driver assignment, load tracking, invoicing, reporting, and QuickBooks sync. The backend follows controller-service-repository layering with EF Core and SQL. Tenant context comes from authenticated claims/request context and resolves tenant-specific data access. Heavy work like invoice generation and external sync is handled through background jobs or queue-style processing so APIs stay responsive.
```

## Create Shipment Flow

```text
Request -> JWT authentication -> tenant/user context -> controller -> service validation/business rules -> repository -> EF Core -> SaveChangesAsync -> activity logging -> typed response.
```

Edge cases to mention:

- Validation should not bloat controllers.
- Pagination needs max limits.
- Double SaveChanges can add overhead unless intentional.
- Audit logging needs an explicit reliability decision.
- Tenant context must be available in background jobs.

## Multi-Tenancy

Flow:

```text
JWT tenant claim -> authentication -> request context -> tenant-aware factory -> tenant connection -> DbContext cached per request.
```

Benefits:

- Strong isolation.
- Smaller blast radius.
- Per-tenant restore/scaling possible.

Tradeoffs:

- Migration orchestration.
- Connection pool pressure.
- Cross-tenant reporting.
- Background job tenant safety.
- Secret/key management.

Strong close:

```text
Database-per-tenant gives strong isolation, but the complexity moves into migrations, connection management, cross-tenant reporting, and operational tooling.
```

## Performance Story

Say:

```text
I reduce unnecessary DB and memory work: projection with Select, filtering before materialization, AsNoTracking for reads, pagination limits, indexes on filter/join columns, and avoiding N+1. I verify with generated SQL or execution plans where possible.
```

## Background Processing Story

Say:

```text
Slow or retryable work should not block the API request. A request can enqueue work, return quickly, and a worker can process with retries, logging, monitoring, and idempotency.
```

Edge cases:

- Retry can duplicate external side effects.
- Tenant context cannot be assumed in a worker.
- Failures need dead-letter/retry visibility.

## Honest Safety Lines

- "I worked around this flow and can explain the architecture and tradeoffs."
- "For the exact piece I did not own end-to-end, I will separate what I implemented from what I understand."
- "My understanding is flow, reason, and tradeoff: here is how it behaves and what I would watch for."

## Questions To Ask

- What are the biggest backend reliability challenges in this product?
- How do you handle observability for APIs and background jobs?
- How are migrations managed across environments?
- What does ownership look like for a developer in the first 90 days?
