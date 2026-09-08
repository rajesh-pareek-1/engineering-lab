# High-End Topic 06 — How Hangfire Works in ROD

> **Goal:** Explain Hangfire from library registration to SQL persistence to tenant-aware execution—without confusing it with a message broker.

---

## One-line answer

> **“ROD uses Hangfire with SQL Server storage for durable background and recurring work. It persists job state in the shared database, restores tenant context when a worker executes a job, and then resolves normal scoped services against the correct tenant database.”**

```text
Schedule work now
        ↓
Persist job instruction in SQL
        ↓
Hangfire worker picks it up later
        ↓
Create DI scope + restore tenant context
        ↓
Run normal application service
```

---

## 1. Why use Hangfire here?

Some work should not keep an API request open:

```text
document-expiry reminders
ETA reminders
password-expiry notifications
email sending
QuickBooks token refresh
monthly subscription calculations
tenant onboarding/seed work
```

Without a durable scheduler:

```text
HTTP request ends / app restarts
        ↓
in-memory Task may disappear
        ↓
missed notification or incomplete onboarding
```

Hangfire gives durable job storage, retries/state history, delayed and recurring schedules, background workers, dashboard visibility, and DI activation.

---

## 2. Libraries and ROD registration

ROD references Hangfire and SQL Server storage, then configures them in `RollOnDispatch/Startup.cs`.

```csharp
services.AddHangfire(configuration => configuration
    .UseActivator(new CustomHangfireJobActivator(scopeFactory))
    .UseSqlServerStorage(
        Configuration.GetConnectionString("RollOnDispatchDatabase"),
        sqlServerOptions));

services.AddHangfireServer();
```

```text
AddHangfire         → register Hangfire client/storage services
UseSqlServerStorage → persist jobs in SQL Server
AddHangfireServer   → start worker process in this application host
UseActivator        → create a DI scope correctly for each job
```

At application startup ROD also registers:

```csharp
GlobalConfiguration.Configuration.UseFilter(new BackgroundJobFilter());
app.UseHangfireDashboard("/hangfire", dashboardOptions);
```

```text
BackgroundJobFilter → captures tenant context when a job is created
Dashboard           → operational view of queued/failed/recurring jobs
```

---

## 3. Which SQL database stores jobs?

ROD calls `UseSqlServerStorage` with `RollOnDispatchDatabase`, the shared/global connection.

```text
Shared SQL database
├── AppGlobalContext control-plane data
│   ├── Tenants, Users, Accounts, Roles, Settings...
│   └── integrations/configuration
└── Hangfire infrastructure
    ├── Job
    ├── State
    ├── JobParameter
    ├── JobQueue
    ├── Server
    ├── Set / Hash / List
    └── recurring-job metadata

Tenant business SQL database
└── shipments, drivers, attachments, dispatch data...
```

```text
Hangfire SQL stores: what should run, when, with what arguments, and what happened.
Tenant SQL stores: the actual driver/shipment/document business records.
```

---

## 4. The three job APIs you must know

| API | Meaning | ROD example |
|---|---|---|
| `BackgroundJob.Enqueue` | Run once as soon as a worker is free | Execute document reminder handler or send email |
| `BackgroundJob.Schedule` | Run once after a delay | Seed company settings after five seconds |
| `RecurringJob.AddOrUpdate` | Create/update cron-based durable schedule | Daily tenant automation and monthly billing |

```csharp
BackgroundJob.Enqueue<DocumentExpiryReminderService>(
    s => s.SetDriversForDocumentExpiryReminder());

BackgroundJob.Schedule<SettingService>(
    s => s.InsertSeedDataFromChargeBee(companyName),
    TimeSpan.FromSeconds(5));

RecurringJob.AddOrUpdate<TenantCornJobService>(
    jobId,
    s => s.SetDocumentExpiryReminderHandler(context),
    Cron.Daily);
```

`AddOrUpdate` matters because the stable tenant-specific job ID updates a schedule instead of creating duplicates on every onboarding/startup attempt.

---

## 5. The hard part: tenant context

An HTTP request has a JWT and `HttpContext`. A Hangfire worker has neither.

```text
Normal API request
JWT → HttpContext.User → RequestContext → TenantDbContextFactory

Hangfire job
no HTTP request
        ↓
must restore tenant identity before service/repository creation
```

ROD solves this with three custom pieces:

```text
BackgroundJobContext
        ↓
BackgroundJobFilter
        ↓
CustomHangfireJobActivator
```

---

## 6. Tenant-aware job flow — actual code path

```text
1. Application schedules a job for Tenant A
   using var jc = new BackgroundJobContext(tenantAId);
   BackgroundJob.Enqueue<SomeService>(...);
        ↓
2. BackgroundJobFilter.OnCreating(...)
   → filterContext.SetJobParameter("BackgroundJobContext", context)
        ↓
3. Hangfire persists JobParameter in shared SQL
        ↓
4. Worker later receives the job
        ↓
5. CustomHangfireJobActivator.BeginScope(...)
   → creates IServiceScope
   → reads BackgroundJobContext job parameter
   → resolves IRequestContext
   → requestContext.SetBackgroundContext(tenantAId)
        ↓
6. Job service/repository is resolved through DI
        ↓
7. ITenantDbContextFactory sees Tenant A
   → builds Tenant A RollOnDispatchContext
        ↓
8. Job queries/writes only Tenant A operational data
```

Source shape:

```csharp
var jc = context.GetJobParameter<BackgroundJobContext>(
    nameof(BackgroundJobContext));

if (jc != null)
{
    var requestContext = serviceScope.ServiceProvider
        .GetRequiredService<IRequestContext>();
    requestContext.SetBackgroundContext(jc.TenantId);
}
```

`SetBackgroundContext` assigns the tenant plus service identity `BackgroundService`, because no human user is executing the job.

---

## 7. Real document-reminder job chain

```text
TenantCornJobService.InitializeTenantCronJobs(tenantId)
        ↓
RecurringJob.AddOrUpdate(
  "{tenantId}-...DocumentExpiryReminder...",
  Cron.Daily)
        ↓
SetDocumentExpiryReminderHandler(BackgroundJobContext rc)
        ↓
using BackgroundJobContext(rc.TenantId)
        ↓
BackgroundJob.Enqueue<DocumentExpiryReminderService>(
  s => s.SetDriversForDocumentExpiryReminder())
        ↓
Hangfire worker restores tenant context
        ↓
DocumentExpiryReminderService
        ↓
tenant-aware repositories
        ↓
notification hub / mobile push
```

Other tenant recurring jobs registered in the same service:

```text
monthly subscription-charge processing
daily ETA reminder
daily password-expiry notification
daily QuickBooks refresh-token update (feature-flagged)
daily document-expiry status processing (2:00 AM)
daily document-expiry reminder (feature-flagged)
```

---

## 8. What happens inside SQL storage?

```text
Enqueue/Schedule/RecurringJob call
        ↓
Hangfire serializes method + target type + arguments + job parameters
        ↓
SQL row is created/updated
        ↓
state starts as Enqueued/Scheduled
        ↓
worker polls queue and moves it to Processing
        ↓
success → Succeeded
failure → Failed and retry policy/state handling
```

This is why an application restart is survivable: job instruction/state is in SQL, not only memory.

```text
At-least-once execution is possible.
Therefore job handlers should be idempotent.
```

Example:

```text
“Send reminder” can run twice after a crash/retry.
Use a reminder ledger + unique key to avoid duplicate user notifications.
```

---

## 9. Why Hangfire instead of Azure Service Bus?

```text
Hangfire
→ application background jobs, delayed/recurring schedules, .NET method execution,
  dashboard, SQL persistence.

Azure Service Bus
→ integration messaging between separate services/systems, independent consumers,
  dead-letter queues, decoupled scaling.
```

```text
Daily document reminder schedule → Hangfire is a natural fit.

Shipment-created event consumed by independently deployed billing/analytics systems
→ message bus + outbox may be a better fit.
```

---

## 10. Reliability and operations

| Concern | ROD mechanism | Stronger next step |
|---|---|---|
| Process restart | SQL-backed job state | monitor worker heartbeat/queue depth |
| Job failure | Hangfire state/retry history | alert on retry exhaustion/failed jobs |
| Tenant isolation | job parameter + custom activator | integration test wrong/missing tenant behavior |
| Duplicate execution | handler should tolerate retry | idempotency table/unique constraint |
| Long work | background worker, not HTTP request | queue separation and concurrency limits |
| Dashboard | Hangfire dashboard | enforce HTTPS, strong identity/RBAC, audit access |

Monitor:

```text
queue depth
oldest queued job age
processing duration by job type
retry count and failed jobs
worker/server heartbeat
tenant-specific failure rate (with metric-cardinality care)
```

---

## 11. Risks and improvements

```text
Job arguments
→ keep them small and stable; pass IDs rather than large object graphs.

External side effects
→ SQL transaction cannot roll back email/push/Blob writes.
→ use retry, idempotency, and an outbox when delivery must be guaranteed.

Tenant context
→ fail clearly when business work has no tenant context.

Dashboard security
→ production should require HTTPS and appropriate access control.

Heavy tenant
→ one tenant’s large job must not starve others; use queues/concurrency/rate limits.
```

---

## 12. 90-second spoken answer

> “ROD uses Hangfire with SQL Server storage for durable background and recurring processing. Startup registers Hangfire, points it to the shared `RollOnDispatchDatabase` connection, starts a Hangfire server, and exposes the dashboard for operations. SQL storage contains job metadata, schedules, parameters, state, retries, queues, and worker information—not tenant shipment data.
>
> The important design challenge is multi-tenancy. A Hangfire job has no HTTP request or JWT. Before creating a job, ROD creates `BackgroundJobContext` with the tenant ID. A Hangfire client filter saves it as a job parameter. When the worker later runs the job, the custom job activator creates a DI scope, restores that tenant ID into `IRequestContext`, and repositories resolve the tenant-specific EF Core context through `ITenantDbContextFactory`.
>
> We use `Enqueue` for immediate background work, `Schedule` for delayed one-time work, and `RecurringJob.AddOrUpdate` for daily/monthly tenant jobs such as document expiry reminders. Because durable background systems can retry, I design handlers to be idempotent and monitor queue depth, failure rate, and job duration.”

---

## Rapid cross-questions

| Question | Answer |
|---|---|
| What if the server restarts? | SQL storage preserves queued/scheduled job metadata; a worker can resume processing when available. |
| Why not `Task.Run()`? | It is tied to process lifetime, has no durable retry/history/schedule, and can vanish on restart. |
| Does Hangfire use SQL business tables? | No. It uses scheduler tables in global SQL; business repositories use tenant databases. |
| Is Hangfire exactly once? | Do not assume it. Make side-effecting jobs idempotent because retries/crashes can repeat execution. |
| How do you prevent wrong-tenant job work? | Store tenant context at creation, restore it in the activator before repository resolution, and test it. |
| How do you scale workers? | Run additional server instances/queues with controlled worker counts, watch SQL/queue pressure, and isolate heavy workloads. |
