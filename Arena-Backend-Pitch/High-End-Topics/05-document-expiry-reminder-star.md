# High-End Topic 05 — Document-Expiry Reminder: STAR Deep Dive

> **Use this as your hero feature.** It combines business value, tenant isolation, background processing, LINQ, EF/SQL data access, notifications, reliability, and future scalability.

---

## The 20-second feature pitch

> “In ROD, drivers upload compliance documents such as licences and other documents with expiry dates. The document-expiry reminder runs as tenant-aware background work, finds active mobile-app drivers’ latest document of each type, detects documents expiring within the configured week or already expired, and sends a personalized push notification. It reduces manual compliance follow-up while keeping each tenant’s driver data isolated.”

---

## S — Situation: business problem and market value

```text
Logistics/dispatch operations depend on drivers having valid documents.

Manual spreadsheet/calendar follow-up creates risks:
• missed expiry dates
• dispatch disruption
• compliance/safety exposure
• operations staff chasing drivers manually
• poor driver experience: no early reminder
```

Business outcome:

```text
detect expiry early
        ↓
notify the driver in the mobile app
        ↓
driver uploads an updated document
        ↓
fewer avoidable compliance gaps and manual follow-ups
```

Why it matters in the market:

```text
Compliance automation = operational reliability.
The value is not “a notification”; it is protecting driver readiness and dispatch continuity.
```

---

## T — Task: what the feature must guarantee

```text
For one tenant at a time:
1. Consider drivers enabled for the mobile app.
2. Consider only driver/associate attachments with an expiry date.
3. For each document type, use only the newest uploaded record.
4. Notify when expiry is within the configured seven-day threshold or expired.
5. Send a clear message with singular/plural grammar.
6. Isolate one driver/notification failure so other drivers still process.
7. Never query another tenant’s drivers/documents.
```

Why “newest document by type” is important:

```text
Driver uploads a renewed licence
but old licence remains in history
        ↓
Without newest-per-type selection
the system can warn about an obsolete document
        ↓
Incorrect notification / loss of trust
```

---

## A — Action: end-to-end ROD flow

```text
Tenant onboarding / existing job schedule
        ↓
TenantCornJobService.InitializeCronJobs(tenantId)
        ↓
RecurringJob.AddOrUpdate(... DailyDocumentExpiryReminder ...)
        ↓
daily tenant-specific Hangfire schedule
        ↓
SetDocumentExpiryReminderHandler(BackgroundJobContext)
        ↓
BackgroundJob.Enqueue<DocumentExpiryReminderService>(...)
        ↓
Custom Hangfire activator restores tenant context
        ↓
DocumentExpiryReminderService.SetDriversForDocumentExpiryReminder()
        ↓
AssociateRepository.GetDriverList(d => d.IsMobileAppEnabled)
        ↓
for each driver: AttachmentRepository.ListOfFiles(driver.AssociateId)
        ↓
select current expiring document per type
        ↓
NotificationHubService → Azure Notification Hub → FCM / Apple push
```

The recurring reminder registration is feature-flagged with `DM197581_Document_Expiry_Check`.

---

## File-and-method map

```text
RollOnDispatch/Services/TenantCornJobService.cs
  InitializeCronJobs(tenantId)
  → RecurringJob.AddOrUpdate(... SetDocumentExpiryReminderHandler ...)
        ↓
  SetDocumentExpiryReminderHandler(BackgroundJobContext rc)
  → BackgroundJob.Enqueue<DocumentExpiryReminderService>(
        service => service.SetDriversForDocumentExpiryReminder())
        ↓
RollOnDispatch/Services/DocumentExpiryReminderService.cs
  SetDriversForDocumentExpiryReminder()
        ↓
RollOnDispatch.Data/Repositories/AssociateRepository.cs
  GetDriverList(predicate: d => d.IsMobileAppEnabled)
        ↓
RollOnDispatch.Data/Repositories/AttachmentRepository.cs
  ListOfFiles(driver.AssociateId)
        ↓
DocumentExpiryReminderService LINQ decision logic
        ↓
RollOnDispatch/Services/NotificationHubService.cs
  CreateNotificationRequestModel(...)
  → RequestNotificationAsync(...)
  → Azure Notification Hub FCM/APNS calls
```

---

## Tenant safety in this feature

```text
Hangfire job has tenant ID
        ↓
CustomHangfireJobActivator restores it into IRequestContext
        ↓
repositories resolve RollOnDispatchContext using ITenantDbContextFactory
        ↓
all driver and attachment queries use that tenant database
```

The reminder service itself does not pass an arbitrary tenant ID from a UI request. Tenant selection happens before repositories are created.

---

## The exact selection logic

Current source shape:

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

Read it like this:

```text
Get active mobile-app drivers
        ↓
Get this driver’s attachment records
        ↓
Keep only AssociateAttachment subtype
        ↓
Ignore documents without Expiry
        ↓
Group records by attachment Type
        ↓
Within each type, newest CreatedDatetime wins
        ↓
Evaluate exactly one current document per type
```

Example:

| Driver | Type    | Uploaded |   Expiry | Selected?                  |
| ------ | ------- | -------: | -------: | -------------------------- |
| Maya   | Licence | Jan 2026 | Feb 2026 | No—older replacement      |
| Maya   | Licence | Feb 2026 | Feb 2027 | Yes—newest licence        |
| Maya   | Medical | Jan 2026 |       — | No—no expiry date         |
| Maya   | Other   | Mar 2026 | tomorrow | Yes—newest Other document |

---

## Expiry decision and message logic

```text
daysToExpiry = attachment.Expiry - current date

daysToExpiry <= expirationWeek (7)
        ↓ yes
send notification

daysToExpiry > 0
→ “will expire in X day/days”

daysToExpiry <= 0
→ “has expired”
```

Message rules in the current service:

```text
Attachment type “Other” → display “document”
1 day                    → “1 day”
many days                → “N days”
expired                  → “has expired”
```

Example output:

```text
Your licence will expire in 1 day. Please update it on your profile
or contact your dispatch company.

Your document has expired. Please update it on your profile
or contact your dispatch company.
```

---

## Database/data model mental picture

```text
Tenant-specific RollOnDispatch database

Associate / Driver
├── AssociateId
├── IsMobileAppEnabled
└── attachment relationship

Attachments table/entity hierarchy
BaseAttachment
├── AttachmentId
├── PrincipalId              ← driver/associate ID
├── Discriminator            ← inheritance subtype
├── Name / Location / AccessToken
├── Type
├── CreatedDatetime          ← inherited audit field
└── AssociateAttachment
    └── Expiry
```

Entity relationship:

```text
Driver (AssociateId) 1 ─── * AssociateAttachment

AssociateAttachment.PrincipalId = driver AssociateId
AssociateAttachment.Expiry      = reminder decision input
AssociateAttachment.Type        = grouping key
```

Notification delivery is external through Azure Notification Hub; notification history/read state is handled through the notification service/data path rather than being the document source of truth.

---

## Notification delivery path

```text
DocumentExpiryReminderService
  CreateNotificationMessage(...)
        ↓
NotificationHubService.CreateNotificationRequestModel(
  driverLoadId: 0,
  tags: [associateId],
  text: message)
        ↓
NotificationHubService.RequestNotificationAsync(...)
        ↓
build Android FCM v1 payload + iOS APNS payload
        ↓
Azure Notification Hub sends to tag/device
        ↓
Driver mobile app receives push
```

The driver/associate ID is used as the notification target tag in this feature.

---

## R — Result: speak honestly

Do not invent a percentage, user count, or revenue number unless you measured it.

Use this result statement:

> “The feature automated a repeatable compliance follow-up flow. It ensures that each tenant’s mobile-enabled drivers receive actionable reminders for their latest relevant documents, while a failed driver or push request is logged without stopping the rest of the tenant job.”

Engineering results visible in the implementation:

```text
✓ latest-document selection avoids stale-document reminders
✓ document type/expiry filters reduce irrelevant notifications
✓ individual driver try/catch isolates failures
✓ structured log context identifies driver and attachment failure
✓ tenant-aware Hangfire execution protects data isolation
✓ feature flag allows controlled rollout
```

---

## Reliability choices in the code

```text
Outer try/catch
→ logs fatal service failure.

Per-driver try/catch
→ a bad attachment/data/push for Driver A does not block Driver B.

Per-notification try/catch
→ send failure is recorded with driver ID and attachment type.

Feature flag
→ tenant/job behavior can be controlled during rollout.
```

---

## Design review: what I would improve next

Say this only when asked, “How would you scale or improve it?”

| Current concern                                                  | Why it matters                                          | Improvement                                                                                                         |
| ---------------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Driver loop loads attachments per driver                         | Can become N+1 database queries at large driver count   | Query eligible attachments in batches, grouped in SQL; paginate tenant drivers                                      |
| Same document can notify every daily run during seven-day window | Notification fatigue/duplicate delivery                 | Persist a reminder ledger: tenant, attachment, expiry, reminder stage, sent time; unique constraint for idempotency |
| `DateTime.Now`                                                 | Server-local time can vary                              | Use UTC (`DateTime.UtcNow`) plus tenant timezone only for display/scheduling semantics                            |
| Expiry threshold is constant                                     | Different documents/businesses can need different rules | Store rule per tenant/document type and inject a policy/strategy                                                    |
| Push provider call is external                                   | SQL transaction cannot roll it back                     | Outbox/retry design and provider delivery telemetry                                                                 |
| Entire attachment list is loaded                                 | More payload/work than necessary                        | Project only`AssociateId`, `Type`, `Expiry`, `CreatedDatetime`, then query server-side                      |

### Scalable query shape

```text
Instead of:
drivers → attachment query per driver

Prefer:
one paged query for mobile-enabled drivers
        ↓
one query for their eligible attachments
        ↓
partition/group by AssociateId + Type
        ↓
select newest per group
        ↓
enqueue/send only needed notifications
```

Add the right index in a shared-schema equivalent:

```sql
(AssociateId, Type, CreatedDatetime DESC)
INCLUDE (Expiry)
```

In ROD’s database-per-tenant model, the same index would exist in each tenant database’s attachment table.

---

## STAR answer — 2 minutes

> “A feature I can explain end to end is the driver document-expiry reminder in Roll On Dispatch. The business problem was that drivers need current documents, and manual follow-up creates compliance and dispatch risk. We wanted a driver-facing reminder before a document expires rather than waiting for operations staff to discover the issue.
>
> The feature runs as tenant-aware Hangfire background work. For the current tenant, it retrieves only drivers enabled for the mobile app. For each driver, it gets attachment records, keeps only driver document attachments with expiry dates, groups them by document type, and selects the newest upload in each group. That avoids warning the driver about an old licence after they have uploaded a renewed one.
>
> It calculates days until expiry and sends a push notification when the document is within the seven-day threshold or expired. The notification service targets the driver’s tag through Azure Notification Hub for Android and iOS. The flow has per-driver and per-notification error handling, so one data or push failure is logged but does not stop other drivers. The job runs with restored tenant context, so its repository queries are connected to the correct tenant database.
>
> I would next improve it by batching attachments to remove the per-driver query pattern and adding an idempotent reminder ledger to prevent repeated daily notifications for the same reminder stage.”

---

## Cross-questions

| Interviewer asks                      | Best answer                                                                                                                                                                      |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Why group by attachment type?         | A driver can upload multiple versions. We want the latest current document of each type, not every historical file.                                                              |
| Why exclude no-expiry attachments?    | They cannot contribute to an expiry decision and would create noise.                                                                                                             |
| What if push fails?                   | Log with driver/attachment context; do not stop other drivers. For stronger delivery reliability, use retry/outbox plus a reminder ledger.                                       |
| Is this idempotent today?             | It is safe to process repeatedly, but daily runs can produce repeated reminders in the threshold window. A persisted send ledger would make delivery idempotent by stage.        |
| How is tenant isolation maintained?   | The scheduled job restores tenant context before repositories create the tenant EF Core context.                                                                                 |
| What is the biggest performance risk? | Attachment lookup inside the driver loop: an N+1 pattern as driver count grows.                                                                                                  |
| How would you test it?                | Mock driver/attachment/notification dependencies; assert newest-per-type, threshold, message grammar, per-driver failure isolation, and tenant job context in integration tests. |
