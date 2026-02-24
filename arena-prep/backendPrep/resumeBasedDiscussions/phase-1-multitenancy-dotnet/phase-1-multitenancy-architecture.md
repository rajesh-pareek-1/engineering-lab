# Phase 1 – Multi-Tenant Architecture (RollOnDispatch)

## 1. High-Level Architecture

### Two Database Model

- Global Database (AppGlobalContext)

  - Tenants
  - Users
  - Roles
  - Permissions
  - Accounts
  - Config
- Tenant Databases (Database-Per-Tenant)

  - Shipments
  - Loads
  - Business data
  - Domain entities

Each tenant database:

- Database name = Tenant GUID
- Password = HMAC(TenantGuid)

---

## 2. Tenant Identification Flow

1. JWT contains `tid` claim
2. ASP.NET middleware validates token
3. `RequestContext` extracts TenantId from claim
4. Stored as scoped dependency
5. Services use `ITenantDbContextFactory`
6. Factory builds tenant-specific connection string
7. DbContext created dynamically
8. Context cached per request

---

## 3. Why DbContext Is Not Registered Directly in DI

- Connection string depends on authenticated tenant
- Tenant resolved per request
- Cannot configure DbContext at startup
- Requires runtime instantiation

---

## 4. Why Reflection Is Used

- Factory is generic: `DbContext<T>()`
- Static factory methods live on concrete DbContext
- Cannot enforce static method contract (pre C# 11)
- Reflection used to dynamically invoke:
  - `CreateWithUserContext`
  - Fallback to `Create`

Improvement:

- Use static abstract interface members (C# 11)
- Or non-static factory pattern per context

---

## 5. Why Cache DbContext Per Request

Without caching:

- Multiple DbContext instances per request
- Multiple DB connections
- No shared transaction boundary
- Fragmented change tracking
- Performance overhead

With caching:

- Consistent unit-of-work
- Reduced connection churn
- Better transactional safety

---

## 6. Migration Strategy

Two migration tracks:

- Global DB migrations
- Tenant DB migrations (separate migration project)

Reasons for separate migration host:

- Avoid startup delay
- Prevent partial upgrades
- Controlled CI/CD rollout
- No multi-instance migration race conditions

---

## 7. Why Database-Per-Tenant

### Benefits

- Strong isolation
- Reduced blast radius
- Easier per-tenant backup/restore
- No noisy neighbor problem
- Independent scaling
- Safer background jobs

### Disadvantages

- Operational overhead
- Migration orchestration complexity
- Higher infrastructure cost
- Cross-tenant reporting complexity
- Connection pool scaling concerns

---

## 8. Scaling Evolution Strategy

At very large scale (e.g., 1M tenants):

Move to:

- Sharded multi-tenant architecture
- Tenant → Shard → Database mapping
- Hybrid model (large tenants isolated)

---

## 9. Security Risk: Deterministic Password

Password derived via HMAC(TenantGuid)

Risks:

- Secret key compromise = all DBs compromised
- Hard credential rotation
- Centralized security dependency

Better alternatives:

- Random per-tenant passwords in secure vault
- Azure Managed Identity


---
