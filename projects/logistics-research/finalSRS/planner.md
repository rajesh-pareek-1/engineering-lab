
---

# 📘 POD Tracker — 90 Day Execution Board

**Version:** MVP Build Plan
**Duration:** 12 Weeks
**Status:** Active Development

---

# 🔄 STATUS LEGEND

Use these tags:

* ⬜ Not Started
* 🟡 In Progress
* 🔵 In Review
* 🟢 Done
* 🔴 Blocked
* 🟣 Refining (Decision Gap)
* ⚫ Refactor Needed

---

# 📎 Shared References

* SRS Link: `__________`
* API Spec: `__________`
* Figma / Wireframe: `__________`
* GitHub Repo: `__________`
* Discord Server: `__________`
* Production URL: `__________`

---

# 🧱 PHASE 0 — Foundation & Architecture Lock (Week 1–2)

---

## 0.1 Core Architectural Decisions

| Task                                           | Status | Notes | Conflicts | Decision Gap |
| ---------------------------------------------- | ------ | ----- | --------- | ------------ |
| Confirm DB-per-tenant strategy                 | ⬜     |       |           |              |
| Finalise JWT strategy (HS256 vs RS256)         | ⬜     |       |           |              |
| Finalise token expiry durations                | ⬜     |       |           |              |
| Confirm storage abstraction design             | ⬜     |       |           |              |
| Finalise status lifecycle enforcement approach | ⬜     |       |           |              |

---

## 0.2 Environment & Dev Setup

| Task                                     | Status | Notes |
| ---------------------------------------- | ------ | ----- |
| Create production repo structure         | ⬜     |       |
| Setup CI pipeline                        | ⬜     |       |
| Setup staging environment                | ⬜     |       |
| Configure environment variables strategy | ⬜     |       |
| Setup logging framework                  | ⬜     |       |

---

## 0.3 Master Registry DB

| Task                          | Status | Notes | Refactor |
| ----------------------------- | ------ | ----- | -------- |
| Create `organisations`table | ⬜     |       |          |
| Create `otp_requests`table  | ⬜     |       |          |
| OTP expiry enforcement logic  | ⬜     |       |          |
| OTP rate limiting             | ⬜     |       |          |

---

# 🔐 PHASE 1 — Authentication & Multi-Tenant Core (Week 2–3)

---

## 1.1 OTP Flow

| Task                  | Status | Notes | Edge Cases Covered |
| --------------------- | ------ | ----- | ------------------ |
| Send OTP endpoint     | ⬜     |       |                    |
| Verify OTP endpoint   | ⬜     |       |                    |
| OTP hashing logic     | ⬜     |       |                    |
| Attempt count lockout | ⬜     |       |                    |

---

## 1.2 JWT & Refresh Tokens

| Task                           | Status | Notes | Refactor |
| ------------------------------ | ------ | ----- | -------- |
| Access token generation        | ⬜     |       |          |
| Refresh token storage (hashed) | ⬜     |       |          |
| Token rotation logic           | ⬜     |       |          |
| Logout token revocation        | ⬜     |       |          |

---

## 1.3 Middleware Chain

| Task                         | Status | Notes | Conflicts |
| ---------------------------- | ------ | ----- | --------- |
| verifyJWT middleware         | ⬜     |       |           |
| resolveTenant middleware     | ⬜     |       |           |
| authorize(policy) middleware | ⬜     |       |           |
| Public route bypass logic    | ⬜     |       |           |

---

# 🚚 PHASE 2 — Shipment Core Engine (Week 3–5)

---

## 2.1 Shipment Table + Core Logic

| Task                           | Status | Notes | Refactor |
| ------------------------------ | ------ | ----- | -------- |
| Create `shipments`table      | ⬜     |       |          |
| Status enum implementation     | ⬜     |       |          |
| core_fields_locked logic       | ⬜     |       |          |
| Duplicate reference prevention | ⬜     |       |          |
| Create shipment endpoint       | ⬜     |       |          |

---

## 2.2 Shipment Events (Audit Log)

| Task                            | Status | Notes | Review |
| ------------------------------- | ------ | ----- | ------ |
| Create `shipment_events`table | ⬜     |       |        |
| Append-only logging             | ⬜     |       |        |
| Event type enum finalisation    | ⬜     |       |        |

---

## 2.3 Assignment Engine

| Task                            | Status | Notes | Decision Gap |
| ------------------------------- | ------ | ----- | ------------ |
| Assign trucker endpoint         | ⬜     |       |              |
| Assign driver endpoint          | ⬜     |       |              |
| Prevent reassignment after lock | ⬜     |       |              |
| Reassignment history logic      | ⬜     |       |              |

---

# 📄 PHASE 3 — Document Management System (Week 5–6)

---

## 3.1 Document Table

| Task                          | Status | Notes |
| ----------------------------- | ------ | ----- |
| Create `shipment_documents` | ⬜     |       |
| Doc type enum                 | ⬜     |       |
| Soft delete logic             | ⬜     |       |

---

## 3.2 Upload Logic

| Task                               | Status | Edge Cases | Refactor |
| ---------------------------------- | ------ | ---------- | -------- |
| File size validation               | ⬜     |            |          |
| MIME validation                    | ⬜     |            |          |
| Cascading ABAC rule                | ⬜     |            |          |
| Status auto-update to POD Uploaded | ⬜     |            |          |

---

## 3.3 File Signing

| Task                    | Status | Notes |
| ----------------------- | ------ | ----- |
| HMAC signing function   | ⬜     |       |
| Expiry enforcement      | ⬜     |       |
| Signed URL verification | ⬜     |       |

---

# 🔗 PHASE 4 — Share Link Engine (Week 6–7)

---

## 4.1 Share Link Table

| Task                         | Status | Notes | Review |
| ---------------------------- | ------ | ----- | ------ |
| Create `share_links`table  | ⬜     |       |        |
| Base62 token generator       | ⬜     |       |        |
| Unique constraint validation | ⬜     |       |        |

---

## 4.2 Share Link Behaviour

| Task                          | Status | Conflicts | Refactor |
| ----------------------------- | ------ | --------- | -------- |
| Generate link endpoint        | ⬜     |           |          |
| Visible doc types storage     | ⬜     |           |          |
| Multiple active links support | ⬜     |           |          |
| Revoke link endpoint          | ⬜     |           |          |
| Access tracking counters      | ⬜     |           |          |

---

## 4.3 Public Controller

| Task          | Status | Edge Cases |
| ------------- | ------ | ---------- |
| Resolve token | ⬜     |            |
| Expiry check  | ⬜     |            |
| Revoked check | ⬜     |            |
| 410 handling  | ⬜     |            |

---

# 📱 PHASE 5 — Mobile Integration (Week 7–9)

---

## 5.1 Authentication UI

| Task                    | Status | Notes |
| ----------------------- | ------ | ----- |
| Phone input screen      | ⬜     |       |
| OTP verification screen | ⬜     |       |
| Token storage logic     | ⬜     |       |

---

## 5.2 Transporter Flow

| Task                   | Status | Refactor |
| ---------------------- | ------ | -------- |
| Shipment list UI       | ⬜     |          |
| Create shipment screen | ⬜     |          |
| Shipment detail screen | ⬜     |          |
| Assign trucker UI      | ⬜     |          |

---

## 5.3 Trucker & Driver Flow

| Task                        | Status | Review |
| --------------------------- | ------ | ------ |
| Assign driver UI            | ⬜     |        |
| Driver shipment list        | ⬜     |        |
| POD upload UI               | ⬜     |        |
| Upload success confirmation | ⬜     |        |

---

## 5.4 Share Link UI

| Task                   | Status | Notes |
| ---------------------- | ------ | ----- |
| Select doc types modal | ⬜     |       |
| Generate link screen   | ⬜     |       |
| WhatsApp deeplink      | ⬜     |       |
| OS Share integration   | ⬜     |       |

---

# 🧪 PHASE 6 — Hardening & Stabilisation (Week 10–12)

---

## 6.1 Security Review

| Task                          | Status | Findings |
| ----------------------------- | ------ | -------- |
| Tenant isolation verification | ⬜     |          |
| JWT expiry enforcement        | ⬜     |          |
| ABAC bypass attempts          | ⬜     |          |
| File signing validation       | ⬜     |          |

---

## 6.2 Performance Optimisation

| Task                           | Status | Notes |
| ------------------------------ | ------ | ----- |
| Add DB indexes                 | ⬜     |       |
| Optimize shipment list query   | ⬜     |       |
| Optimize share link resolution | ⬜     |       |

---

## 6.3 Edge Case Validation (From SRS Section 15)

| Case                     | Status | Result |
| ------------------------ | ------ | ------ |
| Upload before assignment | ⬜     |        |
| Share before POD         | ⬜     |        |
| Duplicate reference      | ⬜     |        |
| Expired link             | ⬜     |        |
| Revoked link             | ⬜     |        |
| Tenant DB down           | ⬜     |        |

---

# 🧠 Ongoing Refinement Board

---

## ⚠ Active Conflicts

| Issue | Status | Decision |
| ----- | ------ | -------- |
|       | ⬜     |          |
|       | ⬜     |          |

---

## 🟣 Decision Gaps (Needs Refinement)

| Topic | Status | Notes |
| ----- | ------ | ----- |
|       | ⬜     |       |
|       | ⬜     |       |

---

## ⚫ Refactor Backlog

| Component | Reason | Status |
| --------- | ------ | ------ |
|           |        | ⬜     |
|           |        | ⬜     |

---

# 📊 Progress Overview

| Phase   | Completion |
| ------- | ---------- |
| Phase 0 | 0%         |
| Phase 1 | 0%         |
| Phase 2 | 0%         |
| Phase 3 | 0%         |
| Phase 4 | 0%         |
| Phase 5 | 0%         |
| Phase 6 | 0%         |

---

# 🏁 MVP Completion Criteria

All of the following must be true:

* 🟢 Full shipment lifecycle works
* 🟢 Role isolation enforced
* 🟢 Share link works with expiry + revoke
* 🟢 No cross-tenant access possible
* 🟢 Driver can upload successfully in real field test
* 🟢 Broker can download via mobile browser
* 🟢 All SRS edge cases validated
