# Pratham Round 2 — Practical Backend Master Sheet

> **Goal:** answer with a real flow, a precise name, and an honest boundary. Do not turn an interview answer into a cloud-services shopping list.

## 0. Truth guardrail — say only what you can defend

### Source-backed in Roll On Dispatch

| Area                   | Service / package                                                            | Evidence to name in an interview                                                                                                 |
| ---------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Object files           | **Azure Blob Storage** / `Azure.Storage.Blobs`                       | `AttachmentRepository.UploadBlob` creates `BlobServiceClient`, uses a tenant-named container and `BlobClient.UploadAsync`. |
| Push notifications     | **Azure Notification Hubs** / `Microsoft.Azure.NotificationHubs`     | `NotificationHubService` creates `NotificationHubClient` and sends FCM v1/APNS notifications.                                |
| Messaging              | **Azure Service Bus** / `Azure.Messaging.ServiceBus`                 | `MessageBrokerService.PublishAddRequests` creates `ServiceBusClient` and sender, then sends `ServiceBusMessage`.           |
| Email                  | **Azure Communication Services Email** / `Azure.Communication.Email` | `AzureEmailService` uses `EmailClient`.                                                                                      |
| Build + image registry | **Azure DevOps Pipelines + Azure Container Registry**                  | `azure-pipeline.yml` tests, publishes an artifact, builds/tags/pushes a Docker image to ACR.                                   |
| Background processing  | **Hangfire + SQL Server storage**                                      | Startup configures`UseSqlServerStorage`; tenant jobs are scheduled from `TenantCornJobService`.                              |

### Do **not** claim these as current ROD implementation without deployment evidence

- App Service / AKS / Azure SQL deployment details.
- Explicit multi-part Azure Blob upload (`StageBlockAsync` / `CommitBlockListAsync`). Current ROD upload streams an `IFormFile` through a `MemoryStream` and calls `UploadAsync`.
- OpenTelemetry or Application Insights exporter configuration. The source shows `ILogger` and request logging, not a verified OTel exporter setup.

**Strong answer:** “I can explain the integration code and our CI pipeline from source. For resources operated outside the repository, I describe the release design, not pretend I personally configured them.”

---

## 1. Azure answer — 45 seconds

> “In Roll On Dispatch, I worked in an ASP.NET Core modular monolith. Tenant operational data is in SQL Server. For files, `AttachmentRepository` uses `Azure.Storage.Blobs`: it resolves a tenant container, uploads the blob, and persists attachment metadata in SQL in a transaction. We use `Microsoft.Azure.NotificationHubs` to target the driver mobile app through FCM/APNS. For asynchronous integration there is `Azure.Messaging.ServiceBus`, and email is implemented through Azure Communication Services. In delivery, Azure DevOps runs tests, packages migration assets, builds a Docker image, and pushes the versioned image to Azure Container Registry. I focus on correlation, retries, tenant isolation, and safe promotion between environments.”

If challenged: **name the class / method, then explain the responsibility.**

---

## 2. Blob upload — exact ROD flow

### Say this flow

```text
Web / mobile multipart form-data
  -> AssociateController.UploadFile([FromForm] AttachmentRequestModel)
  -> AttachmentService.UploadFile<AssociateAttachment>()
  -> AttachmentRepository.UploadBlob(IFormFile, BaseAttachment)
  -> BlobServiceClient -> tenant container -> BlobClient.UploadAsync
  -> TransactionScope: replace same-name DB record + SaveChangesAsync
  -> API response with attachment metadata / location
```

### The names worth remembering

```csharp
// Controller: multipart binding
public async Task<IActionResult> UploadFile(
    [FromForm] AttachmentRequestModel attachment)
{
    await _attachmentService.UploadFile<AssociateAttachment>(attachment);
    return Ok();
}

// Repository: simplified shape of the real flow
var blobService = new BlobServiceClient(_configuration["AzureStorage"]);
var container = blobService.GetBlobContainerClient(_requestContext.TenantId.ToString());
await container.CreateIfNotExistsAsync();

var blob = container.GetBlobClient($"AssociateAttachment/{attachment.PrincipalId}/{file.FileName}");
await blob.UploadAsync(fileStream);

using var scope = new TransactionScope(
    TransactionScopeOption.RequiresNew,
    new TransactionOptions { IsolationLevel = IsolationLevel.ReadCommitted },
    TransactionScopeAsyncFlowOption.Enabled);

// remove old metadata for the same file, insert attachment metadata
await _context.SaveChangesAsync();
scope.Complete();
```

### Why Blob + SQL metadata, rather than file bytes in SQL?

`Blob = cheap durable file/object storage.`
`SQL = searchable business metadata: owner, type, expiry, name, location, audit fields.`

It keeps large file I/O out of primary relational tables while preserving transactional business state as far as possible.

### The interviewer trap: “How does chunking work?”

**Honest start:** “This ROD code path does not show application-level chunking; it receives the whole `IFormFile`, copies to a stream, then calls Blob upload. For large uploads, I would change the design.”

```text
1. Client starts UploadSession (tenant/user/file name/size/hash).
2. API authorizes ownership and returns upload ID + safe part size (for example 5–10 MB).
3. Client uses File.slice() and uploads part N with idempotency key/hash.
4. API stages each part with BlockBlobClient.StageBlockAsync.
5. SQL records upload session and received-part status.
6. After all validated parts: CommitBlockListAsync.
7. Only then create active Attachment metadata in SQL.
8. Hangfire cleans abandoned sessions; retry only failed part.
```

For very large public-client uploads, issue a short-lived **tenant-scoped SAS URL** so the browser uploads to Blob directly. The API still owns authorization, size/type rules, completion, and metadata—not the client.

---

## 3. Push notification answer

> “The driver app registers an installation after login. The backend’s `PushNotificationController` receives it and `NotificationHubService` creates or updates its installation in Azure Notification Hubs. The service sends an FCM v1 or APNS payload tagged to the right user/role. For the document-expiry job, `DocumentExpiryReminderService` builds a `NotificationRequestModel` and calls `INotificationHubService`; the mobile app receives it through Firebase/APNS.”

```text
Driver Mobile App -> PUT api/pushnotification/installations
  -> PushNotificationController -> NotificationHubService
  -> Azure Notification Hubs -> FCM / APNS -> phone

Hangfire expiry job -> DocumentExpiryReminderService
  -> INotificationHubService -> Notification Hub -> driver phone
```

**Push is not a database truth.** It is a best-effort alert. The API/database remain the source of truth; app refresh/deep link should re-read permissions and current data.

---

## 4. STAR feature: Driver document-expiry reminder — 90 seconds

> **Situation:** Driver licence, insurance, and other compliance documents can expire. Dispatch needs visibility before an ineligible driver is used.
>
> **Task:** Notify active mobile-app drivers before expiry without sending duplicate alerts for old replacements, and keep one driver failure from killing the full daily batch.
>
> **Action:** A tenant feature flag enables a daily Hangfire recurring job. `TenantCornJobService.InitializeCronJobs` registers the work; the handler enqueues `DocumentExpiryReminderService.SetDriversForDocumentExpiryReminder`. The service loads mobile-app drivers with a repository predicate, fetches their attachments, keeps `AssociateAttachment` records with an expiry, groups by attachment type, and chooses the newest one. It applies the 7-day expiry rule, builds singular/plural and generic-document messages, then sends through `INotificationHubService`. It logs tenant/driver/attachment context and catches per-driver failure so later drivers still run.
>
> **Result:** The workflow gives drivers advance notice and keeps the job operationally diagnosable. Tests verify send behaviour, a driver failure log, and a repository-level fatal error log. A future hardening step is durable retry/idempotency for the external notification side effect.

### End-to-end visual

```text
Daily recurring job (Hangfire / SQL storage)
  -> tenant job context
  -> SetDriversForDocumentExpiryReminder()
  -> GetDriverList(driver => driver.IsMobileAppEnabled)
  -> ListOfFiles(AssociateId)
  -> AssociateAttachment + Expiry + newest document per Type
  -> <= 7 days or already expired?
  -> NotificationHubService
  -> Azure Notification Hubs -> FCM/APNS -> driver app
```

**Do not merge two flows:** this is the reminder notification. Separate Driver Document Status tracking writes dashboard status records on a different schedule/range.

Full deep dive: [Document expiry reminder STAR](/Users/RajeshPareek/Downloads/engineering-lab-fresh/Arena-Backend-Pitch/High-End-Topics/05-document-expiry-reminder-star.md).

---

## 5. Telemetry / slow API — production answer

### P95 in one line

**P95 latency = 95% of requests finish at or below this time; the slowest 5% are worse.** Average can look good while users experience painful tail latency.

### Speak accurately about ROD

> “The code base has structured application logging through `ILogger` and request logging. I would not claim the current source has OpenTelemetry configured if I cannot point to its exporter setup. For production telemetry, I would add it deliberately.”

### Design I would implement

```text
ASP.NET request
  -> trace ID / correlation ID
  -> controller + service spans
  -> EF/SQL dependency timing
  -> HttpClient / Service Bus dependency timing
  -> Azure Monitor / Application Insights or OTLP collector
  -> dashboard: RPS, error %, p50/p95/p99, DB duration, external failures
  -> alerts: sustained 5xx, p95 breach, queue backlog, dependency failure
```

Typical .NET packages for this **proposed** setup are `OpenTelemetry.Extensions.Hosting`, `OpenTelemetry.Instrumentation.AspNetCore`, `OpenTelemetry.Instrumentation.Http`, and `OpenTelemetry.Instrumentation.SqlClient`, plus the chosen Azure Monitor or OTLP exporter.

### Slow API: the answer sequence

```text
1. Confirm scope: one endpoint? one tenant? all regions? p95/p99 or average?
2. Trace a slow request: controller, DB, blob, external HTTP, serialization.
3. Inspect generated SQL + actual execution plan + logical reads.
4. Fix the demonstrated bottleneck: projection/index/query shape/N+1/cache/async boundary.
5. Load-test and compare before/after p95, error rate, DB CPU—not just local time.
6. Alert on regression and retain a rollback path.
```

Never log JWTs, authorization headers, raw connection strings, or private document contents.

---

## 6. CI/CD, artifact, release flow

### Actual CI source flow

```text
Push / PR to dev, test, main
  -> Azure DevOps `azure-pipeline.yml`
  -> restore private packages + dotnet test (PR/dev path)
  -> generate feature-flag configuration
  -> copy migration/source release assets
  -> publish artifact: dm-backend-azure-webapp
  -> docker build
  -> tag with Build ID / version
  -> ACR login
  -> push image to Azure Container Registry
```

`Artifact` = a versioned, immutable output produced by CI for another stage to consume. It can be a ZIP, compiled files, migration scripts, test reports, or image reference. Here the pipeline publishes migration/source release assets as a named build artifact; the container image is stored in ACR.

### Explain a safe release flow (not claim it exists in this one YAML)

```text
Choose immutable image + migration artifact
 -> approve/promote same version to environment
 -> backup/compatibility check
 -> apply reviewed migration in controlled step
 -> deploy image with environment config/secrets
 -> health/readiness + smoke test
 -> observe p95/errors/dependencies
 -> rollback image; use expand/contract migrations for DB rollback safety
```

**Important:** The checked-in pipeline proves CI/build/ACR publication. It does not itself prove the final production deployment job. Say exactly that if asked.

---

## 7. SQL — exact practical questions

### Window functions in 15 seconds

| Function         | Meaning                                                                |
| ---------------- | ---------------------------------------------------------------------- |
| `ROW_NUMBER()` | Unique sequence per partition; best for keeping exactly one duplicate. |
| `RANK()`       | Same rank for ties, then gaps.                                         |
| `DENSE_RANK()` | Same rank for ties, no gaps.                                           |
| `LAG()`        | Previous row’s value, without self join.                              |

### Delete duplicates; keep the newest `UserId`

```sql
BEGIN TRANSACTION;

WITH Ranked AS
(
    SELECT UserId, Email,
           ROW_NUMBER() OVER
           (
               PARTITION BY Email
               ORDER BY UserId DESC
           ) AS rn
    FROM dbo.Users
)
DELETE FROM Ranked
WHERE rn > 1;

-- Verify count/result before COMMIT in real production work.
ROLLBACK TRANSACTION;
```

**Why this works:** partition creates one group per email; newest ID gets `rn = 1`; deletion removes only `rn > 1`.

### Execution-plan walkthrough

```sql
SELECT ShipmentId, CreatedDatetime, Status
FROM dbo.Shipments
WHERE CarrierId = @carrierId
  AND IsActive = 1
ORDER BY CreatedDatetime DESC;
```

1. In SSMS enable **Include Actual Execution Plan** (`Ctrl+M`), then execute.
2. Read biggest-cost operators and warnings. Common red flags: full scan on a selective predicate, repeated Key Lookup, expensive Sort, spills, big estimated-vs-actual row mismatch.
3. Match the index to equality filters first, then ordering; include selected columns only if it removes lookups:

```sql
CREATE INDEX IX_Shipments_Carrier_Active_Created
ON dbo.Shipments (CarrierId, IsActive, CreatedDatetime DESC)
INCLUDE (ShipmentId, Status);
```

4. Re-run actual plan plus `SET STATISTICS IO, TIME ON`; compare duration and logical reads. A scan is not automatically bad—prove the bottleneck before indexing. Extra indexes speed reads but slow writes and consume storage.

More drills: [Pratham SQL crash sprint](/Users/RajeshPareek/Downloads/engineering-lab-fresh/Arena-Backend-Pitch/14-pratham-one-day-sql-crash-sprint.md).

---

## 8. Final 10-minute backend cards

- **Blob upload**: controller `[FromForm]` → service → Blob `UploadAsync` → SQL metadata transaction.
- **Chunk upload**: actual ROD no explicit chunks; design = `StageBlockAsync` → validate → `CommitBlockListAsync`.
- **Notifications**: installation registration → Notification Hub → FCM/APNS; a push does not replace API truth.
- **SaaS**: tenant identity comes from trusted server-side request context; tenant storage/container is selected server-side.
- **Telemetry**: p95, error rate, dependency duration, trace correlation; do not claim unverified OTel.
- **CI/CD**: test → artifact → Docker image → immutable tag → ACR → approved deploy → health check.
- **Plan**: actual plan, not guessed plan; measure logical reads before/after.
