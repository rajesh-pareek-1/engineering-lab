# 📄 RollOnDispatch — Arena Preparation Notes

## 👤 Introduction

Hi, I’m Rajesh.
I’m currently working as a Full Stack Developer at In Time Tec with around 2 years of experience.

My primary expertise is in:

- .NET Core (backend APIs)
- React Native (mobile development)

I have worked on production-level systems involving API design, database optimization, and real-time driver-based workflows.

I completed my Bachelor of Technology in Computer Science in 2024 from SKIT College.
I belong to Jhunjhunu district in Rajasthan.

I’m excited to be here and looking forward to discussing my experience.

---

# 🚀 Project: RollOnDispatch (Backend API)

## ⚡ 60–90 Sec Pitch

RollOnDispatch is a multi-tenant SaaS platform built for trucking companies in the livestock domain.

It manages the complete shipment lifecycle — from creating shipments, assigning drivers, tracking deliveries, to generating invoices and syncing with QuickBooks.

The system is built using a layered architecture with Controllers, Services, and Repositories on top of EF Core.

A key aspect is multi-tenancy, where each tenant has a separate database resolved dynamically using tenant context from JWT claims.

For scalability, we use Hangfire for background processing like invoice generation, and Azure Service Bus to decouple QuickBooks integration.

I worked mainly on shipment and driver load APIs, validation logic, and performance optimizations.

---

# 🏗️ Architecture (Simple Explanation)

- Controller → Handles HTTP request
- Service → Business logic + validation
- Repository → Database interaction
- EF Core → ORM for DB operations

### Why?

- Clean separation of concerns
- Reusability via generic CRUD
- Easier maintenance and scaling

---

# 🔑 Key Concepts (Interview Ready)

## 🔹 Generic CRUD (base.Add)

> We used a generic base service and repository to avoid duplicating CRUD logic across multiple entities.
> Service handles business logic, then calls `base.Add()` to reuse common DB operations.

---

## 🔹 Repository Pattern

> It separates database logic from business logic and provides reusable methods like Add, GetList, Update, Delete.

---

## 🔹 FluentValidation

> Validation is handled in the service layer using FluentValidation, which keeps controllers clean and centralizes validation rules.

👉 Example:

- Different validation rules based on shipment status

---

## 🔹 Activity Logging

> Activity logging is implemented inside a custom `SaveChangesAsync` method in repository.

Flow:

- Capture changes using EF ChangeTracker
- Save business data
- Then insert audit logs

👉 Tradeoff:

- Logging failure does not block main operation → possible audit gaps

---

## 🔹 TransactionScope

> Used to ensure atomic operations — either everything succeeds or everything rolls back.

---

# 🔁 API Flow (MOST IMPORTANT)

## Example: Create Shipment API

Flow:

1. Request hits Controller
2. Controller calls Service
3. Service:
   - Validates data (FluentValidation)
   - Maps DTO → Entity (AutoMapper)
   - Applies business logic
4. Repository:
   - Adds entity via EF Core
   - Calls SaveChangesAsync
5. EF Core:
   - Executes INSERT queries
6. Activity logging:
   - Logs changes using ChangeTracker
7. Response returned with ShipmentId

---

# ⚡ Performance Concepts

## 🔹 Pagination

> Implemented using Skip and Take with CountAsync.
> Helps handle large datasets.

⚠️ Issue:

- No max limit → can return huge data

---

## 🔹 Projections

> Used Select to fetch only required fields instead of full entity.

👉 Benefit:

- Reduces memory usage
- Improves query performance

---

## 🔹 Async/Await

> Used across controllers, services, and repositories to avoid thread blocking during DB calls.

⚠️ Improvement:

- Found one synchronous DB call inside async flow

---

## 🔹 Indexes

> Indexes are added via migrations on frequently queried fields like shipment and associate.

---

# ☁️ Async Systems (Important)

## 🔹 Hangfire

> Used for background jobs like invoice generation to avoid request timeout.

---

## 🔹 Azure Service Bus

> Used to decouple QuickBooks integration since it runs on client machines.

Flow:

- API → Message sent to queue
- QuickBooks connector processes it asynchronously

---

## 🔹 Invoice Flow

> API triggers background job → generates PDF → sends email → publishes message to Service Bus for QuickBooks sync.

---

## 🔹 Settlement Report

> Aggregates shipment and driver data to calculate payouts and generate reports.

---

# ⚠️ Tradeoffs / Improvements

You MUST mention these if asked:

- No optimistic concurrency → last-write-wins
- Activity logging may fail silently
- Pagination has no limit enforcement
- Double SaveChanges → performance overhead

---

# 🎯 Common Questions (With Answers)

### Why Repository Pattern?

> To separate DB logic and make code reusable.

---

### Why Async?

> To avoid blocking threads during DB calls and improve scalability.

---

### Why Service Bus?

> To decouple QuickBooks and handle offline scenarios.

---

### Why Hangfire?

> To process heavy operations like invoice generation in background.

---

### How multi-tenancy works?

> Tenant ID from JWT → resolves tenant-specific DB.

---

# 🛟 Safety Lines (Use When Stuck)

- “I worked around this flow but didn’t implement it end-to-end.”
- “At a high level, what happens is…”
- “My understanding is…”

---

# 🧠 Final Mental Model

Always answer in:

- Flow (what happens)
- Reason (why used)
- Tradeoff (what could go wrong)

---

# 🚀 You Are Ready

Revise this once or twice.
Speak out loud.

👉 You don’t need more content now — just **confidence + clarity**

---

If you want last step:
👉 say **“mock”** and I’ll simulate real arena in 5 mins.
