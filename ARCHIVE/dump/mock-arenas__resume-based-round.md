# Mock Interview: Resume-Based Round

## 1. Tell Me About Yourself

Expected answer:

```text
Clear role positioning, current company, tech stack, project domains, strongest area.
```

Weak answer:

```text
My name is Rajesh and I know .NET and React.
```

Strong answer:

```text
I am Rajesh Pareek, a software developer with hands-on experience across ASP.NET Core, EF Core, SQL, React, React Native, and Azure DevOps. At In Time Tec I have worked on SaaS/logistics workflows including REST APIs, shipment and driver features, multi-tenant backend systems, SQL performance, background jobs, and web/mobile integration. My strength is backend/product engineering: understanding flow, tradeoffs, and production behavior.
```

## 2. Explain RollOnDispatch

Strong answer:

```text
RollOnDispatch is a logistics platform for trucking workflows. It manages shipment creation, driver assignment, load status, invoicing, reporting, and QuickBooks sync. The backend follows controller-service-repository layering with EF Core and SQL. Tenant context is resolved per request, and heavier work is handled through background jobs/queue-style processing.
```

## 3. What Exactly Did You Work On?

Expected answer:

```text
Be specific and honest: APIs, validation, integration, performance, debugging, support.
```

Strong answer:

```text
I worked around API and product workflows such as shipment/driver-related features, validation, integration with frontend/mobile clients, query behavior, and production-style debugging. For areas I did not fully own, I can still explain the architecture and integration points because I worked around those flows.
```

## 4. Explain a Backend API You Built

Strong answer:

```text
For a create/update workflow, the request reaches the controller, model binding maps the DTO, the service validates and applies business rules, repository persists via EF Core, SaveChangesAsync commits, and the API returns a typed response. Cross-cutting concerns like auth, exception handling, and logging are handled outside the controller.
```

## 5. What Performance Improvement Did You Make?

Strong answer:

```text
The main pattern was reducing unnecessary DB and memory work: pagination, projection with Select, avoiding early ToList, using AsNoTracking for reads, checking indexes on filter/join columns, and avoiding N+1 query patterns. The idea is to push work to SQL and fetch only what the screen/API needs.
```

## 6. Explain Multi-Tenancy From Your Resume

Strong answer:

```text
Tenant identity comes from authenticated claims and flows into a scoped request context. Tenant-aware services use that TenantId to resolve the correct tenant database/connection and create a DbContext for that request. This gives strong isolation, but migrations, connection pooling, cross-tenant reporting, and background job context must be handled carefully.
```

## 7. What Is Your Strongest Backend Concept?

Strong answer:

```text
I am strongest at explaining API request flow and data access performance: how middleware/auth/model binding/controller/service/repository/EF Core work together, and how to avoid common production issues like blocking async calls, N+1 queries, missing pagination, and weak exception handling.
```

## 8. What Would You Improve In Your Project?

Strong answer:

```text
I would enforce pagination limits, add optimistic concurrency where conflicts matter, strengthen tenant validation before DB access, make background jobs explicitly idempotent, improve migration orchestration across tenant databases, and ensure logs/metrics make failures easy to diagnose.
```

## 9. React Native Resume Question

Strong answer:

```text
On React Native/mobile, I worked with TypeScript, navigation, API integration, Redux-style state management, secure storage, push notifications, geolocation/timezone flows, document/image handling, and offline-aware workflows. The main challenge is keeping UI state, API state, and network failures predictable.
```

## 10. When You Do Not Know Something

Use:

```text
I have not implemented that exact piece end-to-end, but my understanding is...
```

Then answer with:

```text
Flow -> reason -> tradeoff
```

