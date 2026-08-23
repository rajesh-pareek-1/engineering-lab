# 11. Current .NET Market and Version Decisions

> **Purpose:** 45 concise, interview-style questions about what is current, what to choose, and why.
> **Checked:** 23 August 2026. Versions change; the decision logic ages better than a version number.

## Your credibility rule

```text
Actual project: .NET 8 + EF Core 8 + SQL Server
Modern choice:  .NET 10 LTS + EF Core 10 for a new long-lived service
Interview rule: never claim production experience with a newer tool merely because you understand it
```

## Answer engine: **R-D-T**

```text
R — Reality: what is current or what the system needs
D — Decision: what I would choose
T — Trade-off: what I gain and what I accept
```

## A. .NET platform and version choices

| # | Interview question | Sharp answer |
|---:|---|---|
| 1 | Which .NET version would you choose for a new enterprise API today? | **.NET 10 LTS**, unless a company platform standard requires another supported version. LTS gives a three-year support window; use the latest patch, not only `10.0.0`. |
| 2 | Is .NET 8 obsolete? | No. It is still supported, but in maintenance until **10 November 2026**. For a new long-lived system I would normally start on .NET 10 LTS; for an existing `net8.0` system I would plan and test an upgrade rather than rush it. |
| 3 | Is .NET 9 safe for production? | It is still supported until **10 November 2026**, but it is STS. I choose it only when a specific feature matters and the organization accepts the shorter upgrade cadence. |
| 4 | LTS versus STS? | LTS is three years of support and suits stable enterprise products. STS is two years and suits teams that deliberately upgrade frequently; quality is not lower, only support duration differs. |
| 5 | What is the current .NET release rhythm? | A major release comes every November. Even-numbered releases are LTS and odd-numbered releases are STS, so version planning should be part of the roadmap. |
| 6 | When would you keep .NET Framework? | To maintain a Windows-only legacy dependency, especially ASP.NET Web Forms or a library that cannot move yet. I would place new APIs/services on modern .NET, not start new Web Forms code. |
| 7 | Can EF Core 10 run on .NET 8? | No. EF Core 10 requires the .NET 10 SDK/runtime. Version alignment matters: a framework upgrade must include compatibility and regression testing. |
| 8 | What is the practical upgrade path from ROD's .NET 8? | Patch .NET 8 immediately, inventory packages and breaking changes, upgrade a branch to .NET 10/EF10, run unit/integration/performance tests, deploy gradually, then monitor errors and latency. |
| 9 | Should we upgrade simply because a new major version exists? | No. Upgrade for supported lifecycle, security, needed capability, or operational benefit. Balance those gains against package compatibility, breaking changes, test effort, and release risk. |
| 10 | Framework-dependent or self-contained publish? | Framework-dependent is smaller and patches centrally when the host runtime is controlled. Self-contained gives a predictable runtime image but increases artifact size and patch responsibility. Containers commonly make either viable. |

## B. API and architecture decisions

| # | Interview question | Sharp answer |
|---:|---|---|
| 11 | Controllers or Minimal APIs? | Controllers fit ROD-style larger APIs needing conventions, filters, clear grouping, and team familiarity. Minimal APIs suit small focused services; I choose readability and maintainability over fewer lines. |
| 12 | Is OpenAPI/Swagger still important? | Yes. OpenAPI is the contract for endpoint shapes, auth, request/response schemas, client generation, testing, and collaboration; Swagger UI is only one way to view it. |
| 13 | REST or GraphQL? | REST is my default for stable resource workflows and clear HTTP caching/authorization. GraphQL helps when clients need varied connected data shapes, but it adds resolver N+1, query-cost, caching, and authorization concerns. |
| 14 | Microservices or modular monolith? | Start with a well-structured modular monolith unless independent deployment, scaling, ownership, or fault isolation is proven. Microservices buy independence but create distributed data, retries, observability, and deployment complexity. |
| 15 | What is .NET Aspire? | Aspire is a code-first orchestration and observability layer for distributed applications: it models services, databases, queues, caches, and dependencies for local development. It is **not** a cloud provider or replacement for ASP.NET Core. |
| 16 | Would you add Aspire to ROD tomorrow? | Not automatically. I would consider its Service Defaults/OpenTelemetry setup or local orchestration if the system becomes multi-service; a modular monolith does not need trendy infrastructure merely to look modern. |
| 17 | Containers versus virtual machines? | Containers package the app and dependencies consistently, support repeatable deployments, and allow density/scaling. They still need external configuration, secret management, health checks, and logging; Docker is not an architecture by itself. |
| 18 | When do you need Kubernetes/AKS? | When multiple services need automated scheduling, scaling, rollout, service discovery, and self-healing. A single modest API can often be simpler and cheaper on App Service or a managed container platform. |
| 19 | Serverless or always-running API? | Serverless fits bursty event-driven functions and operational simplicity. A continuously active API with predictable latency, long connections, or complex networking may fit containers/App Service better. |
| 20 | Synchronous HTTP or asynchronous messaging? | Use HTTP when the caller needs an immediate answer. Use a queue/event for slow, retryable, or independently consumed work; design consumers as idempotent because delivery can be repeated. |
| 21 | Hangfire or Azure Service Bus? | Hangfire is good for in-application scheduled/background jobs such as ROD’s document-expiry reminder. Service Bus is for durable decoupled communication between independent services. |
| 22 | SignalR or Service Bus? | SignalR pushes live updates to connected users. Service Bus durably moves work/events between systems. For an important notification, persist/queue the intent, then use SignalR only as a live delivery channel. |
| 23 | What is the outbox pattern? | Save the business change and an event record in the same SQL transaction. A worker later publishes the event and marks it processed, reducing the "database saved but message was never sent" failure gap. |
| 24 | Why is idempotency now a core API concern? | Retries, mobile reconnects, and queues can repeat requests. I use an operation/idempotency key plus a uniqueness constraint or durable record so duplicate delivery cannot create duplicate invoices, uploads, or notifications. |
| 25 | How would you version APIs today? | Prefer additive, backward-compatible changes first. Version only when the contract must break; choose one consistent approach—URL, header, or media type—and publish the OpenAPI contract and deprecation plan. |
| 26 | Why add rate limiting? | It protects availability and downstream dependencies from accidental or abusive traffic. Set limits by identity/tenant/route, return `429`, and avoid using it as the only security control. |

## C. Data, EF Core, and scale

| # | Interview question | Sharp answer |
|---:|---|---|
| 27 | EF Core, Dapper, or stored procedure? | EF Core is strong for most business CRUD and composable queries. Dapper/raw SQL can fit measured hot paths; stored procedures fit established DB-owned or set-based work. I choose after inspecting the workload, not by ideology. |
| 28 | Is EF Core slow? | EF Core is not inherently slow. Common problems are poor query shape, tracking unused reads, N+1 loading, too many columns, missing indexes, or unbounded result sets. I inspect generated SQL and the actual execution plan. |
| 29 | What is the default read-query shape? | Tenant/authorization filter first, then business filters, stable sort, server pagination, DTO projection, and `AsNoTracking` for a read-only result. |
| 30 | `Include` or projection? | Use projection for list/API response shapes because it returns only needed columns. Use `Include` when the aggregate needs related tracked entities; inspect for N+1 and Cartesian explosion. |
| 31 | When use `AsSplitQuery()`? | When loading several large collections and one join would multiply rows. It trades one huge duplicated result for a small fixed number of queries—not one query per entity. |
| 32 | Redis or in-memory cache? | In-memory cache is process-local and simple for one instance. Redis/distributed cache shares values across scaled instances; both need tenant-aware keys, TTL, invalidation, and protection against stale or sensitive data. |
| 33 | Should every slow endpoint get Redis? | No. First measure SQL, indexes, payload, query count, and downstream latency. Cache only data that is read frequently, changes infrequently, and can tolerate an explicit freshness model. |
| 34 | What is the current AI-data trend for backend engineers? | Retrieval/vector search can help semantic search or RAG, but it does not replace SQL for transactions, constraints, joins, and source-of-truth records. Keep authorization filtering before exposing retrieved data. |
| 35 | What is a safe database migration practice? | Use expand–migrate–contract: add backward-compatible schema first, deploy code that supports both states, backfill safely, switch reads, then remove old fields later. Review lock and index impact on production data. |

## D. Security, compliance, and supply chain

| # | Interview question | Sharp answer |
|---:|---|---|
| 36 | JWT, OAuth 2.0, and OpenID Connect—what differs? | JWT is a token format. OAuth 2.0 delegates authorization; OpenID Connect adds identity/authentication. A JWT bearer API validates tokens; that alone does not mean I built an OAuth identity provider. |
| 37 | Are passkeys replacing every login? | Passkeys are a strong phishing-resistant authentication option, but adoption depends on identity provider, device recovery, user population, and compliance. They complement—not magically replace—authorization and session design. |
| 38 | How do you manage secrets? | Never in source or Docker images. Use environment-specific secret management such as Azure Key Vault/managed identity, least privilege, rotation, and redacted logs. |
| 39 | What is software supply-chain security? | Control dependencies and build provenance: patch supported runtimes, scan packages/images, lock versions where appropriate, review CVEs, keep an SBOM where required, and protect CI/CD credentials. |
| 40 | What changes in a clinical/regulated backend? | Audit trails, least privilege, version/history, validated workflows, data retention, secure logs, and traceability become product requirements—not later add-ons. |

## E. Observability, reliability, and AI-era engineering

| # | Interview question | Sharp answer |
|---:|---|---|
| 41 | Why is OpenTelemetry a market-standard topic? | It provides vendor-neutral logs, metrics, and distributed traces. In .NET it works with `ILogger`, `Meter`, and `ActivitySource`, then can export to Azure Monitor, Prometheus/Grafana, or another backend. |
| 42 | Logs versus metrics versus traces? | Logs explain a discrete event; metrics show aggregate health such as latency/error rate; traces follow one request across API, SQL, and dependencies. I use correlation/trace IDs to connect them. |
| 43 | What health checks would you expose? | **Liveness** means the process is alive; **readiness** means it can accept traffic, considering critical dependencies carefully. Do not make every optional external service turn readiness red unless that is truly required. |
| 44 | What is an SLO? | A measurable reliability target, for example “99.9% of shipment reads succeed” or a p95 latency target. It makes alerting and engineering trade-offs based on user impact rather than only server CPU. |
| 45 | How should engineers use GenAI tools? | Use them to accelerate drafts, tests, explanations, and investigation—not as an authority. Review security, correctness, licensing, performance, and data exposure; never paste secrets, customer data, or regulated data into an unapproved tool. |

## ROD-specific delivery lines

```text
ROD is net8.0 today → supported but near end of support.
I would plan .NET 10 LTS + EF Core 10 after dependency and regression testing.

Hangfire fits ROD’s scheduled document-expiry job.
Service Bus fits a future independent billing/notification consumer.

For a slow expiry batch → remove N+1 attachment queries before adding cache.
For production diagnostics → correlation ID + structured logs now; OpenTelemetry is the sensible next step.
```

## Primary sources for version facts

- [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core)
- [EF Core 10: what is new and support lifecycle](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew)
- [.NET Aspire overview](https://learn.microsoft.com/dotnet/aspire/get-started/aspire-overview)
- [.NET Native AOT trade-offs](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/)
- [.NET observability with OpenTelemetry](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel)
- [ASP.NET Core OpenAPI support](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0)
