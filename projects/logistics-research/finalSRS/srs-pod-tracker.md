# Software Requirements Specification
## POD Tracker — Proof of Delivery Management System
**Project:** SC R&DT · Supply Chain Research & Design Thinking
**Version:** 1.0
**Date:** March 2026
**Status:** Final — MVP

---

## Table of Contents
1. [Introduction](#1-introduction)
2. [Product Scope](#2-product-scope)
3. [Stakeholders & User Roles](#3-stakeholders--user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Shipment Status Lifecycle](#5-shipment-status-lifecycle)
6. [Permission Matrix](#6-permission-matrix)
7. [Document Upload Rules (ABAC)](#7-document-upload-rules-abac)
8. [Share Link Behaviour](#8-share-link-behaviour)
9. [Non-Functional Requirements](#9-non-functional-requirements)
10. [System Architecture](#10-system-architecture)
11. [Technology Stack](#11-technology-stack)
12. [Data Model Summary](#12-data-model-summary)
13. [API Summary](#13-api-summary)
14. [Security Requirements](#14-security-requirements)
15. [Edge Cases & Constraints](#15-edge-cases--constraints)
16. [Out of Scope (MVP)](#16-out-of-scope-mvp)
17. [Assumptions](#17-assumptions)
18. [Glossary](#18-glossary)

---

## 1. Introduction
### 1.1 Purpose
This document defines the complete software requirements for the POD Tracker system — a mobile-first platform that digitises the Proof of Delivery (POD) workflow in the road freight logistics industry. It serves as the single source of truth for engineering, design, and stakeholder review.

### 1.2 Background
Field research conducted with **Anil Pareek, Co-Founder, Bharat Logistics** revealed that the current POD workflow is entirely paper-based. Physical delivery receipts are collected by truck drivers, handed back to trucking companies, and manually shared with transporters and brokers — causing delays, disputes, and lost documents. This system eliminates that friction.

### 1.3 Intended Audience
- Engineering team (Rajesh, Shivesh, Aditya)
- Product and design stakeholders
- QA and testing teams
- Future maintainers and onboarding engineers

### 1.4 Definitions
See [Section 18 — Glossary](#18-glossary).

---

## 2. Product Scope
### 2.1 What the System Does
The POD Tracker enables the complete digital lifecycle of a freight shipment's proof of delivery:
- A **Transporter** creates a shipment and assigns a **Trucker**
- The **Trucker** assigns a **Driver** and vehicle to the shipment
- The **Driver** photographs and uploads the POD at delivery
- The **Transporter** generates a time-limited share link and sends it to the **Broker**
- The **Broker** views and downloads the POD via the public share link — no login required

### 2.2 What the System Does Not Do
- GPS or real-time shipment tracking
- Freight invoicing or billing
- WhatsApp Business API integration (deeplink only in MVP)
- AI-powered document verification (hook left in codebase, deferred)
- Push notifications

### 2.3 Target Platform
- **Mobile App:** React Native (iOS + Android)
- **Public Broker View:** Mobile-optimised web page (served by .NET backend)

---

## 3. Stakeholders & User Roles

### 3.1 Role Overview

| Role | Description | Auth Required | App Access |
|---|---|---|---|
| Transporter | Freight company that owns the shipment | Yes | Mobile app |
| Trucker | Sub-contracted truck operator | Yes | Mobile app |
| Trucker Manager | Senior trucker with org-wide view | Yes | Mobile app |
| Driver | Individual driver operating the vehicle | Yes | Mobile app |
| Broker | Buyer/consignee receiving the POD | No | Public web link |

### 3.2 Transporter
- Represents the organisation that creates and manages shipments
- Can assign one Trucker per shipment
- Has full visibility of all shipments in their organisation
- Is the only role that can generate share links and manage broker contacts
- `sub_role` is always `member` (no sub-roles for transporter in MVP)

### 3.3 Trucker
- A truck operator assigned to a specific shipment by a Transporter
- Assigns the Driver and vehicle number to a shipment
- Cannot create shipments or generate share links
- Has two sub-roles:
  - `member` — sees only shipments assigned to them
  - `manager` — sees all shipments in their organisation

### 3.4 Driver
- The individual physically delivering the consignment
- Assigned to a shipment by the Trucker
- Can only upload POD documents; cannot create, assign, or share
- Sees only their own assigned shipments

### 3.5 Broker (Public / Anonymous)
- External party (buyer, consignee, finance team)
- No login or account required
- Accesses shipment data exclusively via a time-limited share link
- Can only view and download documents the Transporter has made visible

---

## 4. Functional Requirements

### 4.1 Authentication (All Roles)

**FR-AUTH-01** — The system shall authenticate users via Phone OTP.
- User submits phone number + org slug
- Backend sends a 6-digit OTP via SMS (MSG91 / Twilio)
- OTP is valid for 10 minutes
- OTP is single-use and bcrypt-hashed in storage

**FR-AUTH-02** — On successful OTP verification, the system shall issue:
- JWT access token — valid for **15 minutes**
- Refresh token — valid for **30 days**, stored as a hashed value in the tenant DB

**FR-AUTH-03** — The system shall support silent token refresh using the refresh token.
- On refresh, the old refresh token is revoked and a new pair is issued (token rotation)

**FR-AUTH-04** — The system shall support logout by revoking the active refresh token.

**FR-AUTH-05** — Rate limiting shall be enforced:
- Max 3 OTP send requests per phone number per 60 seconds
- Max 5 verification attempts per OTP before lockout

---

### 4.2 Transporter Flows

**FR-T-01 — Create Shipment**
- Transporter can create a new shipment by providing:
  - Shipment Reference Number (optional — system generates if omitted, unique per org)
  - Shipper Name (optional)
- System sets initial status to `Created`

**FR-T-02 — View Shipment List**
- Transporter sees all shipments belonging to their organisation
- List is filterable by status
- Each card shows: reference number, status badge, trucker, driver, last updated

**FR-T-03 — View Shipment Detail**
- Full shipment detail including: all assigned parties, vehicle number, uploaded documents, broker contact (private), share link status

**FR-T-04 — Assign Trucker**
- Transporter selects a Trucker from a list of org members with role `trucker`
- Assignment is logged as an event in `shipment_events`
- Core fields lock once status reaches `Shared` — reassignment is blocked after that
- Reason for reassignment can optionally be recorded

**FR-T-05 — Add / Edit Broker Contact**
- Transporter can add or edit a broker's name and phone number on the shipment
- This is private data — not exposed in the public share link
- Can be edited at any status

**FR-T-06 — Generate Share Link**
- Available only when status = `POD Uploaded` or `Shared`
- Transporter selects which `doc_type`s to expose to the broker
- System generates a Base62 short slug (10 characters)
- Link format: `https://pod.podtracker.in/s/{token}`
- WhatsApp deeplink is also returned: `whatsapp://send?text={url}`
- Default expiry: 30 days (configurable)
- Generating a new link does NOT invalidate the previous one (multiple active links supported)

**FR-T-07 — Revoke Share Link**
- Transporter can revoke any previously generated share link
- Revoked links immediately return 410 Gone to anyone accessing them

**FR-T-08 — Edit Core Fields**
- Transporter can edit core shipment fields (reference number, shipper name) only while `core_fields_locked = false`
- Fields lock permanently once status reaches `Shared`

**FR-T-09 — Edit Metadata**
- Broker contact and shipment notes can be edited at any time, regardless of lock status

---

### 4.3 Trucker Flows

**FR-TK-01 — View Assigned Shipments**
- Trucker (`member`) sees only shipments where `trucker_id = user.id`
- Trucker (`manager`) sees all shipments in the organisation

**FR-TK-02 — Assign Driver + Vehicle**
- Trucker selects a Driver from org members with role `driver`
- Trucker enters the vehicle registration number
- Assignment is blocked if status has reached `POD Uploaded` (core fields locked)
- Assignment is logged as an event

**FR-TK-03 — View Shipment Detail**
- Trucker can view all shipment details for their assigned shipments
- Can see uploaded documents if any

---

### 4.4 Driver Flows

**FR-D-01 — View Assigned Shipments**
- Driver sees only shipments where `driver_id = user.id`
- Shows pending (no POD yet) and completed (POD uploaded) shipments

**FR-D-02 — Upload POD Document**
- Driver can upload a document only if `driver_id = user.id` on the shipment
- Supported upload types: camera capture, file picker
- Supported file formats: JPEG, PNG, WEBP, PDF
- Max file size enforced server-side (5 MB); client-side compression applied before upload
- On successful upload, shipment status transitions to `POD Uploaded`

**FR-D-03 — Upload Success Confirmation**
- After successful upload, Driver sees a confirmation screen with the shipment reference
- Status badge updates to `POD Uploaded`

---

### 4.5 Broker (Public) Flows

**FR-B-01 — View Shipment via Share Link**
- Broker opens `https://pod.podtracker.in/s/{token}` — no login required
- System resolves the token and returns:
  - Shipment reference number
  - Shipper name
  - Driver name and vehicle number
  - Shipment status
  - Documents matching `visible_doc_types` selected by the Transporter

**FR-B-02 — Download Document**
- Each document is accessible via a time-limited signed URL (30-minute expiry)
- Broker can download any document visible in the share link

**FR-B-03 — Expired / Revoked Link Handling**
- If link is expired: show "Link Expired" screen with no document data
- If link is revoked: show "Link No Longer Available" screen
- If token does not exist: show 404 screen

---

### 4.6 Document Management

**FR-DOC-01 — Document Types**
Supported `doc_type` values:
- `pod` — Proof of Delivery (primary)
- `weighbridge` — Weighbridge slip
- `invoice` — Commercial invoice
- `eway_bill` — E-Way Bill (GST)
- `custom` — User-defined label

**FR-DOC-02 — Multiple Documents Per Shipment**
- A shipment can have multiple documents of different types
- Each document is independently associated with a `doc_type`

**FR-DOC-03 — Document Visibility Control**
- When generating a share link, the Transporter selects which `doc_type`s are visible
- Visibility is stored per share link, not per document

**FR-DOC-04 — Soft Delete**
- Transporter can soft-delete a document (`is_deleted = true`)
- Only allowed while `core_fields_locked = false`
- Deleted documents are excluded from all API responses and share link views

**FR-DOC-05 — Signed URL File Serving**
- Documents are never served at a permanent public URL
- All document URLs are HMAC-SHA256 signed with a server secret and time-limited expiry
- Future S3 migration: signed URLs replaced with native presigned URLs — no API contract change

---

### 4.7 Native Share / OS Share Sheet

**FR-NS-01 — Receive Shared Document**
- When a user shares a file to the app via the OS share sheet (e.g. from WhatsApp), the app presents an "Attach to Shipment" screen
- User selects a shipment from a list and confirms
- The document is attached to the selected shipment

**FR-NS-02 — Attach Success**
- Confirmation screen shown after successful attachment
- Shipment reference number is displayed

---

### 4.8 User & Organisation Management

**FR-ORG-01 — Invite Members**
- Transporter can invite new users (Trucker or Driver) by phone number
- Invited user receives an OTP on first login

**FR-ORG-02 — Deactivate Members**
- Transporter can deactivate org members
- Deactivated users cannot log in

**FR-ORG-03 — Reference Number Format**
- Org-wide reference number format is user-defined with a system-generated fallback
- Reference numbers must be unique per organisation

---

## 5. Shipment Status Lifecycle

```
┌─────────┐     Transporter assigns Trucker      ┌──────────┐
│ Created │  ──────────────────────────────────►  │ Assigned │
└─────────┘   + Trucker assigns Driver+Vehicle    └──────────┘
                                                        │
                                              Driver uploads POD
                                                        │
                                                        ▼
┌────────┐     Transporter generates share link  ┌─────────────┐
│ Shared │  ◄─────────────────────────────────── │ POD Uploaded│
└────────┘                                        └─────────────┘
```

| Status | Triggered By | Core Fields Locked |
|---|---|---|
| `Created` | Transporter creates shipment | No |
| `Assigned` | Transporter assigns Trucker | No |
| `POD Uploaded` | Driver uploads document | No |
| `Shared` | Transporter generates share link | **Yes** |

> Once a shipment reaches `Shared`, core fields (reference number, shipper name, trucker, driver, vehicle) are permanently locked. Metadata (broker contact, notes) remain editable at all times.

---

## 6. Permission Matrix

| Action | Transporter | Trucker (Member) | Trucker (Manager) | Driver | Broker |
|---|---|---|---|---|---|
| Create Shipment | ✓ | ✗ | ✗ | ✗ | ✗ |
| View All Org Shipments | ✓ | ✗ | ✓ | ✗ | ✗ |
| View Assigned Shipments | ✓ | ✓ | ✓ | ✓ | ✗ |
| Assign Trucker | ✓ | ✗ | ✗ | ✗ | ✗ |
| Assign Driver + Vehicle | ✗ | ✓ | ✓ | ✗ | ✗ |
| Upload Document | ✓* | ✓* | ✓* | ✓ | ✗ |
| Delete Document | ✓ | ✗ | ✗ | ✗ | ✗ |
| Generate Share Link | ✓ | ✗ | ✗ | ✗ | ✗ |
| Revoke Share Link | ✓ | ✗ | ✗ | ✗ | ✗ |
| Edit Core Fields | ✓ | ✗ | ✗ | ✗ | ✗ |
| Edit Metadata | ✓ | ✗ | ✗ | ✗ | ✗ |
| View Public Share Link | ✗ | ✗ | ✗ | ✗ | ✓ |
| Download Document (via link) | ✗ | ✗ | ✗ | ✗ | ✓ |
| Invite / Deactivate Members | ✓ | ✗ | ✗ | ✗ | ✗ |

> \* Upload permitted only under the cascading ABAC rule — see Section 7.

---

## 7. Document Upload Rules (ABAC)

Document upload follows a **cascading assignment rule** (Decision Q5):

```
IF driver_id IS NOT NULL
  → Only the assigned Driver may upload

ELSE IF trucker_id IS NOT NULL AND driver_id IS NULL
  → Only the assigned Trucker may upload

ELSE IF trucker_id IS NULL AND driver_id IS NULL
  → The Transporter (org owner) may upload
```

**Rationale:** Upload rights cascade down the assignment chain. Whoever is "furthest down" the chain at the time of upload is the responsible party.

**Error on violation:**
```json
{
  "error": "UPLOAD_NOT_PERMITTED",
  "message": "Driver is already assigned. Only the driver may upload documents."
}
```

---

## 8. Share Link Behaviour

| Property | Value |
|---|---|
| Token format | Base62, 10 characters (e.g. `xK9bP2m4Qr`) |
| Default expiry | 30 days |
| Multiple active links | Supported |
| Revocation | Instant — returns 410 Gone |
| Doc visibility | Per-link selection of `doc_type` values |
| File URL expiry | 30 minutes (signed URL) |
| WhatsApp integration | Deeplink only — `whatsapp://send?text={url}` |
| Access tracking | `access_count` and `last_accessed_at` recorded per link |

---

## 9. Non-Functional Requirements

### 9.1 Performance
- API response time (p95): < 400ms for read operations, < 800ms for uploads
- Share link resolution: < 200ms (Redis cache target for post-MVP)
- Concurrent users (MVP target): 100–1,000

### 9.2 Availability
- Target uptime: 99.5% (MVP)
- No SLA requirement for MVP; best-effort

### 9.3 Scalability
- Architecture is designed for horizontal scale (stateless .NET API)
- DB-per-tenant pattern allows independent scaling per organisation
- `IStorageService` abstraction enables switch from local disk to S3 with zero API changes

### 9.4 Security
- All tokens (refresh, share) stored as hashed values — never plaintext
- Document URLs are HMAC-signed and time-limited
- Tenant data is fully isolated at the database level (no shared tables)
- See [Section 14](#14-security-requirements) for full security requirements

### 9.5 Usability
- Mobile app optimised for 375×812px (iPhone SE baseline)
- Offline-tolerant UI: clear loading and error states
- Driver flow is intentionally minimal — maximum 2 taps to upload POD
- All critical actions have confirmation states

### 9.6 Maintainability
- Codebase follows Clean Architecture (Controller → Service → Repository)
- ABAC policies are pure functions in isolated policy files — testable without HTTP context
- Storage abstracted behind `IStorageService` interface
- Multi-tenancy resolved via middleware — transparent to business logic

### 9.7 Internationalisation
- MVP: English only
- Architecture supports future locale additions

---

## 10. System Architecture

### 10.1 High-Level Topology

```
┌─────────────────────────────────────────────────────────┐
│  React Native Mobile App                                 │
│  (Transporter · Trucker · Driver)                        │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS + JWT
                      ▼
┌─────────────────────────────────────────────────────────┐
│  .NET ASP.NET Core API                                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Middleware: verifyJWT → resolveTenant → authorize │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌────────────┐  ┌──────────────┐  ┌───────────────┐   │
│  │  Auth      │  │  Shipment    │  │  Document     │   │
│  │  Service   │  │  Service     │  │  Service      │   │
│  └────────────┘  └──────────────┘  └───────────────┘   │
│  ┌────────────┐  ┌──────────────┐  ┌───────────────┐   │
│  │  Share     │  │  ABAC Policy │  │  IStorage     │   │
│  │  Link Svc  │  │  Engine      │  │  Service      │   │
│  └────────────┘  └──────────────┘  └───────────────┘   │
└────────────────────────┬────────────────────────────────┘
              ┌──────────┴──────────┐
              ▼                     ▼
   ┌──────────────────┐   ┌──────────────────────────┐
   │  Master Registry │   │  Tenant DBs (per org)     │
   │  PostgreSQL       │   │  PostgreSQL × N           │
   │  - organisations  │   │  - users, shipments       │
   │  - otp_requests   │   │  - documents, events      │
   └──────────────────┘   │  - share_links, tokens    │
                           └──────────────────────────┘
```

### 10.2 Multi-Tenancy Strategy
- **DB-per-tenant** pattern (Decision Q19)
- A **Master Registry DB** holds `organisations` (with DB connection info) and `otp_requests`
- On every authenticated request, the `resolveTenant` middleware resolves the org's DB connection from the master registry (or in-memory cache) and injects it into the request context
- All tenant data is fully isolated — no cross-tenant queries are possible

### 10.3 Request Middleware Chain
Every authenticated API request passes through three middleware layers in order:
1. **`verifyJWT`** — validates JWT signature and expiry, attaches user context
2. **`resolveTenant`** — resolves and injects the tenant DB connection
3. **`authorize(policy)`** — evaluates the ABAC policy for the requested action

Public routes (`/public/*`, `/auth/*`) bypass all three layers.

### 10.4 Event Sourcing (Audit Log)
All state-changing operations on shipments append a record to `shipment_events` (Decision Q11). Core fields are never overwritten — the event log is the source of truth for assignment history. This enables:
- Full audit trail of who did what and when
- Reassignment history (trucker/driver changes)
- Dispute resolution

---

## 11. Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| Mobile App | React Native | iOS + Android, single codebase |
| API Backend | ASP.NET Core (.NET 8+) | RESTful JSON API |
| Database | PostgreSQL | DB-per-tenant, master registry |
| Authentication | Phone OTP + JWT | Access 15m, Refresh 30d |
| File Storage (MVP) | Local disk | via `IStorageService` abstraction |
| File Storage (Future) | AWS S3 / Azure Blob | Zero API contract change |
| SMS Gateway | MSG91 / Twilio | OTP delivery |
| File Signing | HMAC-SHA256 | Time-limited document URLs |
| Caching (MVP) | In-memory | Tenant DB connection pool |
| Caching (Future) | Redis | Share link resolution, tenant routing |
| WhatsApp | Deeplink only | `whatsapp://send?text=...` |

---

## 12. Data Model Summary

### 12.1 Master Registry DB Tables

**`organisations`**
Stores each tenant org with their isolated DB connection details.
Key fields: `id`, `name`, `slug` (unique), `db_host`, `db_name`, `plan`, `is_active`

**`otp_requests`**
Stores OTP requests before the tenant is resolved (phone number is not yet associated with a specific org DB).
Key fields: `id`, `phone`, `otp_hash` (bcrypt), `expires_at`, `is_used`, `attempt_count`

### 12.2 Tenant DB Tables (per Organisation)

**`users`**
All users belonging to the org.
Key fields: `id`, `org_id`, `phone` (unique), `name`, `role` (enum), `sub_role` (enum), `is_active`

**`refresh_tokens`**
Hashed refresh tokens for JWT rotation.
Key fields: `id`, `user_id` (FK), `token_hash`, `expires_at`, `revoked_at`

**`shipments`**
Core shipment record.
Key fields: `id`, `org_id`, `reference_number`, `shipper_name`, `status` (enum), `trucker_id` (FK), `driver_id` (FK), `vehicle_number`, `broker_contact_name`, `broker_contact_phone`, `notes`, `core_fields_locked`, `created_by`

**`shipment_documents`**
Uploaded files linked to shipments.
Key fields: `id`, `shipment_id` (FK), `doc_type` (enum), `storage_key`, `original_filename`, `file_size_bytes`, `mime_type`, `uploaded_by` (FK), `uploader_role`, `is_deleted`

**`share_links`**
Generated public share links.
Key fields: `id`, `token` (Base62, unique), `shipment_id` (FK), `created_by` (FK), `expires_at`, `is_revoked`, `visible_doc_types` (jsonb), `access_count`, `last_accessed_at`

**`shipment_events`**
Immutable append-only audit log.
Key fields: `id`, `shipment_id` (FK), `event_type` (enum), `actor_id` (FK), `actor_role`, `payload` (jsonb), `created_at`

Event types: `shipment_created`, `trucker_assigned`, `trucker_reassigned`, `driver_assigned`, `driver_reassigned`, `document_uploaded`, `document_deleted`, `share_link_generated`, `share_link_revoked`, `status_changed`

---

## 13. API Summary

**Base URL:** `https://api.podtracker.in/v1`

### Authentication
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/otp/send` | None | Send OTP to phone |
| POST | `/auth/otp/verify` | None | Verify OTP, receive JWT pair |
| POST | `/auth/token/refresh` | None | Rotate token pair |
| POST | `/auth/logout` | None | Revoke refresh token |

### Shipments
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/shipments` | JWT | List shipments (role-filtered) |
| POST | `/shipments` | JWT | Create shipment |
| GET | `/shipments/:id` | JWT | Get shipment detail |
| PATCH | `/shipments/:id/core` | JWT | Edit core fields |
| PATCH | `/shipments/:id/metadata` | JWT | Edit broker contact, notes |
| POST | `/shipments/:id/assign-trucker` | JWT | Assign trucker |
| POST | `/shipments/:id/assign-driver` | JWT | Assign driver + vehicle |

### Documents
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/shipments/:id/documents` | JWT | List documents |
| POST | `/shipments/:id/documents` | JWT | Upload document (multipart) |
| DELETE | `/shipments/:id/documents/:docId` | JWT | Soft-delete document |
| POST | `/shipments/:id/documents/upload-url` | JWT | **Future:** Get S3 presigned URL |
| POST | `/shipments/:id/documents/confirm` | JWT | **Future:** Confirm S3 upload |

### Share Links
| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/shipments/:id/share-links` | JWT | Generate share link |
| GET | `/shipments/:id/share-links` | JWT | List share links |
| DELETE | `/share-links/:linkId` | JWT | Revoke share link |

### Public (Broker)
| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/public/s/:token` | None | Resolve token, return shipment + docs |

### Error Response Format
All errors follow a consistent envelope:
```json
{
  "error": "ERROR_CODE",
  "message": "Human readable description",
  "field": "optional_field_name"
}
```

### Standard HTTP Status Codes
| Code | Meaning |
|---|---|
| 200 / 201 | Success |
| 400 | Validation error |
| 401 | Invalid or expired JWT |
| 403 | ABAC policy denied |
| 404 | Resource not found |
| 409 | Conflict (duplicate ref, shipment locked) |
| 410 | Share link expired or revoked |
| 413 | File too large |
| 415 | Unsupported file type |
| 429 | Rate limited |
| 503 | Tenant DB unreachable |

---

## 14. Security Requirements

**SR-01 — OTP Security**
- OTPs are 6 digits, generated using a CSPRNG
- Stored as bcrypt hashes — never in plaintext
- 10-minute expiry, single-use
- Brute-force protection: max 5 verification attempts before OTP is invalidated

**SR-02 — JWT Security**
- Access tokens signed with RS256 or HS256 with a strong secret (min 256-bit)
- Access token TTL: 15 minutes
- Refresh tokens stored as SHA-256 hashes in the tenant DB
- Token rotation on every refresh — old token revoked immediately

**SR-03 — Tenant Isolation**
- Each organisation has a completely separate PostgreSQL database
- No cross-tenant queries are possible by design
- Tenant is resolved from the JWT `org_id` claim — not from request parameters

**SR-04 — Document URL Security**
- No document is served at a permanent URL
- All document URLs are signed: `HMAC-SHA256(path + expiry, FILE_SIGNING_SECRET)`
- Authenticated users: 1-hour signed URL
- Broker public view: 30-minute signed URL

**SR-05 — Share Link Security**
- Share link tokens are 10-character Base62 slugs (~60 bits of entropy)
- Tokens are unique at the database level (`UNIQUE` constraint)
- Revoked tokens return HTTP 410 immediately

**SR-06 — Transport Security**
- All API traffic served over HTTPS/TLS 1.2+
- HTTP redirected to HTTPS
- HSTS header enforced

**SR-07 — Input Validation**
- All incoming request bodies validated before processing
- File uploads validated for MIME type and size server-side
- Client-side compression does not bypass server-side size limits

**SR-08 — Rate Limiting**
| Endpoint | Limit | Window |
|---|---|---|
| `POST /auth/otp/send` | 3 requests | per phone per 60s |
| `POST /auth/otp/verify` | 5 attempts | per OTP |
| `POST /shipments/:id/documents` | 20 uploads | per user per minute |
| `GET /public/s/:token` | 100 requests | per IP per minute |

---

## 15. Edge Cases & Constraints

**EC-01 — Upload Before Assignment**
Driver cannot upload POD if `driver_id IS NULL` on the shipment. The Upload POD button is hidden and the endpoint returns 403 if called directly.

**EC-02 — Share Link Before POD**
The "Generate Share Link" action is disabled in the UI and blocked at API level if `shipment.status NOT IN ('pod_uploaded', 'shared')`.

**EC-03 — Reassignment After Lock**
Once status reaches `Shared`, `core_fields_locked = true`. All attempts to reassign trucker, driver, or edit core fields return:
```json
{ "error": "SHIPMENT_LOCKED", "message": "Core fields cannot be edited after Shared status." }
```

**EC-04 — Duplicate Reference Number**
Reference numbers must be unique per organisation. Duplicate submission returns HTTP 409.

**EC-05 — Expired Share Link**
Broker accesses a link after 30 days. Public page shows "Link Expired" with no document data exposed. Transporter must generate a new link.

**EC-06 — Revoked Share Link**
Returns HTTP 410 Gone immediately. No document data is exposed.

**EC-07 — Tenant DB Unreachable**
If the tenant DB is unreachable during request processing, the API returns HTTP 503 with a generic error. No partial data is returned.

**EC-08 — File Too Large**
API enforces 5 MB size limit server-side. Returns HTTP 413. Client-side compression is recommended but not relied upon for enforcement.

**EC-09 — Unsupported File Type**
Returns HTTP 415. Allowed: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`.

---

## 16. Out of Scope (MVP)

The following are explicitly deferred and **not** part of the MVP:

| Feature | Notes |
|---|---|
| Push notifications | Deferred post-MVP |
| Real-time GPS tracking | Not in scope |
| Freight invoicing / billing | Not in scope |
| WhatsApp Business API | Deeplink only in MVP |
| AI document verification | Hook left in Document Service for future |
| Redis caching | In-memory cache sufficient for MVP scale |
| S3 / cloud storage | Local disk + IStorageService abstraction ready |
| Message queue (RabbitMQ, etc.) | Direct function calls in MVP |
| Admin dashboard (web) | Mobile app only for MVP |
| Analytics / reporting | Not in scope |
| Multi-language support | English only in MVP |
| Offline mode | Not guaranteed; graceful error states shown |

---

## 17. Assumptions

**A-01** — Users have a working smartphone (iOS or Android) with internet connectivity at the time of document upload.

**A-02** — OTP delivery is handled by an external SMS gateway (MSG91 or Twilio). Delivery reliability is outside system control.

**A-03** — The Broker always accesses the share link via a mobile browser. The public view is optimised for mobile.

**A-04** — Each organisation is pre-provisioned with its own PostgreSQL database before their first user logs in. Database provisioning is an ops task, not a self-service flow in MVP.

**A-05** — File storage in MVP is local disk on the API server. Data durability (backup, RAID) is an ops responsibility.

**A-06** — Client-side image compression is applied by the React Native app before upload. The server enforces a hard 5 MB limit regardless.

**A-07** — The WhatsApp deeplink (`whatsapp://send`) works only on devices with WhatsApp installed. No fallback is required in MVP.

**A-08** — Org slugs are assigned during onboarding by the ops team. Users supply their org slug at login.

---

## 18. Glossary

| Term | Definition |
|---|---|
| POD | Proof of Delivery — a document (typically a photo of a signed receipt) confirming goods were delivered |
| Transporter | The freight company that creates and owns a shipment |
| Trucker | Sub-contracted truck operator assigned to a shipment |
| Driver | Individual operating the vehicle; responsible for uploading POD at delivery |
| Broker | External buyer or consignee who receives the POD via a share link, without logging in |
| Share Link | A time-limited, publicly accessible URL generated by the Transporter to share POD documents |
| ABAC | Attribute-Based Access Control — the policy engine used to determine what each user can do |
| JWT | JSON Web Token — used for stateless API authentication |
| OTP | One-Time Password — 6-digit code sent via SMS for login |
| Tenant | A single organisation with its own isolated database |
| DB-per-tenant | A multi-tenancy strategy where each organisation has a separate PostgreSQL database |
| Core Fields | Shipment fields that lock permanently once status reaches `Shared` (reference number, shipper name, trucker, driver, vehicle) |
| Metadata | Shipment fields that remain editable at all times (broker contact, notes) |
| Event Log | The `shipment_events` table — an immutable append-only record of all state changes |
| Base62 | Encoding using `[0-9A-Za-z]` — used for generating compact share link tokens |
| Signed URL | A document URL with an embedded HMAC signature and expiry timestamp |
| IStorageService | A .NET interface abstracting file storage — allows switching from local disk to S3 without API changes |
| `core_fields_locked` | Boolean flag on `shipments` table; set to `true` when status reaches `Shared` |

---

*Document prepared by: SC R&DT Engineering Team*
*Field research: Anil Pareek — Co-Founder, Bharat Logistics*
*Engineers: Rajesh Pareek · Shivesh · Aditya*
*Version 1.0 — March 2026*
