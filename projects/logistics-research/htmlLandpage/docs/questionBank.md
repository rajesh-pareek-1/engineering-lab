# System Architecture — Clarification Question Bank

**Project:** SC R&DT · POD Tracker — Logistics Shipment Tracking System
**Mode:** Senior Solution Architect
**Status:** Awaiting decisions before diagram generation

---

## System Context (Current Understanding)

- Role-based logistics system
- Roles: Transporter, Trucker, Driver, Broker (public/external)
- Shipment lifecycle: `Created → Assigned → POD Uploaded → Shared`
- POD stored as image
- Public share link with expiry
- Future: WhatsApp integration, AI-assisted shipment parsing
- Mobile-first app
- Single backend API

---

## Decision Table (Fill Before Proceeding)

| #   | Topic                                | Decision                                                                                                                                                                                                                                                                                                                                                        |
| --- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Q1  | Trucker / Driver reassignment policy | c                                                                                                                                                                                                                                                                                                                                                               |
| Q2  | Shipment lock at `Shared`          | c                                                                                                                                                                                                                                                                                                                                                               |
| Q3  | Single vs. multiple PODs             | b                                                                                                                                                                                                                                                                                                                                                               |
| Q4  | Broker document scope                | b                                                                                                                                                                                                                                                                                                                                                               |
| Q5  | External document attachments        | Yes, transporter can attach docs, only when there's no other actor in right side side trucker or driver missing. if driver is missing then only trucker can attch document, if trucker and driver both are missing then only transporter can attach document, we keep functionality that transported can native share docs from whatsapp to directly in our app |
| Q6  | Trucker shipment visibility          | c                                                                                                                                                                                                                                                                                                                                                               |
| Q7  | Shipment number format               | c                                                                                                                                                                                                                                                                                                                                                               |
| Q8  | User vs. Organisation model          | b                                                                                                                                                                                                                                                                                                                                                               |
| Q9  | Broker account model                 | a                                                                                                                                                                                                                                                                                                                                                               |
| Q10 | Share link storage strategy          | b, later will see for caching                                                                                                                                                                                                                                                                                                                                   |
| Q11 | Audit log requirement                | b                                                                                                                                                                                                                                                                                                                                                               |
| Q12 | POD storage backend                  | b, but keep it flexible to switch to option 'a' in future                                                                                                                                                                                                                                                                                                       |
| Q13 | Image compression strategy           | b, mobile sdie, we have limit will fail api call if size is too big                                                                                                                                                                                                                                                                                             |
| Q14 | Multi-document schema readiness      | Future-ready schema now                                                                                                                                                                                                                                                                                                                                         |
| Q15 | Authentication strategy              | c                                                                                                                                                                                                                                                                                                                                                               |
| Q16 | Share token entropy                  | b                                                                                                                                                                                                                                                                                                                                                               |
| Q17 | RBAC enforcement layer               | c                                                                                                                                                                                                                                                                                                                                                               |
| Q18 | Expected shipment volume             | mvp, later let's see if it grows will do horizontal scaling and sharding                                                                                                                                                                                                                                                                                        |
| Q19 | Multi-tenancy model                  | c                                                                                                                                                                                                                                                                                                                                                               |
| Q20 | Expected concurrent drivers          | 100–1,000 concurrent                                                                                                                                                                                                                                                                                                                                           |
| Q21 | WhatsApp integration depth           | keep it only share link, app can give option to share link deeplinking to whatsapp, no integration of whats app is needed                                                                                                                                                                                                                                       |
| Q22 | AI parsing service placement         | will choose in future                                                                                                                                                                                                                                                                                                                                           |
| Q23 | Event-driven vs. direct calls        | Direct function calls                                                                                                                                                                                                                                                                                                                                           |

---

## PHASE 1 — Business Logic Clarity

### Q1 — Trucker & Driver Reassignment

Can a transporter reassign a trucker after one has already been assigned?
Can a trucker reassign a driver mid-shipment?

> This affects whether we allow `UPDATE` on assignment fields or require a new assignment record.

| Option                              | Description                                                    | Trade-off                                  |
| ----------------------------------- | -------------------------------------------------------------- | ------------------------------------------ |
| **A — Free edit**            | Allow direct field updates.                                    | Simple, no history.                        |
| **B — Versioned assignment** | Each assignment creates a new record; old one is soft-deleted. | Full audit trail but more complex queries. |
| **C — Event log**            | Assignments are immutable; changes are appended as events.     | Best for compliance, highest complexity.   |

**Your Decision:**

---

### Q2 — Shipment Lock Policy

Should a shipment become read-only (locked) once it reaches `Shared` status?
Or should the transporter still be able to edit or add documents?

> Directly impacts state machine design and API authorization logic.

| Option                                 | Description                                                                       | Trade-off                                                |
| -------------------------------------- | --------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **A — Hard lock at `Shared`** | No edits allowed once shared.                                                     | Simple and tamper-evident — good for legal/compliance.  |
| **B — Soft lock**               | Display is locked but admin/transporter can override with an audit note.          | Flexible but weakens immutability guarantees.            |
| **C — Field-level locking**     | Core fields lock at `Shared`; metadata (broker contact, notes) remain editable. | Best UX balance; requires per-field authorization logic. |

**Your Decision:**

---

### Q3 — Multiple PODs per Shipment

Can a driver upload more than one POD image for a single shipment?
(e.g., delivery receipt + weighbridge slip)

| Option                                             | Description                                                                                   | Trade-off                                              |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **A — Single POD only**                     | One image per shipment.                                                                       | Simple, but limits real-world use cases.               |
| **B — Multiple documents with types**       | A `documents` table with `doc_type` enum (`POD`, `weighbridge`, `invoice`).         | Flexible and production-ready; more schema complexity. |
| **C — Single POD now, future-ready schema** | Keep single for now; design schema with a foreign key supporting a `documents` table later. | Low-risk migration path — recommended for MVP.        |

**Your Decision:**

---

### Q4 — Broker Document Access Scope

Should the broker's share link expose only the POD, or also other attached documents?

| Option                                            | Description                                                               | Trade-off                                                  |
| ------------------------------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **A — POD only**                           | Share link is tightly scoped to POD.                                      | Simplest and most secure.                                  |
| **B — Configurable per link**              | Transporter selects which documents are visible when generating the link. | Maximum control; more UI complexity.                       |
| **C — All documents at `Shared` status** | Everything uploaded is visible via the link.                              | Easy to implement; potentially over-exposes internal docs. |

**Your Decision:**

---

### Q5 — External Document Attachments

Should the transporter be able to attach non-POD documents to a shipment?
(e.g., e-way bill, invoice PDF, customs clearance)

> Determines whether the `documents` table needs `doc_type` and `uploader_role` columns from day one.

**Your Decision (Yes / No / Later):**

---

### Q6 — Trucker Shipment Visibility

Can a trucker see all shipments assigned to their organisation, or only shipments explicitly assigned to them individually?

| Option                                          | Description                                                  | Trade-off                                                     |
| ----------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------- |
| **A — Individual assignment only**       | Trucker sees only their own shipments.                       | Clean separation; simplest query.                             |
| **B — Org-level visibility**             | All truckers in an org see all org shipments.                | Enables team collaboration; risk of data exposure within org. |
| **C — Role-based with manager override** | Regular truckers see own; a "trucker manager" role sees all. | Most granular; requires an extra sub-role.                    |

**Your Decision:**

---

### Q7 — Shipment Number Format

Is `SHP-2025-00142` a user-defined free-text field or a system-generated value?

| Option                                           | Description                                                                        | Trade-off                                           |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- | --------------------------------------------------- |
| **A — User-defined**                      | Transporters enter their own reference numbers.                                    | Flexible; risk of duplicates across orgs.           |
| **B — System-generated**                  | Auto-increment or UUID-based.                                                      | Consistent; loses user's existing reference number. |
| **C — User-defined with system fallback** | User can enter a ref; system auto-generates if blank. Uniqueness enforced per org. | Best of both; requires validation layer.            |

**Your Decision:**

---

## PHASE 2 — Data Model

### Q8 — User vs. Organisation Model

Is a "Transporter" a single individual user or an organisation with multiple users?
(e.g., a logistics company with 10 staff members)

> Most critical architectural decision — determines if multi-tenancy is needed from day one.

| Option                            | Description                                                            | Trade-off                                                                                           |
| --------------------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **A — User = Transporter** | Each account is an individual.                                         | Simple now; painful to migrate to org model later.                                                  |
| **B — Org + Users**        | An `organisations` table; all users belong to an org via `org_id`. | Industry standard for B2B SaaS. Enables team accounts, billing per org, and multi-tenant isolation. |
| **C — Org optional**       | Users can operate solo or join/create an org.                          | Flexible; adds conditional logic everywhere.                                                        |

**Your Decision:**

---

### Q9 — Broker — System User or External Entity?

Is the broker a registered user in your system, or purely an anonymous external recipient of a share link?

| Option                                         | Description                                                                                                                    | Trade-off                                                                       |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| **A — Anonymous external**              | Broker receives a URL; no account needed.                                                                                      | Zero friction; no identity, no broker-side audit.                               |
| **B — Registered broker user**          | Broker has a login.                                                                                                            | Enables history, notifications, and dispute handling; more onboarding friction. |
| **C — Hybrid — optional registration** | Link works anonymously; broker can optionally register to get a persistent dashboard of all links shared to their phone/email. | Best UX; moderate complexity.                                                   |

**Your Decision:**

---

### Q10 — Share Link Storage Strategy

How should share tokens be stored and resolved?

| Option                                             | Description                                                                                                   | Trade-off                                                                                          |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **A — Token column on `shipments` table** | `share_token` + `share_expires_at` columns on `shipments`.                                              | Simple; one JOIN. Works if one active link per shipment.                                           |
| **B — Separate `share_links` table**      | Each generated link is a row with `token`, `shipment_id`, `created_by`, `expires_at`, `is_revoked`. | Supports multiple links per shipment, revocation, full audit.**Recommended for production.** |
| **C — Redis / cache layer**                 | Token stored in Redis with TTL auto-expiry.                                                                   | Near-instant lookups; no persistent audit; harder to revoke cleanly.                               |

**Your Decision:**

---

### Q11 — Audit Log Requirements

Do you need a full audit trail?
(e.g., "Who changed the trucker assignment at 14:32 on 21 Feb?")

| Option                                  | Description                                                                                                 | Trade-off                                                    |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| **A — No audit log**             | Simpler schema.                                                                                             | Fine for MVP; no history if disputes arise.                  |
| **B — Append-only event log**    | A `shipment_events` table with `event_type`, `actor_id`, `old_value`, `new_value`, `timestamp`. | Ideal for compliance and disputes; moderate schema addition. |
| **C — DB-level change tracking** | Postgres triggers or a CDC tool (Debezium).                                                                 | Zero application code overhead; adds infra complexity.       |

**Your Decision:**

---

## PHASE 3 — Storage Strategy

### Q12 — POD Image Storage Backend

Where should POD images be stored?

| Option                                                      | Description                                                                       | Trade-off                                                                                 |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **A — Object storage (S3 / R2 / GCS) + Signed URLs** | Upload to bucket; store only object key in DB. Signed URLs expire and are scoped. | Industry standard. Scales to millions of files; cheap; CDN-ready.**Recommended.**   |
| **B — Local disk / VPS blob storage**                | Files stored on your server's filesystem.                                         | Simple to start; breaks under scale; no redundancy.                                       |
| **C — Database BLOB**                                | Binary stored directly in Postgres/MySQL.                                         | Kills DB performance at volume; bloats backups; no CDN possible.**Avoid entirely.** |

**Your Decision:**

---

### Q13 — Image Compression & Format Strategy

Should POD images be compressed or converted server-side before storage?
(e.g., JPEG → WebP, thumbnail generation)

| Option                                               | Description                                                                        | Trade-off                                                                       |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **A — Store raw**                             | No processing.                                                                     | Simplest; 4–8 MB images possible; high storage cost at scale.                  |
| **B — Client-side compression before upload** | Mobile app compresses before sending.                                              | Reduces bandwidth; slightly lower quality control.                              |
| **C — Server-side processing pipeline**       | Upload triggers a Lambda/worker that compresses, generates thumbnail, stores both. | Best quality control; future-ready for AI image parsing; adds async complexity. |

**Your Decision:**

---

### Q14 — Multi-Document Schema Readiness

Even if starting with a single POD, should the schema support multiple documents from day one?

> **Recommendation:** Design a `shipment_documents` table now with `doc_type`, `storage_key`, `uploaded_by`, `uploaded_at`. The application layer restricts to one POD for MVP; the schema supports expansion with zero migration cost later.

**Your Decision (Future-ready schema now / Migrate later):**

---

## PHASE 4 — Security Model

### Q15 — Authentication Strategy

How should users authenticate?

| Option                                     | Description                                                                | Trade-off                                                                                         |
| ------------------------------------------ | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **A — JWT (stateless)**             | Access token + refresh token pattern. No server-side session store needed. | Standard for mobile APIs; works with horizontal scaling.                                          |
| **B — Session-based**               | Session stored in DB or Redis.                                             | Easier to revoke; requires sticky sessions or a shared session store.                             |
| **C — OTP + JWT (recommended fit)** | Login via phone + OTP, issue a JWT on success.                             | Combines mobile-native UX with stateless token auth. Best fit given the existing mock login flow. |

**Your Decision:**

---

### Q16 — Share Link Token Entropy

How should public share tokens be generated?

| Option                                                 | Description                                                                                          | Trade-off                                                                 |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **A — UUID v4**                                 | 122 bits of randomness.                                                                              | Collision-proof; slightly long URLs (`/s/3f2504e0-4f89...`).            |
| **B — Short random slug (8–12 chars, base62)** | e.g.,`xK9bP2m4`. Human-friendly; easy to share via WhatsApp.                                       | Requires collision check on insert.**Recommended for share links.** |
| **C — HMAC-signed token**                       | Encodes shipment ID + expiry, signed with a secret key. Stateless validation — no DB lookup needed. | Useful at massive scale; no native revocation without a denylist.         |

**Your Decision:**

---

### Q17 — Access Control Enforcement Layer

Where should role-based access control (RBAC) live in the codebase?

| Option                                               | Description                                                                                           | Trade-off                                                                    |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **A — Controller / handler layer**            | Each endpoint manually checks `user.role`.                                                          | Simple but easy to miss a check; becomes a security liability at scale.      |
| **B — Middleware + policy layer**             | A dedicated `authorize(role, resource, action)` middleware runs before every handler.               | Centralised, auditable, testable.**Recommended.**                      |
| **C — Attribute-based access control (ABAC)** | Rules defined as policies (e.g.,`user.org_id === shipment.org_id AND user.role === 'transporter'`). | More granular than RBAC; industry standard for complex multi-tenant systems. |

**Your Decision:**

---

## PHASE 5 — Scalability

### Q18 — Expected Shipment Volume

What is the expected shipment volume at each stage?

| Scale                 | Description                 | Infra Implication                                     |
| --------------------- | --------------------------- | ----------------------------------------------------- |
| **MVP / pilot** | Hundreds of shipments/month | Single DB instance, no queue needed                   |
| **Growth**      | Tens of thousands/month     | Connection pooling (PgBouncer), consider read replica |
| **Enterprise**  | Hundreds of thousands/month | Queue, horizontal scaling, caching layer (Redis)      |

**Your Answer (rough estimate):**

---

### Q19 — Multi-Tenancy Model

Should transporter organisations be fully isolated from each other at the data layer?

| Option                                                         | Description                                                    | Trade-off                                                                                                        |
| -------------------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **A — Shared DB, shared schema with `org_id` filter** | All orgs in one DB; every query includes `WHERE org_id = ?`. | Simplest; lowest cost. A missed `org_id` filter leaks data — mitigate with Postgres Row Level Security (RLS). |
| **B — Shared DB, schema-per-tenant**                    | Each org gets its own Postgres schema (`org_123.shipments`). | Strong isolation; complex migrations.                                                                            |
| **C — DB-per-tenant**                                   | Each org gets a dedicated database.                            | Maximum isolation; highest infra cost. Justified only for enterprise contracts with data residency requirements. |

**Your Decision:**

---

### Q20 — Expected Concurrent Drivers

How many drivers might be uploading PODs simultaneously at peak?

| Scale                 | Recommended Upload Approach                                                                                                                                     |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Under 100 concurrent  | Single API server + S3 direct upload                                                                                                                            |
| 100–1,000 concurrent | Presigned S3 URLs — app uploads directly to S3, bypassing your API server entirely.**Recommended regardless of scale — offloads all upload bandwidth.** |
| 1,000+ concurrent     | CDN + multi-region upload endpoints                                                                                                                             |

**Your Answer (rough estimate):**

---

## PHASE 6 — Future Integrations

### Q21 — WhatsApp Integration Depth

How deeply integrated should WhatsApp be at launch vs. in the future?

| Option                            | Description                                                                                                        | Trade-off                                                                   |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| **A — Notification only**  | Send a WhatsApp message (via Twilio / WABA) when a share link is generated. One webhook, no conversation handling. | Fast to build; low complexity.                                              |
| **B — Conversational bot** | Driver can reply "UPLOADED" via WhatsApp to trigger a status change in the system.                                 | Requires webhook handler + conversation state machine.                      |
| **C — Full bot with AI**   | Driver describes delivery via WhatsApp text; AI parses it and creates/updates the shipment automatically.          | Most powerful; requires NLP integration (Dialogflow, GPT function calling). |

**Your Decision (MVP target / Future target):**

---

### Q22 — AI Parsing Service Placement

Where does AI-assisted shipment parsing sit in the architecture?

| Option                                        | Description                                                                                                          | Trade-off                                                   |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| **A — Inline synchronous**             | API calls AI model during the upload request.                                                                        | Simple; adds noticeable latency to every upload.            |
| **B — Async worker / queue**           | POD upload triggers a job queue (BullMQ / SQS). Worker calls AI in background, updates shipment with extracted data. | Non-blocking, retriable, observable.**Recommended.**  |
| **C — Third-party managed extraction** | Route through AWS Textract, Google Document AI, or Azure Form Recognizer.                                            | Managed infra; strong OCR accuracy; per-page pricing model. |

**Your Decision:**

---

### Q23 — Event-Driven Architecture

Does the system need an event bus where one action triggers multiple downstream effects simultaneously?
(e.g., "POD uploaded" → notification + AI parsing + audit log, all in parallel)

| Option                                                 | Description                                                                                            | Trade-off                                                                |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| **A — Direct function calls**                   | No event bus. Synchronous, co-located logic.                                                           | Simple; easy to debug; fine for MVP.                                     |
| **B — Internal event emitter**                  | Node.js `EventEmitter` or equivalent. Decouples side effects from core logic without external infra. | Lightweight decoupling; no retry/replay guarantees.                      |
| **C — Message broker (Kafka / RabbitMQ / SQS)** | Full event-driven system. Enables microservices, retries, event replay.                                | Correct long-term architecture for multiple consumers; overkill for MVP. |

**Your Decision (MVP target / Future target):**

---

## Next Steps (After Decisions Are Made)

Once all questions above are answered, the following artifacts will be generated in order:

1. **High-Level Architecture Diagram** — system overview, actors, external services, data flow
2. **Component Diagram** — internal service breakdown (API, workers, storage, auth, queues)
3. **Database ER Diagram** — all tables, relationships, indexes, constraints, enums
4. **API Structure** — full endpoint list, request/response shapes, auth requirements per route

---

*Prepared by: Oz — Senior Solution Architect Mode*
*Project: SC R&DT · POD Tracker*
*Date: Feb 2026*
