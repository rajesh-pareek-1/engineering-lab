# Fundamentals

## Introduce yourself

I am Rajesh Pareek, a software developer with hands-on experience across ASP.NET Core, EF Core, SQL, React, React Native, and Azure DevOps. I have worked on SaaS/logistics workflows involving REST APIs, shipment and driver features, multi-tenant backend systems, SQL performance, background jobs, and web/mobile integration. My strength is backend/product engineering: understanding flow, tradeoffs, and production behavior.

## Positioning

- Backend role: strongest in ASP.NET Core APIs, EF Core, SQL, background processing, auth, multi-tenant workflows.
- Full stack role: can own UI -> API -> service -> database flow.
- Mobile/frontend role: React Native, TypeScript, API integration, navigation, secure storage, offline-aware flows.

## Answer template

Definition -> project example -> tradeoff -> what I would improve.

# Frequently Asked Questions

## Tell me about yourself

Use the introduction above. Keep it under 45 seconds. End with backend/product engineering strength.

## Explain RollOnDispatch

RollOnDispatch is a multi-tenant logistics platform for trucking workflows: shipment creation, driver assignment, load tracking, invoices, reports, and QuickBooks sync. Backend uses controller-service-repository layering with EF Core and SQL. Tenant context comes from authenticated claims/request context. Heavy work uses background jobs/queue-style processing.

## What exactly did you work on?

I worked around shipment/driver APIs, validation, frontend/mobile integration, query behavior, production-style debugging, and performance improvements. For parts I did not own end-to-end, I separate what I implemented from what I understand.

## Strengths

API/data-flow thinking, debugging across frontend/backend/database, explaining tradeoffs clearly, and improving performance by reducing unnecessary work.

## Weakness

I am still deepening larger-scale distributed systems/cloud operations. I compensate by making tradeoffs explicit, validating behavior with logs/metrics, and preferring simpler reliable designs first.

# Production Scenarios

## Debugging story

Hard bugs are usually data-flow/integration bugs: stale UI state, query fetching too much, background retry duplicates, or missing tenant context. Approach: reproduce, trace request/correlation ID, inspect payload/generated SQL/logs, isolate layer, fix root flow, add guard/test/log.

## Conflict handling

I clarify the shared goal, separate facts from assumptions, show tradeoffs, and propose a small reversible step. If I am wrong, I update quickly.

## Production incident

State impact first, contain issue, identify affected users/tenants, check logs/metrics, roll back or hotfix, communicate status, and write a prevention note afterward.

## Scaling story

First reduce waste: pagination, projection, indexes, caching, async I/O, queues. Then scale stateless API horizontally. Avoid adding distributed complexity before measuring bottleneck.

## Leadership example

Ownership means making the flow understandable, communicating risk early, helping unblock adjacent frontend/backend work, and leaving the system easier to operate.

# Performance Concepts

- Strong performance answer: reduce DB rows/columns, avoid N+1, use `AsNoTracking`, paginate, index, cache hot reads, move slow work to background jobs.
- Strong mobile performance answer: stable keys, FlatList virtualization, memoized rows, avoid heavy JS work, test release builds.
- Strong production answer: measure first, inspect logs/metrics/SQL plan, fix bottleneck, add monitoring.
- Tradeoff language matters: "This improves X, but risks Y."

# Edge Cases

- Do not overclaim ownership. Separate built/worked-around/understood.
- Avoid dictionary definitions. Always add production reason.
- If you do not know: state what you know, infer carefully, and say how you would verify.
- If asked about a weak area: be honest, then show learning method.
- If challenged on project details: answer flow, reason, tradeoff.
- If asked for numbers you do not remember: avoid fake precision; explain direction and validation method.

# Tricky Questions

## Did you personally build this?

I worked on parts of this flow directly and worked around the full system enough to explain the architecture and tradeoffs. For the exact piece I did not own end-to-end, I will separate what I implemented from what I understand.

## Why should we hire you?

I can connect backend API design, EF/SQL performance, production debugging, and frontend/mobile integration. I am practical: I explain tradeoffs, reduce unnecessary complexity, and focus on reliable delivery.

## Why leave/current motivation?

I am looking for stronger backend/product ownership, deeper production engineering exposure, and a team where I can keep growing in API design, data performance, and scalable systems.

## What would you improve in your project?

Pagination limits, optimistic concurrency where conflicts matter, stronger tenant validation, explicit job idempotency, migration orchestration for tenant DBs, and better observability for APIs/background jobs.

## Hardest bug?

Integration/data-flow bugs: API looks correct but UI state is stale, generated SQL is inefficient, tenant context is missing, or background retry duplicates work. I debug by tracing the flow end-to-end.

# Syntax Refreshers

## 30-second RollOnDispatch

RollOnDispatch is a multi-tenant logistics platform for trucking workflows. It handles shipment creation, driver assignment, load tracking, invoicing, reporting, and QuickBooks sync. I worked around backend APIs, validation, data access, performance, background processing, and web/mobile integration.

## 90-second project pitch

RollOnDispatch manages trucking/livestock logistics workflows across tenants. The backend follows controller-service-repository layering with EF Core and SQL. Authenticated claims provide tenant/user context, and tenant-aware data access resolves the correct database. Shipment and driver workflows use validation, DTOs, async EF calls, and activity logging. Slow or retryable work like invoice generation and QuickBooks sync is moved to background jobs/queue-style processing. Main tradeoffs are tenant isolation vs migration/connection/reporting complexity, and background reliability vs duplicate side effects.

## Safe ownership line

I did not implement that exact piece end-to-end, but I worked around the flow and understand the integration points, behavior, and tradeoffs.

# Real Project Examples

## REST API

Controller receives DTO, service validates and applies business rules, repository persists through EF Core, `SaveChangesAsync` commits, response returns typed result. Cross-cutting concerns like auth, logging, and exceptions stay outside controller.

## Multi-tenancy

JWT tenant claim -> request context -> tenant-aware factory -> tenant DB connection -> request-cached DbContext. Benefit: isolation. Tradeoff: migrations, connection pools, reporting, background jobs.

## Background jobs

Invoice/report/QuickBooks sync can be slow or unreliable. Enqueue work, return quickly, process with retry/logging/monitoring, keep operations idempotent and tenant-safe.

## SQL/EF optimization

Projection with Select, filter before materialization, `AsNoTracking`, pagination, indexes, avoid N+1, inspect generated SQL/plan.

## React Native

API-driven mobile workflows with TypeScript, navigation, state/API sync, secure storage, push/geolocation/timezone/document features, and offline-aware behavior. Main challenge: predictable state under network/device differences.

# 30-Minute Rapid Revision

1. Say intro once.
2. Say RollOnDispatch 30-second and 90-second versions.
3. Say multi-tenancy flow.
4. Say performance story.
5. Say background jobs story.
6. Say hardest bug/debugging story.
7. Say weakness answer.
8. Say "did you personally build this?" answer.
9. Prepare 3 interviewer questions.
10. Stop reading and speak.

# Questions To Ask Interviewer

- What are the biggest backend reliability challenges in this product today?
- How do you handle observability for APIs and background jobs?
- How do you manage database migrations and deployments?
- What would success look like in the first 90 days?
- Where can a developer take real ownership early?
