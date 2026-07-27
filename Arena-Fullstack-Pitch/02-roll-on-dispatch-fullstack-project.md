# 2. Roll On Dispatch - Full-Stack Project Pitch

## 60-second pitch

> Roll On Dispatch is a multi-tenant logistics platform for shipments, customers, brokers, drivers, driver loads, locations, documents, invoicing, reports, and dispatch operations. The web application uses React 18, TypeScript, Redux Toolkit, RTK Query, React Router, Bootstrap, and Google Maps. The backend uses .NET 8, ASP.NET Core Web API, EF Core, SQL Server, Hangfire, JWT authentication, and Azure services.
>
> My strongest personal contributions were in backend workflows around driver-load attachments and document-expiry notifications. I also worked with frontend and mobile teams on API contracts and integration issues. That required understanding how a React action creates a request, how JWT and request data reach the API, how service and transaction logic update SQL and blob storage, and how the UI responds to success or failure.

## Mnemonic: **S-L-D-A-T**

- **S - Shipment:** primary operational record.
- **L - Load board:** dispatch visibility and actions.
- **D - Drivers:** assignment, status, mobile workflow.
- **A - Attachments:** upload, preview, metadata, blob.
- **T - Tenant:** isolated data, settings, permissions.

## Architecture

```text
dm-web
├── pages: shipment, load board, driver, reports, settings
├── reusable components: forms, maps, uploads, modals
├── Redux reducers and RTK Query APIs
└── JWT-protected routing
          ↓ REST/JSON
dm-api
├── controllers
├── services and helpers
├── repositories / EF Core
├── Hangfire / notifications / blob storage
└── SQL Server
```

## Hero flow: driver-load attachment

```text
User selects document
  → frontend validates type/size
  → upload state/loading shown
  → authenticated multipart/API request
  → DriverLoad endpoint
  → attachment service uploads blob
  → metadata/status saved in SQL
  → API returns attachment model/access information
  → UI updates list or invalidates cache
  → success/error feedback
```

### Interview answer

> An attachment feature crosses both sides of the application. The React UI collects the file, validates it, shows progress or loading, and sends an authenticated request. The backend validates the driver-load and permission, uploads to blob storage, saves attachment metadata, and updates operational status. SQL changes can use a transaction, but blob storage is external, so a reliable design needs compensation or Pending/Completed state. The response updates the UI attachment list, while structured logs help correlate failures.

### Cross-questions

**Why not put a file in Redux?**

> Large binary values are not ideal serializable global state. Keep temporary file selection near the component or upload abstraction, and store only necessary metadata/status globally.

**What if the request is clicked twice?**

> Disable submission while pending, use a stable operation/attachment identifier, and enforce server-side idempotency or uniqueness. UI prevention alone is not sufficient.

**What if blob upload succeeds and SQL fails?**

> SQL rollback cannot remove the blob. Attempt compensating deletion and log cleanup, or use Pending/Completed records plus a reconciliation job.

## Hero flow: document-expiry reminder

> The backend scheduled job finds eligible expiring driver documents, applies tenant and date rules, formats a notification, and sends it through the notification service. The frontend can display document status or notification-related information from the APIs. Important concerns are duplicate prevention, timezone boundaries, retry classification, and structured logs.

## API contract collaboration

> Frontend and backend agree on route, verb, authentication, request DTO, response DTO, error shape, nullability, pagination, and status codes. TypeScript catches many client-side mismatches, but runtime validation and server-side validation remain necessary.

## Full-stack debugging flow: **B-N-A-S-D**

- **B - Browser:** UI state, console, network tab.
- **N - Network:** URL, method, token, payload, status, response.
- **A - API:** controller binding, authorization, validation.
- **S - Service:** business path, exception, external calls.
- **D - Database:** generated SQL, state, transaction, tenant.

> I debug from the visible symptom toward the data source. If the network response is correct, the issue is likely client state/rendering. If it is wrong, I trace the API and database. This avoids guessing.

## Strong challenge answer

> The most interesting full-stack challenge is partial failure. The browser, API, SQL Server, blob storage, jobs, and mobile clients cannot share one simple transaction. Reliability comes from clear system-of-record decisions, idempotency, short database transactions, compensation, observable states, and safe retries.

