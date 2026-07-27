# 10. Mock Interview, HR Answers, and Rapid Revision

## Two-to-three-hour reading plan

| Time | Sheet | Goal |
|---:|---|---|
| 15 min | 1 | Say introduction aloud three times |
| 25 min | 2 | Master Roll On Dispatch and both hero stories |
| 15 min | 3 | Understand Feedlot Manager and multi-tenancy |
| 20 min | 4 | C# rapid questions |
| 15 min | 5 | OOP, SOLID, DI, architecture |
| 20 min | 6 | Web API request flow and status codes |
| 20 min | 7 | EF Core, LINQ, async |
| 25 min | 8 | SQL, indexes, transactions |
| 15 min | 9 | JWT, Hangfire, tests, logs, CI/CD |
| 10 min | 10 | Final mock and calm reset |

## The answer engine: **H-E-A-R-T**

Use this whenever surprised:

1. **H - Headline:** answer the question immediately.
2. **E - Explain:** give the core principle.
3. **A - Apply:** connect to your project or a small example.
4. **R - Risks:** mention one trade-off/failure case.
5. **T - Tie back:** conclude with the decision.

Example: **What is a transaction?**

> A transaction makes related database changes one atomic unit. It commits all changes or rolls them back on failure, while isolation controls concurrent interaction. In a cattle-movement workflow, source count, destination count, and history should commit together. I keep transactions short because long transactions increase locks and contention. So I place the transaction around the business operation, not around unrelated network calls.

## High-priority questions from the recent first round

### 1. Explain your project architecture, layers, and domain

> Roll On Dispatch is a layered modular monolith. React and mobile clients call authenticated REST APIs. Controllers form the HTTP/presentation layer and work with request and response DTOs. Services and helpers form the application/business layer and coordinate shipment, driver-load, attachment, invoice, and notification workflows. Repositories and EF Core form the data-access layer over SQL Server. Shared enums, exceptions, and utilities are in the common project, while TenantManagement handles tenants, users, roles, and related services. Blob storage, Hangfire, notifications, messaging, and QuickBooks are infrastructure integrations connected through dependency injection.
>
> The domain is logistics and dispatch: shipments, customers and brokers, drivers, driver loads, cargo, trailers, locations, documents, status transitions, billing, and tenant-specific operations. Business rules belong in services/domain behavior rather than controllers or clients.

Follow-ups:

- Why layered architecture? Separation of concerns, testability, focused change, and understandable dependencies.
- Is it strict Clean Architecture? It uses several principles, but I describe it honestly as layered architecture/modular monolith rather than claiming textbook conformance.
- DTO vs entity? DTO is the API contract; entity is persistence state; domain behavior expresses rules/invariants.

### 2. Explain one or two design patterns used in the project

> One is Strategy Pattern. Tenant management has email providers such as Twilio and Azure behind `IEmailIntegration`. The email orchestration service can work through the common contract while the selected provider performs the actual sending. This isolates provider behavior, improves testing, and allows another provider without rewriting callers. The current selection uses concrete-type lookup; a cleaner evolution would select by provider key or `CanHandle` capability.
>
> The second is Repository Pattern. Services depend on repository interfaces for shipments, driver loads, and attachments rather than containing EF Core queries. Repositories encapsulate domain-focused persistence operations, tenant-aware queries, and includes/projections, creating a consistent test seam. I avoid repositories that only copy every `DbSet` method because EF Core already provides repository/unit-of-work behavior.

Follow-ups:

- Strategy vs Factory? Strategy performs interchangeable behavior; Factory creates/selects an object and may choose a strategy.
- Strategy benefit? Removes large conditionals, isolates changes, supports testing and extension.
- Pattern disadvantage? Extra abstractions and types; use only when variability is real.

### 3. Explain DI and “program to interface”

> Dependency injection means a class receives dependencies through its constructor instead of constructing concrete dependencies. In ROD, a service receives interfaces such as `IShipmentRepository` or `IEmailIntegration`, and ASP.NET Core's container selects the implementation and lifetime. Benefits are lower coupling, clear dependencies, easy mocking in unit tests, swappable providers, and centralized lifetime management.
>
> “Program to an interface” means depend on the capability required rather than one implementation. A reminder service should depend on `IEmailIntegration`, not instantiate `TwilioEmailService`. The composition root decides the provider. I do not create an interface for every class—only at meaningful boundaries or when it adds flexibility/testability.

Follow-ups:

- Lifetimes? Transient creates per resolution, scoped per request/scope, singleton for application lifetime.
- Why scoped `DbContext`? It is a non-thread-safe unit of work and change tracker.
- DI disadvantage? Excessive interfaces, hidden service-locator usage, or huge constructors can make design worse.

### 4. Explain EF Core

> EF Core is Microsoft's cross-platform ORM for .NET. It maps C# entities and relationships to relational tables, translates LINQ expression trees into parameterized SQL, tracks entity states, persists changes through `SaveChanges`, and manages schema evolution through migrations. In ROD it is used with SQL Server through repositories for shipments, driver loads, attachments, users, and tenant-aware data.
>
> Its benefits are productivity, type-safe queries, relationship mapping, change tracking, async operations, parameterization, and migrations. It does not remove the need for SQL knowledge: I still inspect generated SQL and execution plans, use projection and `AsNoTracking`, avoid N+1 queries, paginate, and design indexes.

Follow-ups:

- Tracking vs no tracking? Tracking supports updates; `AsNoTracking` reduces overhead for reads.
- `IQueryable`? Expression composed for provider translation, usually SQL.
- One `SaveChanges` transaction? Yes, its generated database commands are transactional by default.
- Eager vs lazy? Eager explicitly loads relationships; lazy loads on access and can cause N+1.

### 5. What are the benefits of Repository Pattern?

> Repository isolates persistence details from business services, centralizes meaningful queries, supports consistent tenant filtering/includes/projections, creates an interface for unit-test mocks, and localizes persistence changes. The service describes what the use case needs; the repository describes how data is obtained or saved.
>
> The trade-off is extra abstraction. `DbSet` and `DbContext` already resemble repository and unit-of-work patterns, so a custom repository should add domain-specific value rather than simply wrapping every EF Core method.

Mnemonic: **P-T-R-C** - Persistence isolation, Test seam, Reusable queries, Centralized change.

### 6. What is GraphQL?

> GraphQL is a typed API query language and execution model. The server exposes a schema; clients use queries to request selected fields, mutations to change state, and optionally subscriptions for real-time updates. Resolvers fetch each field's data. It can reduce over-fetching and serve different web/mobile data shapes through one schema.
>
> I have mainly worked with REST rather than production GraphQL. I understand its important challenges: naive resolvers can create N+1 database queries, so batching/DataLoader and projection matter; nested queries need complexity/depth limits; authorization must be enforced at the resolver/resource level; and caching and monitoring require deliberate design. ROD could use it for flexible shipment views, but I would adopt it only if that flexibility justifies the complexity.

Follow-ups:

- GraphQL vs REST? Client-selected schema fields versus server-defined endpoint responses.
- One GraphQL request equals one SQL query? No; naive resolvers can perform many queries.
- Query vs mutation? Query reads; mutation changes state.
- Does GraphQL replace authorization? No.

### 7. Middleware versus filters

> Middleware runs in the general ASP.NET Core HTTP pipeline and can handle requests before MVC is selected. It receives `HttpContext`, can call the next middleware, execute logic after it returns, or short-circuit. I use middleware for application-wide concerns such as exception handling, correlation IDs, request logging, authentication, CORS, and rate limiting.
>
> Filters run inside the MVC/controller pipeline and have action-specific context such as controller metadata, action arguments, model state, and the action result. I use an action filter when behavior must understand a particular controller action, and a result filter when it must wrap MVC result execution.

Mnemonic: **G-A** - Global HTTP concern uses middleware; Action-aware MVC concern uses a filter.

Follow-ups:

- Pipeline order? Exception handling early; routing; authentication; authorization; endpoints.
- Can middleware short-circuit? Yes, return without calling `_next`.
- Can a filter short-circuit? Yes, set `context.Result`.
- Why exception middleware over exception filter? It catches a wider set of downstream failures, including those outside MVC action execution.
- Filter types? Authorization, resource, action, exception, and result filters.
- Scoped service in middleware? Inject into `InvokeAsync` for conventional middleware or use `IMiddleware` activation.

## Mock interview

### 1. Tell me about yourself.

Use Sheet 1's 90-second answer. End with backend ownership, not education.

### 2. Explain your strongest project.

> My strongest project is Roll On Dispatch, a multi-tenant logistics platform built with .NET 8, ASP.NET Core, EF Core, and SQL Server. It supports shipments, drivers, loads, documents, and mobile workflows. My concrete contributions include driver-load attachment consistency and document-expiry reminder logic. These taught me to reason about database transactions, external blob operations, background jobs, idempotency, and structured logs.

### 3. Explain one feature end to end.

> For document-expiry reminders, a scheduled Hangfire job starts with tenant context, queries eligible active driver documents, evaluates the expiry window, and builds the notification. Before sending, it should check an idempotency record to avoid duplicates. It sends through the notification service, records the outcome, and logs tenant, document, job, and error context. Transient failures retry; permanent invalid data is logged and skipped or handled separately.

### 4. Why did you use a transaction for attachments?

> The related SQL changes needed all-or-nothing behavior. However, I understand that SQL transactions do not include Azure Blob Storage, so the full workflow also needs compensation, pending/completed state, idempotency, or reconciliation to address partial failure.

### 5. What happens when an API request arrives?

> It passes through middleware, routing selects the endpoint, authentication creates the principal, authorization checks access, model binding creates the DTO, validation runs, and the controller invokes the service. The service applies business rules and uses EF Core/SQL Server. The result is serialized into an HTTP response, with centralized error handling and structured logging.

### 6. Explain dependency injection and lifetimes.

> DI supplies dependencies externally and makes coupling explicit. Transient creates each time, scoped normally creates once per request, and singleton lives for the application. `DbContext` is scoped because it is a non-thread-safe unit of work. A singleton must not capture it.

### 7. Explain `IEnumerable` vs `IQueryable`.

> `IEnumerable` executes LINQ in .NET over objects. `IQueryable` builds an expression a provider such as EF translates into SQL. I filter, sort, and project while it is queryable, then materialize once asynchronously.

### 8. How do you optimize a slow API?

> I measure the endpoint and dependencies, inspect EF-generated SQL and the actual execution plan, check row counts and indexes, remove N+1 queries, project required columns, use no-tracking reads and pagination, reduce round trips, and retest with representative parameters.

### 9. Explain JWT authentication.

> The API validates the token's signature, issuer, audience, and expiry, builds a claims principal, then authorization evaluates roles or policies. JWT payload is readable, so it must not contain secrets. Access tokens should be short-lived and refresh tokens securely rotated and revocable.

### 10. What is multi-tenancy?

> One application serves multiple organizations while isolating data and configuration. Resolve the tenant from trusted authenticated context, apply isolation to queries, repositories, caches, background jobs, and logs, and still authorize access to each resource.

### 11. Why Hangfire?

> It provides persistent scheduling, background execution, retries, and visibility. Jobs must be tenant-aware, idempotent, and observable because delivery can be at least once.

### 12. Unit test vs integration test?

> Unit tests isolate business behavior and are fast. Integration tests exercise real framework wiring and persistence behavior. I use both; for EF query semantics I prefer the actual relational provider over pretending with mocks.

### 13. What is SOLID?

> Five principles for change-friendly object design: one reason to change, extend without repeatedly modifying stable code, preserve substitutability, keep interfaces focused, and depend on abstractions. I apply them pragmatically, not as a rule that every class needs an interface.

### 14. Explain an index.

> An index is an ordered structure that can make filtered and sorted reads efficient. The trade-off is storage and write cost. Column order and included columns should match measured queries, verified through execution plans.

### 15. What did you do in CI/CD?

> I contributed to Dockerized deployment and Azure DevOps pipeline/release validation. A typical pipeline restores, builds, tests, publishes an artifact/image, deploys through environments, runs health checks, and uses approval and monitoring for production. I would not claim sole ownership if I only contributed.

## Resume pressure questions

### You listed PostgreSQL. Explain your experience.

> I need to correct that entry. My hands-on work on these projects used SQL Server; PostgreSQL was added by mistake while tailoring the resume. My real strength is EF Core and relational/SQL Server work. I understand that relational concepts transfer, but I would learn PostgreSQL-specific behavior before claiming proficiency.

### Did you build the entire architecture?

> No. I worked within and contributed to the existing layered, multi-tenant architecture. I can explain how my features flowed through it and the principles involved, but I do not claim sole authorship of the platform architecture.

### Did you personally serve 500+ users?

> That number describes the product's user scale, not a feature I alone delivered. My contribution was maintaining backend workflows used within that product.

### Did you implement OAuth?

> My direct work was mainly within JWT-based authentication and authorization in the existing system. I understand OAuth and OpenID Connect concepts, but I would not claim that I built an authorization server unless I had done so.

### Did you implement Serilog or Application Insights from scratch?

> I used the project's logging and monitoring approach and added diagnostic context around workflows. I distinguish using and contributing to observability from designing the entire setup.

## Resume boundary: frontend exposure and test frameworks

### JavaScript, TypeScript, React, and Redux Toolkit

> My role and strongest skills are backend-focused. I have frontend exposure through collaborating on and debugging API integrations with React or React Native clients, reading JavaScript/TypeScript code, understanding request models and state flows, and coordinating contract changes. I understand that React builds component-based interfaces and Redux Toolkit provides predictable centralized state management, but I would not present myself as a specialist frontend developer.

If asked for the frontend-to-backend flow:

```text
React component/event
  → Redux Toolkit async action or API client
  → HTTPS request with JWT
  → ASP.NET Core endpoint
  → response/error contract
  → store state updated
  → component re-renders
```

Cross-question: **Why TypeScript instead of JavaScript?**

> TypeScript adds static type checking and tooling over JavaScript, which helps catch contract and refactoring mistakes earlier. It still compiles to JavaScript for execution.

Cross-question: **What did you personally do with React/Redux?**

> My direct contribution was primarily backend API support and integration debugging. I could follow the client request and state flow to diagnose contract issues, but I would not claim ownership of the frontend architecture unless discussing a specific change I made.

### xUnit and NUnit

> Both xUnit and NUnit are .NET testing frameworks. The core testing concepts are the same: arrange, act, assert; setup/fixtures; parameterized tests; and isolated, deterministic behavior. In the repository, Roll On Dispatch integration tests use xUnit, while some project tests also use other test frameworks. I focus on writing maintainable tests rather than claiming deep framework-specific expertise in every named framework.

- xUnit commonly uses `[Fact]` and `[Theory]`.
- NUnit commonly uses `[Test]` and `[TestCase]`.
- Mocks such as Moq isolate external collaborators when appropriate.
- Integration tests use the real application pipeline and preferably realistic relational persistence.

## HR answers

### Why are you changing jobs?

> I am grateful for the product exposure I have received. I now want a role with deeper backend ownership, stronger design and code-review exposure, and opportunities to grow in API reliability and database engineering. I am moving toward growth, not away from a particular person or project.

### Your strength?

> My strength is tracing an operational issue end to end. I am comfortable moving from an API request through service logic and EF queries to database state and logs. I also try to be honest about what I know and systematic about what I need to learn.

### Your weakness?

> Earlier, I sometimes spent too long trying to make the first solution perfect. I now time-box investigation, confirm requirements and failure cases early, deliver the smallest safe change, and improve it using review and measurements.

### A mistake you made?

> Choose a real low-risk example. Explain the missed assumption, detection, correction, test/guard added, and lesson. Never blame a teammate and never invent a production disaster.

### Why should we hire you?

> I bring practical .NET backend experience in complex operational products, not only tutorial APIs. I understand request flows, tenant-aware data, transactions, background jobs, and production debugging. I can contribute at my current level, communicate honestly, and grow quickly under strong engineering practices.

## Thirty rapid-fire prompts

Answer aloud in one or two sentences:

1. Value vs reference type.
2. Class vs record.
3. `var` vs `dynamic`.
4. Boxing/unboxing.
5. Interface vs abstract class.
6. Encapsulation vs abstraction.
7. `throw` vs `throw ex`.
8. `IEnumerable` vs `IQueryable`.
9. Deferred execution.
10. `First` vs `Single`.
11. Tracking vs `AsNoTracking`.
12. N+1 problem.
13. `async`/`await` and threads.
14. Cancellation token.
15. Scoped vs singleton.
16. Middleware order.
17. `401` vs `403`.
18. `PUT` vs `PATCH`.
19. DTO vs entity.
20. JWT vs OAuth.
21. Authentication vs authorization.
22. Refresh-token rotation.
23. Clustered vs nonclustered index.
24. `WHERE` vs `HAVING`.
25. ACID.
26. Deadlock.
27. Optimistic concurrency.
28. Unit vs integration test.
29. Why Hangfire, not `Task.Run`?
30. Why a modular monolith?

## Final memory palace

Imagine entering a logistics office:

1. **Door:** introduction and JWT identity.
2. **Reception:** API middleware and routing.
3. **Manager desk:** service layer and SOLID.
4. **Filing cabinet:** EF Core and SQL Server.
5. **Locked drawer:** transaction and tenant isolation.
6. **Dispatch board:** Hangfire jobs and mobile sync.
7. **CCTV screen:** logs and Application Insights.
8. **Workshop:** unit and integration tests.
9. **Container truck:** Docker and CI/CD.
10. **Exit sign:** honest correction and questions for interviewer.

## Five-minute final revision

- Say **I-P-T-I-G** introduction.
- Say **S-DAT** Roll On Dispatch.
- Say **FARM-T** Feedlot Manager.
- Explain attachment consistency without claiming blob rollback.
- Explain reminder job with idempotency.
- Explain request → controller → service → EF → SQL → response.
- Say PostgreSQL correction calmly once.
- Breathe out, look at the interviewer, answer the headline first.

## Kratin rounds: final question-and-answer drill

### Lazy loading versus eager loading?

> Eager loading uses `Include` or projection to request known related data deliberately. Lazy loading automatically queries a navigation when it is accessed and can hide N+1 round trips. For APIs I normally prefer projection or deliberate eager loading.

### Explain architecture, layers, and domain.

> ROD is a layered modular monolith in the logistics domain. Clients call controllers; services coordinate shipment, driver-load, attachment, and notification use cases; repositories and EF Core access tenant-specific SQL databases; and Azure Blob, Hangfire, notifications, and QuickBooks are infrastructure integrations connected through DI.

### Explain Strategy Pattern.

> Strategy puts interchangeable behavior behind a shared interface. ROD has provider-style integrations behind abstractions. The caller depends on the contract, while configuration or a resolver chooses the implementation. It reduces conditional logic and improves testing.

### DI and program to an interface?

> A class receives dependencies instead of constructing them. Depending on `INotificationService` rather than an Azure class reduces coupling, makes unit testing easy, and lets composition choose the implementation. The interface should represent a meaningful capability, not exist only as ceremony.

### Explain EF Core.

> EF Core is a .NET ORM. `DbContext` is a unit of work and change tracker, `DbSet` represents an entity query root, LINQ expression trees translate to parameterized SQL, and `SaveChanges` persists tracked changes transactionally. I use projection and `AsNoTracking` for reads and inspect generated SQL for important queries.

### Repository advantages?

> It centralizes persistence and domain-specific queries, keeps services focused on use cases, and creates a test seam. The downside is that a generic wrapper can duplicate EF Core and hide useful query behavior.

### Design Student Documents for OCP without deployments.

> Store document types and field/validation definitions as data. `StudentDocument` references `DocumentType`; administrators add a type and its definitions without changing upload orchestration. Do not use an enum plus `if/else`. Add a strategy only when a genuinely new behavior, such as external verification, is required.

### How do you start a new REST API?

> Clarify actor, outcome, rules, scale, security, failure cases, and idempotency; model resources and cardinality; define DTOs, routes, verbs, and status codes; identify transaction and integration boundaries; then add validation, authorization, pagination, observability, tests, and rollout compatibility.

### Explain cardinality.

> Cardinality describes relationship counts: one-to-one, one-to-many, and many-to-many. A student has many uploaded documents; every document has one student and one document type; one document type can classify many documents. Foreign keys and unique constraints enforce the intended relationship.

### Clustered index and nonclustered disadvantage?

> A clustered index stores the rows at its leaf level and is useful for suitable key lookups and range scans; only one exists per table. A nonclustered index is a separate structure, consumes space, adds write cost, and may require key lookups when it does not cover the query. Index design must follow workload and execution plans.

### Explain the feature using STAR.

> Situation: drivers needed correct warnings for their latest expiring documents. Task: align selection, messaging, and failure handling with business rules. Action: select mobile drivers, filter associate attachments with expiry, group by type, choose the newest, isolate decision/message functions, handle grammar and `Other`, isolate driver failures, and add structured logs. Result: more correct, readable, and diagnosable reminders. Next: batch the N+1 query and add persistent idempotency.

### What does `LAG()` do?

> `LAG` returns a value from an earlier row in the window without a self-join. For yearly student performance I use `LAG(CurrentScore) OVER (PARTITION BY StudentId ORDER BY ExamYear)`, then subtract the previous score. It compares the previous available row; exact previous calendar year needs a calendar or year-to-year join when years are missing.

## Round 1 Master Drill: Asked Questions and Sharp Answers

### 1. Give a project introduction.

> Roll On Dispatch is a multi-tenant logistics platform for shipments, driver loads, drivers, trailers, documents, invoices, and mobile users. The core is an ASP.NET Core Web API with layered services and repositories, EF Core and SQL Server. It integrates Azure Blob Storage for files, Hangfire for background jobs, notifications, tenant-aware data access, and a React/React Native front end. My strongest work was around document attachments and expiry reminders, where I had to understand API flow, EF queries, storage consistency, notifications, logs, and mobile behavior end to end.

### 2. Authentication and authorization other than JWT?

| Mechanism | Best fit |
|---|---|
| Cookie authentication | Browser/server-rendered web app; browser sends secure cookie |
| OAuth 2.0 / OpenID Connect | Login/delegated access through identity provider |
| API key | Server-to-server/integration; rotate and scope it |
| Mutual TLS | Strong machine-to-machine identity using client certificates |
| Windows/Integrated auth | Internal enterprise/domain environments |

```text
Authentication = Who are you?
Authorization  = What may you do?
```

Authorization models:

```text
RBAC      → role: Dispatcher / Admin / Driver
Claims    → permission or tenant claim
Policy    → named requirement combining rules
Resource  → can this user access this specific shipment?
```

### 2a. Attribute/filter-based authorization?

```csharp
[Authorize(Roles = "Dispatcher")]
[HttpPost]
public IActionResult CreateShipment() => Ok();
```

> `[Authorize]` supplies endpoint authorization metadata. After authentication creates `HttpContext.User`, authorization checks the role, claim, or policy before the controller action runs. Invalid/missing identity is normally `401`; valid identity without permission is `403`.

Policy version:

```csharp
builder.Services.AddAuthorization(options =>
    options.AddPolicy("DispatchShipment", policy =>
        policy.RequireClaim("permission", "dispatch.shipment")));

[Authorize(Policy = "DispatchShipment")]
```

ROD-specific nuance:

> ROD also has `CustomAuthorize`, an MVC `IAuthorizationFilter`, which reads the user role and checks a permission service. Use the built-in policy system where possible; write a custom filter/requirement when the decision genuinely needs custom logic.

### 3. JWT setup: high-level flow and libraries

```text
Login credentials
 → server validates user
 → server creates signed JWT claims
 → client sends Authorization: Bearer <token>
 → JwtBearer middleware validates signature, issuer, audience, expiry
 → HttpContext.User is created
 → authorization checks endpoint policy/role
```

Packages/classes:

```text
Microsoft.AspNetCore.Authentication.JwtBearer
System.IdentityModel.Tokens.Jwt
Microsoft.IdentityModel.Tokens
```

Server registration:

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidateAudience = true,
            ValidAudience = configuration["Jwt:Audience"],
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

app.UseAuthentication();
app.UseAuthorization();
```

> Signing proves the token was issued by a trusted server and has not been changed. JWT is not encrypted by default, so never put passwords or sensitive data in claims.

### 4. Middleware request flow

```text
Request
 → Exception/logging middleware
 → HTTPS/static files
 → Routing
 → CORS
 → Authentication
 → Authorization
 → Endpoint/controller
 → response travels back outward in reverse order
```

```csharp
public async Task InvokeAsync(HttpContext context)
{
    // before next middleware
    await _next(context);
    // after endpoint response returns
}
```

> Middleware is an onion. Code before `await _next` runs on the way in; code after it runs on the way out. Middleware can short-circuit by not calling `_next`.

### 5. Global exception middleware—and authentication failures

```csharp
public sealed class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;

    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger)
        => (_next, _logger) = (next, logger);

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (NotFoundException ex)
        {
            await WriteProblem(context, 404, "Not found", ex.Message);
        }
        catch (ValidationException ex)
        {
            await WriteProblem(context, 400, "Validation failed", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception. TraceId: {TraceId}", context.TraceIdentifier);
            await WriteProblem(context, 500, "Unexpected error", "Please try again later.");
        }
    }
}
```

> Put it early so it surrounds downstream middleware and endpoints. It logs one consistent error shape and keeps controllers clean.

Important correction:

> Authentication and authorization failures usually do **not** throw exceptions. The JWT handler produces a `401`; authorization produces a `403`. Configure JWT `OnChallenge`/`OnForbidden` events or a custom authorization result handler if those responses need a common JSON shape. Global exception middleware handles unhandled exceptions, not normal access denial.

### 6. How can middleware be registered?

| Way | Code | Use |
|---|---|---|
| Conventional class | `app.UseMiddleware<GlobalExceptionMiddleware>();` | Normal reusable middleware |
| Inline delegate | `app.Use(async (ctx, next) => { await next(); });` | Small local pipeline concern |
| `IMiddleware` class | `AddScoped<MyMiddleware>(); app.UseMiddleware<MyMiddleware>();` | Middleware needing DI activation per request |
| Built-in | `app.UseExceptionHandler(...)` | Framework exception handler |
| Extension method | `app.UseGlobalExceptionHandling();` | Clean startup/composition API |

> Middleware has **no required base class**. Conventional middleware receives `RequestDelegate` and exposes `Invoke` or `InvokeAsync`; alternatively it implements `IMiddleware`.

### 6a. Why global instead of local catch blocks?

```text
Global → consistent status/ProblemDetails/logging/trace ID
Local  → only when method can recover, retry, compensate, or add business meaning
```

> Do not wrap every controller in generic `try/catch`. Throw/return meaningful domain outcomes locally; let global middleware map unexpected failures consistently.

### 7. DI: definition, example, and multiple implementations

> Dependency injection means a class receives the collaborators it needs instead of constructing them. It reduces coupling, supports unit tests, and lets the composition root select implementation.

```csharp
public class ReminderService
{
    private readonly INotificationService _notifications;

    public ReminderService(INotificationService notifications)
        => _notifications = notifications;
}

builder.Services.AddScoped<INotificationService, PushNotificationService>();
```

Multiple registrations:

```csharp
builder.Services.AddScoped<IEmailSender, AzureEmailSender>();
builder.Services.AddScoped<IEmailSender, TwilioEmailSender>();

public SenderResolver(IEnumerable<IEmailSender> senders) { ... }
```

```text
Resolve IEmailSender             → last registration
Resolve IEnumerable<IEmailSender> → all registrations, registration order
```

Best selection options:

```text
Strategy resolver with CanHandle/provider key
Factory
.NET keyed services: AddKeyedScoped / GetRequiredKeyedService
```

### 8. Async/await: I/O versus CPU

| Work | Correct tool |
|---|---|
| DB, HTTP, Blob upload, file read/write | native async I/O: `await`, no blocked thread |
| Compression, hashing, image/PDF transform | CPU work; bounded worker/background job |
| One small CPU calculation | run directly if very short |
| Large server CPU job | queue/background service; do not tie up request |

```csharp
await using var input = file.OpenReadStream();
await blobClient.UploadAsync(input, cancellationToken); // I/O-bound

var hash = await Task.Run(() => ComputeHash(bytes), cancellationToken); // CPU-bound, bounded use
```

> `async` does not magically create a thread. For I/O it frees the request thread while the OS/network works. Do not use `Task.Run` around EF Core, `HttpClient`, or Blob async APIs.

### 9. How would you process 10,000 files efficiently?

```text
Stream file; do not load all into RAM
 → producer/consumer queue
 → bounded concurrency
 → one DbContext/scope per work item
 → batch database work where safe
 → idempotency + retry transient failures
 → dead-letter/failed list + metrics
```

```csharp
await Parallel.ForEachAsync(
    files,
    new ParallelOptions
    {
        MaxDegreeOfParallelism = 8,
        CancellationToken = cancellationToken
    },
    async (file, ct) =>
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var handler = scope.ServiceProvider.GetRequiredService<IFileHandler>();
        await handler.ProcessAsync(file, ct);
    });
```

> Never `Task.WhenAll` 10,000 uploads without a limit. It can exhaust connections, sockets, memory, rate limits, and database capacity. Tune concurrency from measurements and downstream limits. `DbContext` is not thread-safe, so never share one across parallel tasks.

### 10. Runtime polymorphism using classes

```csharp
public abstract class TaxCalculator
{
    public abstract decimal Calculate(decimal amount);
}

public sealed class CityTaxCalculator : TaxCalculator
{
    public override decimal Calculate(decimal amount) => amount * 0.05m;
}

TaxCalculator calculator = new CityTaxCalculator();
decimal tax = calculator.Calculate(100m); // runtime chooses City implementation
```

> Runtime polymorphism means a base-class or interface reference invokes the override of the real object at runtime. In ROD, attachments have a base `BaseAttachment` and concrete subtypes such as associate/driver-load attachments. EF materializes the concrete subtype; `OfType<AssociateAttachment>()` selects the appropriate runtime type. For changing behavior, I prefer interfaces/strategies over deep inheritance.

### 11. `const` versus `readonly`

| `const` | `readonly` |
|---|---|
| Compile-time constant | Runtime field value |
| Implicitly static | Instance or static field |
| Must initialize at declaration | Initialize at declaration or constructor |
| Literal/constant-compatible types | Any field type |
| Value embedded into consuming assembly | Value read from field at runtime |

```csharp
public const int MaxRetries = 3;
public readonly DateTime CreatedAt;
public static readonly string BuildVersion;

public MyClass(DateTime now)
{
    CreatedAt = now; // ✅ constructor assignment
}
```

```text
Readonly assignment in ordinary method?  ❌ no
Readonly assignment in its constructor?  ✅ yes
Static readonly in static constructor?   ✅ yes
```

Reference-object trap:

```csharp
public readonly List<string> Tags = new();

Tags.Add("driver");          // ✅ object may mutate
// Tags = new List<string>(); // ❌ field reference cannot be reassigned
```

### 12. `using` and disposable services

| `using` form | Meaning |
|---|---|
| `using System;` | namespace import |
| `using var stream = ...;` | calls `Dispose()` at scope end |
| `await using` | calls `DisposeAsync()` |
| `using Alias = ...;` | type alias |

```csharp
await using var stream = file.OpenReadStream();
await blobClient.UploadAsync(stream, cancellationToken);
```

> Disposable objects own scarce resources: file handles, database connections, streams, readers, timers, and unmanaged/native handles. `using` guarantees cleanup even when an exception occurs.

DI rule:

> Do not manually dispose an injected DI service. The DI container disposes scoped services when the scope ends and singletons when the application stops. Dispose resources that **you** create and own.

### 13. Garbage collection, generations, and LOH

```text
Gen 0 → newest short-lived objects; collected often
Gen 1 → buffer between short and long lived
Gen 2 → long-lived survivors; collection is more expensive
LOH   → large objects (roughly ≥ 85 KB); collected with Gen 2
```

> Surviving objects are promoted. Many large allocations or long-lived references increase Gen 2/LOH pressure. For file handling, stream content, use buffers carefully/`ArrayPool`, avoid loading huge files into memory, and dispose unmanaged resources. Do not call `GC.Collect()` as a normal performance fix.

### 14. Middleware methods: `Invoke`, `InvokeAsync`, base class

```csharp
public async Task InvokeAsync(HttpContext context)
{
    await _next(context);
}
```

```text
Invoke       → synchronous signature possible
InvokeAsync  → normal async signature; returns Task
Base class   → none required
Required convention → public Invoke/InvokeAsync accepting HttpContext
Alternative  → implement IMiddleware
```

> Scoped services can be injected into `InvokeAsync` parameters for conventional middleware. Do not capture a scoped service in a singleton-like conventional middleware constructor.

### 15. Deadlock versus race condition

| Deadlock | Race condition |
|---|---|
| Two operations wait forever/cycle for each other | Result depends on unsafe timing |
| Example: Txn A locks shipment then driver; Txn B locks driver then shipment | Example: two requests both see “no record” then both insert |
| Fix: consistent lock order, short transactions, indexes, retry deadlock victim | Fix: synchronization, unique constraint, optimistic concurrency, idempotency |

Async deadlock example:

```csharp
var result = GetDataAsync().Result; // avoid blocking async flow
```

> Use `await` end to end. For shared database business state, an in-memory `lock` is not enough across multiple servers; use database constraints/concurrency controls.

### 16–17. SOLID problem: city/country tax and Open/Closed Principle

Bad design:

```csharp
if (country == "IN" && city == "Bangalore") return amount * .05m;
if (country == "US") return amount * .07m;
// every rule changes this class
```

Open design:

```csharp
public record TaxRequest(string Country, string? City, decimal Amount);

public interface ITaxRule
{
    bool CanHandle(TaxRequest request);
    decimal Calculate(TaxRequest request);
}

public sealed class BangaloreTaxRule : ITaxRule
{
    public bool CanHandle(TaxRequest x) => x.Country == "IN" && x.City == "Bangalore";
    public decimal Calculate(TaxRequest x) => x.Amount * 0.05m;
}

public sealed class TaxService(IEnumerable<ITaxRule> rules)
{
    public decimal Calculate(TaxRequest request) =>
        rules.Single(r => r.CanHandle(request)).Calculate(request);
}
```

> Open/Closed means stable orchestration is closed for modification but open for extension. Add a new rule class and DI registration; do not edit a giant `if/else`. If only tax **rates** change, keep rates/configuration data-driven; if calculation **behavior** changes, add a new rule/strategy.

Design principles behind it:

```text
Composition over inheritance
Dependency inversion: depend on ITaxRule
High cohesion: each rule owns one tax behavior
Low coupling: service does not know every city
Single responsibility: selection/calculation separated from HTTP/storage
```

### 18. Works locally but fails in production: debugging path

```text
1. Define exact symptom: endpoint, user/tenant, status, time, trace ID
2. Compare version/build + environment config + feature flags + secrets
3. Inspect structured logs, traces, telemetry, dependencies
4. Compare production data, migrations/schema, permissions/IAM, tenant context
5. Inspect generated SQL + execution plan if DB path is slow/wrong
6. Reproduce safely with production-like data/config
7. Fix smallest root cause; test; deploy safely; monitor
```

> “Business logic did not change” does not mean the environment is equal. Production differences include configuration, data volume, missing migration, secret/identity permissions, network/DNS, third-party endpoint, feature flag, time zone, OS/runtime version, and load.

### 19. Third-party service fails: debug and fix

```text
Trace/correlation ID
 → safe request metadata: URL, method, status, duration, provider error code
 → redact secrets/PII
 → compare sandbox/prod config, credentials, DNS/TLS, contract/version
 → provider status page/docs/support
 → timeout + bounded retry for transient failure
 → circuit breaker/fallback/queue if dependency is unavailable
 → idempotency for any retried write
```

> Do not retry every `4xx`; validation/auth errors need correction. Retry transient timeouts, `429`, and selected `5xx` with exponential backoff and jitter while respecting `Retry-After`.

### 20. Retrying requests: refresh token race condition

```text
Many API calls receive 401
 → all want to refresh
 → without coordination: refresh-token rotation race / logout / overwrite
 → solution: one shared refresh promise (“single flight”)
 → waiting calls reuse result
 → retry original request once
 → refresh failure: clear session and login
```

```csharp
private readonly object _refreshGate = new();
private Task<Token>? _inflightRefresh;

public Task<Token> RefreshOnceAsync()
{
    lock (_refreshGate)
    {
        if (_inflightRefresh is { IsCompleted: false })
            return _inflightRefresh;

        return _inflightRefresh = RefreshCoreAsync();
    }
}
```

> The lock only protects choosing/creating the shared task; it does not surround an `await`. Persist rotated refresh/access tokens atomically where possible, cap retry to one, and prevent interceptor loops.

### 21. CORS: what and setup

> CORS is a browser security rule. A browser sends an `Origin`; the server explicitly allows selected origins/methods/headers. Non-browser server-to-server calls are not protected by browser CORS enforcement.

```csharp
builder.Services.AddCors(options =>
    options.AddPolicy("WebApp", policy => policy
        .WithOrigins("https://app.example.com")
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()));

app.UseRouting();
app.UseCors("WebApp");
app.UseAuthentication();
app.UseAuthorization();
```

```text
Simple request    → browser sends request with Origin
Preflight request → browser sends OPTIONS first for non-simple request
Server response   → Access-Control-Allow-* headers decide browser access
```

> Never combine `AllowAnyOrigin()` with `AllowCredentials()`. Restrict explicit production origins.

### 22. 100/min API versus 10,000/min API: rate limiting

For an **outgoing** third-party API, give every provider/client its own concurrency, queue, and retry policy:

```text
Provider A: 100/min    → token bucket/queue; backpressure; respect Retry-After
Provider B: 10,000/min → separate larger policy; still cap concurrency
```

For **incoming** ASP.NET Core endpoints:

```csharp
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("lowLimit", limiter =>
    {
        limiter.PermitLimit = 100;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueLimit = 20;
    });
});

app.UseRateLimiter();

[EnableRateLimiting("lowLimit")]
public IActionResult PartnerEndpoint() => Ok();
```

> Partition by API key, tenant, user, or IP—not one global bucket—when fairness matters. Return `429 Too Many Requests` and `Retry-After`; queue/background-process work where immediate response is unnecessary.

### 23. Slow application: diagnosis and optimization

```text
Measure p50/p95/p99 + trace ID
 → split time: API / DB / third party / CPU / memory
 → inspect generated SQL + parameters
 → actual execution plan + STATISTICS IO/TIME
 → fix query shape/index/data amount
 → remeasure same workload
```

EF Core checks:

```csharp
var sql = query.ToQueryString();

var result = await db.Shipments
    .AsNoTracking()
    .Where(x => x.Status == ShipmentStatus.Ready)
    .Select(x => new ShipmentDto(x.Id, x.Reference))
    .Take(50)
    .ToListAsync();
```

```text
Avoid N+1                 → projection / suitable Include / batch
Avoid tracking for reads  → AsNoTracking
Avoid over-fetch          → Select DTO columns
Avoid unbounded lists     → pagination + stable sort
Use indexes by workload   → filter/join/sort columns, measured plan
Keep predicates sargable  → do not wrap indexed columns in functions
```

Execution-plan red flags:

```text
Unexpected table scan | expensive sort/hash | key lookup storm
estimated vs actual row mismatch | spills | high logical reads
```

> Stored procedures are useful for mature DB-owned/reporting/set-based workloads or carefully tuned operations, but not an automatic cure. Choose EF LINQ or a procedure from maintainability and measurements.

### 24. One line: duplicate elements in an array

```csharp
var duplicates = items.GroupBy(x => x).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
```

### 25. LINQ inner join using `Join`

```csharp
var result = await db.Shipments
    .Join(
        db.Drivers,
        shipment => shipment.DriverId,
        driver => driver.Id,
        (shipment, driver) => new
        {
            shipment.Id,
            shipment.Reference,
            DriverName = driver.Name
        })
    .ToListAsync();
```

> `Join` returns only rows having a match on both sides: an inner join. With an EF navigation property, projection such as `shipment.Driver.Name` is often clearer and still translates to SQL.

### 26. SQL: eighth-highest salary/rank and window functions

```sql
WITH Ranked AS
(
    SELECT
        EmployeeId,
        Salary,
        DENSE_RANK() OVER (ORDER BY Salary DESC) AS SalaryRank
    FROM Employees
)
SELECT EmployeeId, Salary
FROM Ranked
WHERE SalaryRank = 8;
```

| Function | Ties |
|---|---|
| `ROW_NUMBER()` | every row gets unique number; duplicate salary gets different number |
| `RANK()` | ties share rank; gaps follow ties: `1, 1, 3` |
| `DENSE_RANK()` | ties share rank; no gaps: `1, 1, 2` |

> “Eighth highest” usually means eighth **distinct** salary, so `DENSE_RANK` is the safest answer. Clarify whether they mean employee row number, rank with gaps, or distinct salary.

## Round 2 memory map

```text
SECURE    → JWT, authz, CORS, rate limits
PIPELINE  → middleware, global exception, DI
SCALE     → async, 10k files, retries, races, deadlocks
DESIGN    → polymorphism, SOLID, OCP tax rules
OPERATE   → production bug, third party, telemetry
DATA      → EF SQL plan, duplicates, joins, window functions
```
