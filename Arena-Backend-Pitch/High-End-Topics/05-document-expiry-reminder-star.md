# High-End Topic 05 — ROD Document-Expiry Reminder

> **Verified against `dm-api`, `dm-web`, and `dm-driver-mobile-app`.**
> This is a strong STAR feature because it joins a business problem, tenant-aware background work, LINQ, SQL-backed job storage, Azure push delivery, error isolation, and client impact.

---

## 0. The 25-second answer

> “In Roll On Dispatch, drivers upload compliance documents with expiry dates. To reduce manual follow-up and compliance risk, we run a tenant-aware daily Hangfire reminder. For each mobile-enabled driver, it finds only the newest attachment of each document type, ignores attachments without an expiry date, and sends a push reminder when the document is within seven days of expiry or already expired. The job restores the tenant context before its repositories are created, so it reads only that tenant’s database. Driver-level and notification-level failures are logged and do not stop the rest of the tenant’s drivers.”

**Memory hook: `SCHEDULE → SCOPE → SELECT → SEND → SURVIVE`**

```text
SCHEDULE  daily Hangfire work per tenant
SCOPE     restore that tenant before EF/repositories are resolved
SELECT    latest valid document of each type
SEND      targeted Azure Notification Hub push
SURVIVE   isolate one driver/push failure from the batch
```

---

## 1. First, separate the two document-expiry features

This prevents a very common interview mistake.

| Feature                                          | Purpose                              | Trigger/rule                                                            | Main output                                             | Client impact                                                          |
| ------------------------------------------------ | ------------------------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Document-expiry reminder** — this guide | Tell the driver to update a document | Daily;`<= 7` days or expired                                          | Targeted mobile push                                    | Driver receives an alert; no document deep link in the current payload |
| **Document-status tracking**               | Give dispatch/web a status view      | Separate 2:00 daily job; also stores expiring status for a 14-day range | `DriverDocumentStatus` records / expiry status fields | Web driver cards show expired or expiring indicators                   |

They share the same domain data — driver attachments and expiry dates — but they are **not the same code path** and use different feature flags.

```text
Reminder:        DM197581_Document_Expiry_Check
Status tracking: DM243129_DRIVER_DOCUMENT_STATUS_TRACKING
```

---

## 2. S — Situation: business requirement and value

```text
Driver has licence / insurance / compliance document
        ↓
Document expires while operations are busy
        ↓
Manual calendar or spreadsheet follow-up can be missed
        ↓
Compliance risk + driver cannot be dispatched + dispatcher chases driver
```

**Requirement translated into engineering rules**

```text
For one tenant:
  1. Process only drivers enabled for the mobile app.
  2. Process only associate/driver attachments with an expiry date.
  3. If a document was renewed, use the latest version — never the old one.
  4. Notify at seven days or fewer, including already expired documents.
  5. Deliver to that driver’s registered device(s).
  6. A bad driver record or failed push must not stop other drivers.
  7. Never read a different tenant’s driver data.
```

**Why newest-per-type matters**

```text
Old licence: uploaded Jan, expires this week
New licence: uploaded Feb, expires next year

If we inspect every historical file → false alert.
If we choose newest Licence record → correct business state.
```

---

## 3. Domain and data mental model

```text
Tenant database (one tenant at a time)

Driver / Associate
├── AssociateId
├── Name
└── IsMobileAppEnabled
        1
        │
        │ PrincipalId = AssociateId
        *
BaseAttachment
├── AttachmentId
├── PrincipalId
├── Type
├── CreatedDatetime
├── Discriminator
├── Name / Location / AccessToken
└── AssociateAttachment
    └── Expiry : DateTime?
```

```text
Driver 1 ── 0..many attachments
Attachment.Type + CreatedDatetime → chooses the current version
Attachment.Expiry                → decides whether to remind
```

`AssociateAttachment` is a subtype of `BaseAttachment`; that is why the code uses `.OfType<AssociateAttachment>()`. It is not a cast for convenience — it deliberately excludes files belonging to other attachment use cases.

---

## 4. Complete execution flow — from requirement to push

```text
Tenant is provisioned / tenant job schedule is initialized
        │
        ▼
TenantCornJobService.InitializeTenantCronJobs(tenantId)
        │
        └── creates a daily tenant coordinator job
                │
                ▼
        InitializeCronJobs(tenantId)
                │
                ├── checks Feature Manager flag
                │   DM197581_Document_Expiry_Check
                │
                └── registers tenantId-Document_Expiry_Reminder daily
                        │
                        ▼
SetDocumentExpiryReminderHandler(BackgroundJobContext)
        │
        └── BackgroundJob.Enqueue<DocumentExpiryReminderService>(...)
                │
                ▼
Hangfire custom activator creates a DI scope
        │
        └── restores tenantId into IRequestContext
                │
                ▼
EF repositories resolve the current tenant database
        │
        ▼
DocumentExpiryReminderService.SetDriversForDocumentExpiryReminder()
        │
        ├── query mobile-enabled drivers
        ├── for each driver, get attachments
        ├── choose latest eligible attachment per type
        ├── decide expiry window
        └── target driver tag through Azure Notification Hub
                │
                ▼
FCM v1 (Android) / APNS (iOS) → registered driver device
```

### Exact code-path map

```text
RollOnDispatch/Startup.cs
  AddHangfire(... UseSqlServerStorage(AppGlobal) ...)
  AddHangfireServer()
  GlobalConfiguration.UseFilter(new BackgroundJobFilter())
        ↓
RollOnDispatch/Services/TenantCornJobService.cs
  InitializeCronJobs(tenantId)
  SetDocumentExpiryReminderHandler(BackgroundJobContext)
        ↓
TenantManagement/Common/HangfireTenantContext.cs
  BackgroundJobFilter.OnCreating() stores BackgroundJobContext in job metadata
  CustomHangfireJobActivator.BeginScope() restores IRequestContext tenant context
        ↓
RollOnDispatch/Services/DocumentExpiryReminderService.cs
  SetDriversForDocumentExpiryReminder()
        ↓
RollOnDispatch.Data/Repositories/AssociateRepository.cs
  GetDriverList(... predicate ...)
        ↓
RollOnDispatch.Data/Repositories/AttachmentRepository.cs
  ListOfFiles(driver.AssociateId)
        ↓
RollOnDispatch/Services/NotificationHubService.cs
  CreateNotificationRequestModel() → RequestNotificationAsync()
        ↓
Microsoft.Azure.NotificationHubs → FCM v1 / APNS
```

---

## 5. Tenant safety — why a background job still knows the customer

There is no HTTP request and no JWT when Hangfire runs. Therefore it must carry tenant identity explicitly.

```text
Recurring job is created while BackgroundJobContext(tenantId) exists
        ↓
BackgroundJobFilter writes that context into Hangfire job parameters
        ↓
CustomHangfireJobActivator reads it for the executing job
        ↓
IRequestContext.SetBackgroundContext(tenantId)
        ↓
TenantDbContextFactory builds SQL Server options for that tenant
        ↓
AssociateRepository / AttachmentRepository query that tenant DB
```

Relevant shape:

```csharp
// TenantCornJobService
using var jc = new BackgroundJobContext(tenantId);
RecurringJob.AddOrUpdate<TenantCornJobService>(
    documentExpiryReminderJobName,
    rc => rc.SetDocumentExpiryReminderHandler(jc),
    Cron.Daily);

// CustomHangfireJobActivator
var jc = context.GetJobParameter<BackgroundJobContext>(nameof(BackgroundJobContext));
var requestContext = serviceScope.ServiceProvider.GetRequiredService<IRequestContext>();
requestContext.SetBackgroundContext(jc.TenantId);
```

**Interview line:**

> “A background job cannot rely on `HttpContext.User`, so ROD persists the tenant context with the Hangfire job and restores it into the DI scope before tenant-aware repositories are constructed.”

---

## 6. Selection and decision logic — line by line

```csharp
var drivers = await _associateRepository.GetDriverList(
    include: "",
    predicate: d => d.IsMobileAppEnabled);

var latestAttachments = (await _attachmentRepository.ListOfFiles(driver.AssociateId))
    .OfType<AssociateAttachment>()
    .Where(a => a.Expiry.HasValue)
    .GroupBy(a => a.Type)
    .Select(g => g.OrderByDescending(a => a.CreatedDatetime).First())
    .ToList();
```

```text
predicate d => d.IsMobileAppEnabled
  → EF translates it to SQL WHERE; only mobile-capable drivers are selected.

ListOfFiles(driver.AssociateId)
  → retrieves attachments whose PrincipalId is that driver’s AssociateId.

OfType<AssociateAttachment>()
  → retain driver/associate document subtype only.

Where(Expiry.HasValue)
  → expiry-less files cannot create an expiry reminder.

GroupBy(Type)
  → a driver can have multiple historical licences, insurance records, etc.

OrderByDescending(CreatedDatetime).First()
  → newest uploaded document wins for each type.
```

### Decision rule

```csharp
var daysToExpiry = ((DateTime)attachment.Expiry - DateTime.Now).Days;
var shouldNotify = daysToExpiry <= 7;
```

| Example                  | `daysToExpiry` | Result                   |
| ------------------------ | ---------------: | ------------------------ |
| Expiry is 10 days away   |               10 | no reminder              |
| Expiry is 3 days away    |                3 | remind                   |
| Expiry is tomorrow       |                1 | remind; singular “day” |
| Expiry is today / passed |    0 or negative | remind; “has expired”  |

The current service uses a constant of `7`. It also treats expired documents as eligible because negative values satisfy `<= 7`.

### Message rule

```text
Type = Other        → say “document”, not “other”
days = 1            → “will expire in 1 day”
days > 1            → “will expire in N days”
days <= 0           → “has expired”
```

Example:

```text
Your insurance will expire in 3 days. Please update it on your profile
or contact your dispatch company.
```

---

## 7. Notification integration — backend to mobile device

### A. Mobile registers its device first

```text
Driver signs in to React Native app
        ↓
PushNotificationManager gets platform push token + stable installation ID
        ↓
For Driver role, tags = ["Driver", userId]
        ↓
PUT /api/pushnotification/installations
        ↓
NotificationHubService.CreateOrUpdateInstallationAsync(...)
        ↓
Azure Notification Hub stores installation, platform, token, and tags
```

The app uses React Native Firebase Messaging plus native push-notification libraries. The backend validates a non-empty installation ID, push channel, and platform before sending the installation to Azure Notification Hubs.

### B. Reminder targets that registration

```csharp
await _notificationHubService.CreateNotificationRequestModel(
    driverLoadId: 0,
    tags: new[] { attachment.AssociateId.ToString() },
    text: notificationText);
```

```text
Document reminder uses the driver/associate ID as the target tag
        ↓
NotificationHubService builds Android FCM v1 + iOS APNS payloads
        ↓
Azure Notification Hub sends only to matching registrations
```

### C. What the mobile client does

```text
Android foreground:
Firebase messaging().onMessage(...)
→ creates a local notification with title/body.

Background:
the OS/provider displays the push notification.

Tap handling:
the current driver flow checks driverLoadId.
This reminder sends driverLoadId = 0,
so it informs the driver but does not deep-link them into a document screen today.
```

**Good ownership answer:**

> “The notification is actionable in its wording — update the document on the profile — but the current reminder payload does not include an attachment ID or document route. My next improvement would add an explicit action and attachment ID so a tap can navigate directly to the document update screen.”

---

## 8. Frontend impact — accurate version

The **reminder job itself** is backend-triggered; it does not need a React page to start it.

```text
Web app contribution to reminder domain:
DocumentUpload component collects document Type and Expiry.
Those values become attachment records used by the reminder job.
```

The web app also shows document health on driver cards:

```text
Attachment / DriverDocument response
        ↓
documentExpiryStatus = Active | ExpiringSoon | Expired
        ↓
DriverUtils groups expired and expiring documents
        ↓
useDriverCard creates a dispatcher-facing status message
```

But be precise:

```text
Web status UI  ≠  this reminder push job

Web status comes from the related DriverDocumentStatus flow.
The reminder job sends push directly to mobile-enabled drivers.
```

There are two different thresholds in the current code base:

```text
Reminder service          → 7 days
Status-tracking service   → up to 14 days for “Expiring” records
```

Do not claim they are the same rule. If asked, say they are related operations with independently implemented business windows; aligning them would be a product/architecture review item.

---

## 9. Error handling and what “robust” means here

```text
Scope 1 — outer job failure
GetDriverList / unexpected batch failure
→ logs “Fatal error in DocumentExpiryReminderService”

Scope 2 — one driver failure
attachment read / malformed data / LINQ failure
→ logs DriverName + AssociateId
→ continue with the next driver

Scope 3 — one push failure
notification call fails
→ logs DriverName + AssociateId + AttachmentType
→ continue with remaining documents/drivers
```

### What is good in the implementation

```text
✓ Failure isolation: Driver A cannot block Driver B.
✓ Structured context: logs carry driver identity and attachment type.
✓ Provider service catches Azure Hub exceptions and returns false.
✓ Feature flag lets the team control rollout before enabling the daily schedule.
✓ Hangfire dashboard/job storage gives operational visibility for scheduled work.
```

### Honest limitation — say it like an engineer

```text
The reminder service catches and logs its outer exception instead of rethrowing.
So Hangfire may regard that job execution as successful; it is not a durable
delivery guarantee by itself.

Also, the reminder call does not check the bool returned by
CreateNotificationRequestModel(). A provider failure that returns false should
be recorded as a retryable delivery failure.
```

**Strong next design**

```text
Reminder decision
        ↓
write NotificationOutbox / ReminderLedger in SQL transaction
        ↓
background sender delivers push
        ↓
mark Sent only after provider success
        ↓
retry transient failures with backoff
```

That creates auditability, retry control, and idempotency rather than relying on best-effort push delivery.

---

## 10. Current tests — what actually exists

**Library:** xUnit with Moq.

File: `UnitTests/ServiceTests/DocumentExpiryReminderServiceTests.cs`

| Existing test                                           | Setup                                                    | What it proves                                |
| ------------------------------------------------------- | -------------------------------------------------------- | --------------------------------------------- |
| `...ShouldSendNotifications_WhenDocumentsAreExpiring` | One mobile-enabled driver; Insurance expiry ~3 days away | `CreateNotificationRequestModel` is invoked |
| `...ShouldLogError_WhenDriverProcessingFails`         | Attachment repository throws for one driver              | Per-driver error is logged once               |
| `...ShouldLogFatalError_WhenRepositoryFails`          | Driver repository throws                                 | Outer fatal error is logged once              |

### What these tests do **not** currently prove

```text
□ 8-day document does not notify
□ expired document does notify
□ no-expiry attachment is ignored
□ newest attachment is selected over old one
□ one day uses singular grammar
□ “Other” is rendered as “document”
□ a notification return value of false is handled
□ one failed driver still allows a second driver to be processed
□ tenant context is restored in a real Hangfire execution
□ mobile installation + Azure Hub delivery works end-to-end
```

### Test cases I would add first

```text
1. Given old + renewed Licence, assert only renewed Licence is evaluated.
2. Given expiry = Now + 8 days, assert no hub request.
3. Given expiry = Now - 1 day, assert “has expired”.
4. Given type = Other, assert message says “document”.
5. Given driver 1 throws and driver 2 is valid, assert driver 2 receives push.
6. Given notification service returns false/throws, assert a retryable failure is logged.
7. Integration test a queued tenant job: tenant A’s context cannot read tenant B’s data.
```

**Interview-safe phrase:**

> “The current unit tests cover the happy path and the two error boundaries. I would extend them around idempotency, boundary dates, newest-document selection, and tenant-context integration because those are the highest-risk business rules.”

---

## 11. Dependencies and configuration

| Dependency                                         | Role in the feature                                                                       |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Hangfire + Hangfire.SqlServer**            | Persists recurring/enqueued job metadata and processes work in the app’s Hangfire server |
| **SQL Server app-global database**           | Hangfire storage; separate from tenant operational databases                              |
| **TenantDbContextFactory + IRequestContext** | Selects/builds the correct tenant EF Core context for job execution                       |
| **EF Core repositories**                     | Reads drivers and attachments from the selected tenant database                           |
| **Microsoft.FeatureManagement**              | Gates registration of the reminder schedule                                               |
| **Azure Notification Hubs SDK**              | Sends tagged native notification payloads                                                 |
| **FCM v1 / APNS**                            | Downstream Android and iOS push networks                                                  |
| **Mobile push registration**                 | Supplies platform token, installation ID, and driver tag to Azure Hub                     |
| **Logging**                                  | Records batch, driver, and notification failures for diagnosis                            |

Configuration concepts used by the notification service:

```text
NotificationHub:NotificationHubConnectionString
NotificationHub:NotificationHubName

Hangfire SQL storage
→ app-global connection string, not the per-tenant operational connection string
```

Never put or repeat real connection strings in notes, commits, logs, or interview screenshares.

---

## 12. Performance and scaling discussion

### Current trade-off

```text
1 query: get all mobile-enabled drivers
N queries: get attachment list for each driver

Total = N+1 query pattern per tenant run
```

This is simple and clear for a modest tenant, but it can become the cost center for a tenant with many drivers.

### Strong next iteration

```text
page mobile-enabled drivers
        ↓
fetch only eligible attachment columns for the page
        ↓
partition by (PrincipalId, Type)
        ↓
choose max CreatedDatetime in SQL
        ↓
produce reminder candidates
        ↓
write idempotent outbox records
        ↓
send in controlled batches
```

Suggested attachment index for the equivalent tenant table:

```sql
CREATE INDEX IX_Attachments_Principal_Type_Created
ON dbo.Attachments (PrincipalId, Type, CreatedDatetime DESC)
INCLUDE (Expiry, Discriminator);
```

### Review points

| Concern                                   | Why it matters                                        | Better design                                                                |
| ----------------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| Daily repeat during seven-day window      | Push fatigue and duplicate delivery                   | Reminder ledger with unique key`(TenantId, AttachmentId, Expiry, Stage)`   |
| `DateTime.Now`                          | Server-local date/time semantics can drift            | Use UTC for storage/compare; convert only for tenant display/schedule policy |
| Constant seven days                       | Different documents/tenants can need different policy | Tenant/document-type reminder rule configuration                             |
| External push cannot join SQL transaction | Database success and push success can disagree        | Transactional outbox + retry worker                                          |
| One batch per tenant can be large         | Long jobs / pressure on DB/provider                   | Pagination, batching, queue concurrency controls, telemetry                  |

---

## 13. STAR answer — 2 minutes

> “A feature I can walk through end to end is the document-expiry reminder in Roll On Dispatch. The problem was operational compliance: drivers can have licences or insurance documents expire, and manual follow-up creates dispatch risk and unnecessary work for operations.
>
> We designed it as tenant-aware scheduled processing rather than a user request. Hangfire registers a daily recurring job for each tenant behind a feature flag. Because background work has no JWT or HTTP request, the job carries a `BackgroundJobContext`; the custom Hangfire activator restores its tenant ID into `IRequestContext` before the repositories and EF context are resolved.
>
> The service gets only mobile-enabled drivers. For each driver it retrieves attachments, keeps `AssociateAttachment` records with an expiry date, groups by document type, and chooses the most recently uploaded record. That is important because an old licence may still exist after a driver has uploaded a renewal. It sends a reminder within seven days or after expiry through Azure Notification Hubs, targeted using the driver’s registration tag. Android and iOS delivery then use FCM and APNS.
>
> We isolated errors at driver and notification level, so a bad record or failed push is logged with driver and attachment context without blocking the rest of the job. The existing xUnit/Moq tests cover notification invocation and the driver/batch error boundaries. My next improvement would be a reminder ledger and outbox so notifications are idempotent, retryable, and directly traceable.”

---

## 14. Fast cross-questions

| Question                                 | Strong answer                                                                                                                                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Why Hangfire, not an API request?        | This is time-based work and can be slow. A request should return quickly; Hangfire persists and executes the scheduled work independently.                                                       |
| Why only mobile-enabled drivers?         | The delivery channel is mobile push. Filtering avoids a reminder the driver cannot receive through that channel.                                                                                 |
| Why`OfType<AssociateAttachment>()`?    | The attachment store has a base type. We must process only the subtype that represents driver/associate documents with expiry metadata.                                                          |
| Why group by type?                       | To evaluate the current version of each document type, not every historical upload.                                                                                                              |
| How does it know the tenant without JWT? | Hangfire stores`BackgroundJobContext`; the custom activator restores it into `IRequestContext`, then `TenantDbContextFactory` selects the tenant DB.                                       |
| Is it fully idempotent today?            | No. It may send daily reminders throughout the seven-day window. A persistent reminder ledger/outbox would make each stage idempotent.                                                           |
| What happens when Azure Hub fails?       | The feature logs the failure and continues. Stronger reliability needs a checked result plus outbox/retry and delivery telemetry.                                                                |
| What is the current performance risk?    | Per-driver attachment lookup is N+1. Batch/project candidate attachments server-side as the tenant grows.                                                                                        |
| What does the web app do?                | It captures expiry on upload and separately shows document status on driver cards. The reminder itself pushes to mobile; the web status flow is related but separate.                            |
| What does the mobile app do?             | It registers the device token and user tags with the API/Azure Hub, then displays the incoming native push. This  reminder currently has no document deep link because`driverLoadId` is zero. |

---

## 15. One-line evidence map

```text
Scheduling:      TenantCornJobService.InitializeCronJobs + SetDocumentExpiryReminderHandler
Business rule:   DocumentExpiryReminderService.SetDriversForDocumentExpiryReminder
Tenant context:  BackgroundJobFilter + CustomHangfireJobActivator + RequestContext
Data:            AssociateRepository.GetDriverList + AttachmentRepository.ListOfFiles
Push:            NotificationHubService + Azure Notification Hubs
Mobile:          PushNotificationManager + PUT /api/pushnotification/installations
Web:             DocumentUpload and DriverCard expiry status display
Tests:           DocumentExpiryReminderServiceTests (xUnit + Moq)
```
