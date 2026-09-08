# High-End Topic 02 — ROD Backend Architecture

> **Goal:** Explain the architecture in 90 seconds, then trace one request through real files and discuss trade-offs like an engineer—not a folder-tour guide.

---

## Architecture in one sentence

> **“ROD is a modular ASP.NET Core application: controllers expose HTTP endpoints, services own business rules, repositories isolate EF Core data access, and tenant-aware context creation connects every business query to the correct customer SQL database.”**

```text
React web / React Native driver app
        ↓ HTTP + JWT
ASP.NET Core middleware pipeline
        ↓
Controllers       = transport / HTTP boundary
Services          = business workflows and rules
Repositories      = persistence/query boundary
EF Core contexts  = global or tenant SQL connection
        ↓
SQL Server + Azure integrations + Hangfire
```

---

## 1. What architecture is this?

```text
Primary shape: layered modular monolith

Not: a collection of independently deployed microservices
Not: pure Clean Architecture with strict project names Core/Application/Infrastructure

It is a single deployable ASP.NET Core application
with clear modules and responsibilities.
```

```text
ROD logistics module
├── Controllers / Services / Data
├── shipment, driver, trailer, attachment, notifications
└── tenant-aware operational database

Tenant Management module
├── identity, users, roles, accounts, subscription, provisioning
├── global database
└── shared tenancy/authentication infrastructure
```

Why this works for ROD:

```text
one domain-heavy product
shared deployment and database infrastructure
many related workflows: dispatch, driver data, documents, billing
need for consistent tenant context, authentication, jobs, auditing
```

---

## 2. Solution/folder map

```text
dm-api/
├── RollOnDispatch/                 API host and application layer
│   ├── Controllers/                HTTP endpoints
│   ├── Services/                   business use cases
│   ├── Models/                     request/response DTOs
│   ├── Validations/                input rules
│   ├── Extensions/                 DI registrations
│   ├── ApiKeyAuth/                 API-key authentication handler
│   ├── EmailTemplates/             server-side templates/assets
│   └── Startup.cs                  middleware + auth + Hangfire composition
│
├── RollOnDispatch.Data/            tenant business-data layer
│   ├── Entities/                   EF Core persistence entities
│   ├── Configurations/             Fluent EF mapping/indexes
│   ├── Repositories/               query and persistence abstractions
│   ├── Migrations/                 tenant-schema EF migrations
│   └── RollOnDispatchContext.cs    tenant business DbContext
│
├── TenantManagement/               shared/global platform module
│   ├── Common/                     RequestContext, jobs, permissions, exceptions
│   ├── Controllers/                tenant/account/auth endpoints
│   ├── Services/                   auth, provisioning, billing, email
│   ├── Data/                       AppGlobalContext + global repositories/entities
│   ├── Models/                     global-domain DTOs
│   ├── Extensions/                 global DI registration
│   └── Migrations/                 global-schema migrations
│
├── RollOnDispatch.Common/          shared constants, enums, helpers, exceptions
├── UnitTests/                      focused automated tests
├── WebApp.IntegrationTests/        HTTP/database integration coverage
└── RollOnDispatch.DataMigration/   migration-oriented application/tooling
```

---

## 3. Responsibilities — do not mix these up

| Layer             | Owns                                                                   | Should not own                                 |
| ----------------- | ---------------------------------------------------------------------- | ---------------------------------------------- |
| Controller        | HTTP route, model binding, status response, endpoint authorization     | SQL queries or substantial domain workflow     |
| Service           | business rules, orchestration, transaction boundary, integrations      | HTTP-specific mechanics or raw EF query sprawl |
| Repository        | EF Core query shape, persistence, includes, tracking decisions         | UI/HTTP behavior or business-policy decisions  |
| Entity            | persisted domain data and relationships                                | API response formatting                        |
| DTO/Model         | request/response contract                                              | EF persistence behavior                        |
| DbContext factory | chooses correct tenant database/context                                | business workflow                              |
| Middleware        | cross-cutting pipeline concern                                         | feature-specific business logic                |
| Global module     | identity, tenancy, permissions, subscription/integration configuration | tenant dispatch records                        |

Memory line:

```text
Controller receives → Service decides → Repository persists → Context isolates
```

---

## 4. The two database contexts

```text
AppGlobalContext
├── Tenants, Users, Accounts, AccountUsers
├── Roles, Permissions, Scopes
├── subscription/integration/message configuration
└── Hangfire SQL storage connection

RollOnDispatchContext
├── shipments, driver loads, associates/drivers
├── trailers, attachments, settings
└── tenant operational records
```

`ITenantDbContextFactory` is the boundary between request identity and tenant business data:

```text
validated JWT claim
        ↓
IRequestContext.TenantId
        ↓
ITenantDbContextFactory
        ↓
RollOnDispatchContext connected to that tenant SQL database
```

---

## 5. Real request path — `POST /api/Trailer`

```text
Client
  POST /api/Trailer
  Authorization: Bearer <JWT>
        ↓
RollOnDispatch/Startup.cs
  UseRouting → UseAuthentication → UseAuthorization → UseEndpoints
        ↓
RollOnDispatch/Controllers/TrailerController.cs
  TrailerController.Add(TrailerModel)
        ↓
RollOnDispatch/Services/TrailerService.cs
  TrailerService.AddTrailer(...)
  validates duplicate/driver assignment workflow
  opens TransactionScope
        ↓
RollOnDispatch.Data/Repositories/TrailerRepository.cs
  inherits CrudBaseRepository<Trailer>
        ↓
RollOnDispatch.Data/Repositories/CrudBaseRepository.cs
  constructor calls _contextFactory.DbContext<RollOnDispatchContext>()
        ↓
TenantManagement/Data/TenantDBContextFactory.cs
  reads IRequestContext.TenantId
  creates tenant-specific UseSqlServer options
        ↓
tenant SQL database
  AddAsync(Trailer) → SaveChangesAsync()
```

Important nuance:

> `RequestContext` is a scoped DI object, not a middleware. It is created when a dependent component needs it, after authentication has already populated `HttpContext.User`.

---

## 6. Dependency injection and composition root

`Startup.ConfigureServices` is the composition root. It registers controllers, services, repositories, global context, authentication, Hangfire, HTTP clients, feature flags, and external integrations.

```text
Interface                 Implementation              Lifetime intent
IRequestContext       →  RequestContext               scoped/request or job scope
ITenantDbContextFactory → TenantDbContextFactory      scoped
ITrailerService       →  TrailerService               scoped
ITrailerRepository    →  TrailerRepository            scoped
```

Why interface-based DI:

```text
service depends on capability, not concrete class
→ easier unit testing with mocks
→ implementation can change behind interface
→ dependencies are visible in constructor
```

---

## 7. Cross-cutting concerns and where they live

| Concern           | ROD mechanism                                                          |
| ----------------- | ---------------------------------------------------------------------- |
| Authentication    | JWT bearer setup in`Startup`; auth service creates signed tokens     |
| Authorization     | `[Authorize]`, roles, permission context/custom authorization        |
| Tenant isolation  | `RequestContext` + `ITenantDbContextFactory`                       |
| Errors            | exception handling plus controller/API exception mapping               |
| Logging           | HTTP/request/error logging and`ILogger<T>`                           |
| Background work   | Hangfire SQL storage, filter, custom job activator                     |
| Transactions      | `TransactionScope` around multi-step business updates where used     |
| Feature rollout   | `Microsoft.FeatureManagement` feature flags                          |
| External services | email providers, Azure Blob/notifications, ChargeBee, QuickBooks, maps |

---

## 8. Why choose this architecture?

```text
Layering
→ makes feature flow readable and testable.

Modular monolith
→ avoids distributed-system overhead while ROD modules still share transactions,
  tenant context, auth, and deployment lifecycle.

Repository boundary
→ avoids EF Core code leaking across every service/controller.

Tenant factory
→ prevents controllers from picking databases using UI input.
```

### Advantages

```text
clear test seams: controller/service/repository
business rules are not buried in endpoints
EF Core access is centralized
tenant isolation is applied before repository queries
single deployable is simpler to debug and release
modules can evolve independently inside the solution
```

### Trade-offs

```text
more files and interfaces for simple CRUD
generic repositories can hide query/performance details if overused
cross-module dependencies can grow in a large monolith
database-per-tenant adds migration/provisioning operations
```

---

## 9. Other architecture options

| Option                        | When it fits                                    | Why not automatically better here                                                   |
| ----------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| Simple controller + DbContext | tiny CRUD service                               | business rules and tenant handling become scattered                                 |
| Vertical slices/CQRS          | complex independent use cases                   | adds conventions/handlers; only worth it when complexity needs it                   |
| Clean/Hexagonal architecture  | long-lived domain with many adapters            | strong boundary, but extra abstractions can be costly                               |
| Microservices                 | independently scaling/deployed bounded contexts | brings network failure, observability, versioning, and distributed-transaction cost |
| Event-driven microservices    | high-volume decoupled async domains             | needs idempotency, outbox, retries, monitoring, eventual-consistency design         |

Strong answer:

> “Microservices are not an upgrade from a modular monolith by default. I would split only around a clear independent bounded context with separate scaling, release, ownership, or reliability needs.”

---

## 10. How I would improve it without blaming it

```text
1. Make tenant-context absence fail explicitly for business-data access.
2. Add consistent ProblemDetails/global exception mapping for every endpoint.
3. Keep query-specific read models close to complex report/query use cases.
4. Add OpenTelemetry traces across controller → service → repository → SQL/external call.
5. Use an outbox pattern when a SQL change must reliably trigger external work.
6. Keep module boundaries explicit as the monolith grows.
```

---

## 11. 90-second spoken answer

> “ROD is a modular ASP.NET Core application organized around layered responsibilities. Controllers are the HTTP boundary, services own business workflows, and repositories own EF Core persistence and query behavior. The main business module is RollOnDispatch, while TenantManagement owns global concerns such as users, tenants, roles, permissions, subscription, and provisioning.
>
> The important architectural detail is tenant-aware data access. After JWT authentication, `RequestContext` extracts tenant identity from trusted claims. `ITenantDbContextFactory` uses it to construct the tenant’s `RollOnDispatchContext`, so repositories query the correct customer SQL database without trusting a tenant ID from the client.
>
> It is a modular monolith rather than microservices. That keeps deployment, transactions, tenant context, and debugging simpler while the dispatch workflows remain tightly related. If a module later needed truly independent scaling and release ownership, I would evaluate extracting it behind an API or asynchronous contract.”

---

## Rapid cross-questions

| Question                                        | Answer                                                                                                                                                                                                   |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Why not put business logic in controller?       | Controllers should remain transport-focused; services make workflows reusable, testable, and independent of HTTP.                                                                                        |
| Why use repositories if EF Core already is one? | EF Core is a unit-of-work/repository-like abstraction, but project repositories centralize query behavior and prevent persistence logic spreading through services. Do not over-abstract simple queries. |
| Where should transaction live?                  | At the service/use-case boundary when one business operation changes multiple records. Keep it short and do not assume it rolls back Blob/email/external calls.                                          |
| Where does tenant selection occur?              | In`ITenantDbContextFactory`, using trusted `IRequestContext.TenantId`.                                                                                                                               |
| How is backend tested?                          | Unit tests isolate service rules with mocks; integration tests exercise controllers/auth/database behavior.                                                                                              |
