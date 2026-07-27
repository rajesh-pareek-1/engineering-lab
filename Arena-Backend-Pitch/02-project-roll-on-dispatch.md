# 2. Roll On Dispatch - Project Pitch and Cross-Questions

## 60-second project pitch

> Roll On Dispatch is a multi-tenant logistics platform used for operational workflows involving shipments, drivers, driver loads, trailers, carriers, documents, invoices, and mobile clients. The backend is built on .NET 8 and ASP.NET Core Web API with EF Core and SQL Server. It uses JWT-based security, layered services and repositories, Hangfire for background work, and integrations such as Azure services.
>
> My work included backend changes around driver-load attachments and document-expiry reminders. One reliability issue involved coordinating a file upload to blob storage with saving its attachment record. I added or supported transaction handling and failure-aware logic so the workflow would not silently leave inconsistent application data. I also worked on selecting expiring driver documents and formatting push notifications. These changes required understanding the request flow, EF Core queries, asynchronous operations, logs, and the mobile-facing behavior.

## Mnemonic: **S-DAT**

- **S - Shipments:** logistics lifecycle and status.
- **D - Drivers:** loads, documents, actions, mobile app.
- **A - Attachments:** blob file plus database metadata.
- **T - Tenants and transactions:** isolation and consistency.

## System mind map

```text
Mobile/Web Client
      ↓ HTTPS + JWT
ASP.NET Core Controller
      ↓ DTO validation
Service / business rules
      ↓
Repository + EF Core ─────→ SQL Server
      ↓                         ↑
Azure Blob / Notification   tenant-aware context
      ↓
Hangfire / async processing
      ↓
structured logs + monitoring
```

## End-to-end API explanation: **R-V-B-D-O**

1. **R - Request:** route, JSON DTO, JWT.
2. **V - Validate:** model validation, authorization, business rules.
3. **B - Business:** service coordinates the workflow.
4. **D - Data:** repository/EF Core queries and transaction.
5. **O - Outcome:** status code, response DTO, log, client update.

Spoken answer:

> A request first reaches an authenticated controller endpoint. ASP.NET Core binds the JSON to a DTO and validates it. The controller passes the request to a service, where business and tenant rules are applied. The repository uses EF Core against the tenant-aware SQL Server context. For related writes, we use a transaction. We return a structured response and appropriate status code, and log enough identifiers to troubleshoot the operation without logging sensitive data.

## Hero story 1: attachment and transaction

### Situation

A driver-load document required two related effects:

1. upload the physical file to Azure Blob Storage;
2. save the attachment metadata in SQL Server.

### Important technical truth

A SQL transaction cannot automatically roll back Azure Blob Storage. This is a distributed-consistency problem, not a single-database transaction.

### Safe explanation

> I wrapped the database changes in a transaction and treated the blob upload as an external operation. The code had to detect failure at either stage. If the database save failed after upload, the workflow needed compensating cleanup or a retry/reconciliation path. The goal was to prevent an attachment record pointing to no file and to avoid orphaned blobs as much as possible.

### Cross-questions

**Why is `TransactionScope` or an EF transaction not enough?**

> It protects enlisted database operations, but Azure Blob Storage is not part of the local SQL transaction. Atomicity across both systems requires a distributed protocol, which blob storage does not participate in this way, or an application pattern such as compensation, outbox, idempotency, and reconciliation.

**What order would you use?**

> Usually upload first, then save metadata. If metadata fails, attempt blob deletion and log the cleanup result. Another design is to save a Pending record, upload using its ID, then mark it Completed. A scheduled reconciliation job can clean old Pending records or orphaned blobs.

**How do you make retry safe?**

> Use a stable operation or attachment ID, deterministic blob name, and check whether the resource already exists before creating another. Database uniqueness constraints can also prevent duplicate metadata.

**What would you log?**

> Tenant ID, driver-load ID, attachment ID, blob name or safe correlation value, stage, duration, and exception. I would not log tokens or file contents.

## Hero story 2: document-expiry reminder

### Flow

```text
scheduled job
  → query active drivers and relevant attachments
  → calculate expiry window
  → exclude invalid/inactive/already-handled data
  → build readable notification
  → send push notification
  → log outcome and retry transient failure
```

### Spoken answer

> The reminder workflow is a good background-job example. A scheduled job queries documents approaching expiry, applies eligibility rules, builds a notification, and sends it to the correct users. My work included correcting the attachment query and improving notification formatting and push logic. The important concerns were tenant isolation, date boundaries, null or missing records, duplicate reminders, transient notification failures, and observability.

### Cross-questions

**How do you avoid duplicate notifications?**

> Store a notification record or idempotency key based on tenant, document, expiry window, and notification type. Before sending, check whether the same logical reminder was already completed. A unique database constraint is stronger than only an in-memory check.

**Why Hangfire?**

> It gives persistent background jobs, retries, scheduling, and a dashboard. It separates slow or scheduled work from the HTTP request while keeping the job in the .NET ecosystem.

**What if the job runs twice?**

> Assume at-least-once execution. Make the handler idempotent, use a unique key or distributed lock where appropriate, and ensure repeated execution does not corrupt state or send duplicates.

**What date/time issue matters?**

> Store instants in UTC where possible, convert for tenant/user display, define expiry-day boundaries clearly, and avoid comparing server-local dates with tenant-local dates.

## Offline/mobile synchronization

> For offline clients, the server must handle retries and potentially stale updates. I would use a client-generated operation ID for idempotency, entity versions or timestamps for conflict detection, transactions for related SQL writes, and explicit conflict responses. The server remains authoritative for business rules. Sync responses should tell the client what succeeded, failed, or needs refresh.

Cross-question: **Did you design the entire sync architecture?**

> I supported mobile-facing APIs and integration issues within the existing architecture. I understand the end-to-end concerns, but I would not claim sole ownership of the complete sync design.

## Performance answer

> I diagnose API performance from the outside inward: request duration, logs and traces, EF-generated SQL, execution plan, indexes, returned rows, and application allocations. Typical improvements are projecting only required columns, avoiding N+1 queries, using `AsNoTracking` for reads, adding suitable indexes, paginating, and reducing round trips. I validate improvement with measurements rather than assuming a rewrite is faster.

## Project challenge answer

> The challenging part of operational software is maintaining consistency when a workflow crosses a database, file storage, background jobs, and mobile clients. My approach is to identify the system of record, define failure points, make retries safe, protect database writes with transactions, and add logs and reconciliation for operations that cannot be one atomic transaction.

## Kratin project walkthrough: infrastructure, team, and ownership

> Roll On Dispatch is a multi-tenant logistics product supporting shipments, driver loads, drivers, trailers, documents, invoices, notifications, and mobile workflows. React and React Native clients call an ASP.NET Core REST API. Controllers handle HTTP contracts, services coordinate use cases, repositories and EF Core access SQL Server, and tenant resolution selects the correct customer database. Azure Blob Storage holds files while SQL stores searchable attachment metadata. Hangfire handles scheduled or in-application background jobs; separate integration boundaries handle work such as QuickBooks synchronization. Docker and Azure DevOps pipelines build and publish deployable images and migration assets.

> I worked within a cross-functional product team involving backend, web/mobile, QA, product/business, and deployment support. My personal ownership was feature implementation and debugging around driver-load attachments, document-expiry reminders, API/database behavior, logging, and mobile-facing outcomes. I collaborated across layers, but I do not claim that I designed the entire platform or owned all cloud infrastructure.

If asked team size, state the real number from memory. Never manufacture a headcount.

## God-mode STAR feature: document-expiry reminder

### S - Situation and business decision

> Drivers upload documents such as licences and insurance. Dispatch operations need the latest valid version, and drivers should be warned before it expires. Old uploads, missing expiry values, mobile-disabled drivers, or one failing notification could make reminders incorrect or stop the batch.

Clarified rules:

- Notify only drivers enabled for the mobile application.
- Consider associate/driver documents, not unrelated attachment subtypes.
- Ignore documents without an expiry date.
- When multiple versions exist, evaluate only the newest document of each type.
- Produce readable messages for upcoming and expired documents.
- A failure for one driver must not prevent remaining drivers from being processed.

### T - Task

> My task was to make selection and notification behavior match those business rules and improve diagnosability, while fitting the existing scheduled-service, repository, EF Core, and notification architecture.

### A - Action: exact implementation flow

1. The scheduled service requests eligible drivers through a repository predicate:

```csharp
var drivers = await _associateRepository.GetDriverList(
    include: "",
    predicate: d => d.IsMobileAppEnabled);
```

`Expression<Func<Driver,bool>>` is applied to `IQueryable<Driver>`, translated into a SQL `WHERE`, and executed by `ToListAsync`.

2. For each driver, attachment metadata is loaded and reduced to the relevant latest documents:

```csharp
var latestAttachments =
    (await _attachmentRepository.ListOfFiles(driver.AssociateId))
    .OfType<AssociateAttachment>()
    .Where(a => a.Expiry.HasValue)
    .GroupBy(a => a.Type)
    .Select(g => g.OrderByDescending(a => a.CreatedDatetime).First())
    .ToList();
```

3. The expiry decision is separated from message construction:

```csharp
var days = (attachment.Expiry!.Value.Date - DateTime.Today).Days;

if (ShouldSendExpiryNotification(days))
    await SendExpiryNotification(driver, attachment, days);
```

4. Formatting handles singular/plural and a generic `Other` type:

```csharp
var displayType = attachmentType.Equals("Other", StringComparison.OrdinalIgnoreCase)
    ? "document"
    : attachmentType.ToLowerInvariant();

var status = daysUntilExpiry switch
{
    > 1 => $"will expire in {daysUntilExpiry} days",
    1   => "will expire in 1 day",
    0   => "expires today",
    _   => "has expired"
};
```

5. An inner `try/catch` isolates each driver. Structured logs include driver ID, attachment type, stage, and exception rather than only a generic string.

### R - Result

> The workflow became aligned with the document-version rule, produced clearer user messages, continued processing after an individual failure, and gave support better diagnostic context. The engineering value was correctness and operability, not only fewer lines of code.

### Cross-question defense

**What tests would you write?**

- Only mobile-enabled drivers are selected.
- Null-expiry documents are skipped.
- The newest document wins for each type.
- Different document types each receive evaluation.
- `1 day`, multiple days, today, expired, and `Other` messages are correct.
- A notification exception for driver B does not prevent driver C.

**What would you optimize next?**

> The current repository call per driver can become N+1. I would query all relevant attachment metadata in a batch, project only needed fields, use `AsNoTracking`, group server-side where supported, and process large tenant sets in pages.

**How would you prevent repeat reminders?**

> Persist an idempotency record keyed by tenant, attachment, expiry milestone, and channel, enforced by a unique constraint. A condition such as `days <= 7` by itself may send the reminder on every job run.

**What about time zones?**

> Define whether expiry means the tenant's calendar day, store instants in UTC where appropriate, and compare using an explicit tenant time zone rather than relying on server-local time.
