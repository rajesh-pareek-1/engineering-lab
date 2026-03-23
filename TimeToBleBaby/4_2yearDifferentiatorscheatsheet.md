# Backend Arena Kill Sheet (20 Topics)

---

# 1️⃣ Reflection (5)

**Trigger:** runtime metadata + performance overhead

**Answer**

Reflection allows runtime access to **type metadata, methods, and properties** .

**Insight**

Reflection is slower because it bypasses compile-time optimizations and involves **runtime lookup** . Cache results if used frequently.

---

# 2️⃣ IEnumerable vs IEnumerator (47)

**Trigger:** iteration state understanding

**Answer**

`IEnumerable` represents a **collection** , while `IEnumerator` manages the **iteration state** (`MoveNext`, `Current`).

**Insight**

Every `foreach` internally uses an enumerator.

Example flow

```
IEnumerable → GetEnumerator() → IEnumerator
```

---

# 3️⃣ Throw vs Throw ex (56/25)

**Trigger:** debugging awareness

**Answer**

`throw` preserves the **original stack trace** , while `throw ex` resets it.

**Insight**

Using `throw ex` hides the **real source of the exception** , making production debugging difficult.

---

# 4️⃣ Generics Performance (57)

**Trigger:** boxing awareness

**Answer**

Generics improve performance by **avoiding boxing and enabling compile-time type safety** .

**Insight**

Non-generic collections force value types to be **boxed to object** , increasing GC pressure.

---

# 5️⃣ IEnumerable vs IQueryable (64/133)

**Trigger:** database query optimization

**Answer**

`IQueryable` builds **expression trees executed by the database** , while `IEnumerable` executes **in memory** .

**Insight**

Using `IEnumerable` too early can cause **full table fetch + memory filtering → performance issues** .

---

# 6️⃣ Private Constructors (72)

**Trigger:** Singleton + controlled instantiation

**Answer**

Private constructors prevent external object creation.

**Insight**

Commonly used for **Singleton patterns and factory methods** .

Example use:

```
Singleton instance control
```

---

# 7️⃣ Destructors / Finalizers (74)

**Trigger:** unmanaged cleanup knowledge

**Answer**

Destructors run during **garbage collection** to clean unmanaged resources.

**Insight**

Objects with finalizers survive at least **one GC cycle** , increasing memory pressure.

---

# 8️⃣ Boxing / Unboxing Performance (77)

**Trigger:** heap allocation awareness

**Answer**

Boxing converts **value types to objects** , causing heap allocation.

**Insight**

Frequent boxing increases **GC load and memory usage** .

Hidden boxing example:

```
IEnumerable numbers = List<int>
```

Enumerator gets boxed.

---

# 9️⃣ GC Generations (80)

**Trigger:** GC internals

**Answer**

.NET heap is divided into **Gen0, Gen1, Gen2** based on object lifetime.

**Insight**

Frequent **Gen2 collections pause all threads (Stop-the-World)** .

---

# 🔟 Dispose vs Finalize (81)

**Trigger:** resource management

**Answer**

`Dispose` releases resources immediately, while `Finalize` relies on **GC timing** .

**Insight**

Failing to dispose resources can cause **connection pool or socket exhaustion** .

---

# 1️⃣1️⃣ LINQ Deferred Execution

**Trigger:** LINQ execution model

**Answer**

LINQ queries execute **only when enumerated** .

Triggers:

```
foreach
ToList()
First()
```

**Insight**

Multiple enumeration can **re-run expensive queries** .

---

# 1️⃣2️⃣ N+1 Query Problem

**Trigger:** ORM optimization awareness

**Answer**

Occurs when fetching related data results in **one query per record** .

**Insight**

Use:

- eager loading
- projection
- batching

---

# 1️⃣3️⃣ Async vs Threading

**Trigger:** concurrency understanding

**Answer**

`async/await` enables **non-blocking IO** , not parallelism.

**Insight**

Improves scalability by freeing **threads during IO waits** .

---

# 1️⃣4️⃣ Thread Pool Starvation

**Trigger:** async misuse detection

**Answer**

Occurs when threads block waiting for async operations.

Bad patterns:

```
task.Result
task.Wait()
```

**Insight**

Blocking async code can freeze high-traffic APIs.

---

# 1️⃣5️⃣ HttpClient Misuse

**Trigger:** networking knowledge

**Answer**

Creating `HttpClient` per request opens **new TCP sockets** .

**Insight**

Sockets remain in **TIME_WAIT** , causing **socket exhaustion** .

Solution:

```
IHttpClientFactory
```

---

# 1️⃣6️⃣ Dependency Injection Lifetimes

**Trigger:** ASP.NET Core architecture

**Answer**

```
Singleton → app lifetime
Scoped → request lifetime
Transient → new instance
```

**Insight**

Injecting **Scoped into Singleton** causes runtime errors, Captive dependency issue(a service lives longer than it should).

---

# 1️⃣7️⃣ DbContext Lifetime

**Trigger:** EF Core knowledge

**Answer**

`DbContext` should be **scoped per request** .

**Insight**

It is **not thread-safe** , sharing across threads causes corruption.

---

# 1️⃣8️⃣ Connection Pooling

**Trigger:** database performance

**Answer**

Connection pools reuse **database connections** instead of creating new ones.

**Insight**

Not disposing connections causes **pool exhaustion** .

---

# 1️⃣9️⃣ Caching Strategies

**Trigger:** performance architecture

**Answer**

Use caching to reduce repeated computations or DB calls.

**Insight**

Unbounded caches cause **memory growth → Gen2 GC pressure** .

---

# 2️⃣0️⃣ Horizontal Scaling

**Trigger:** distributed system awareness

**Answer**

Scaling by adding more servers behind a **load balancer** .

**Insight**

Requires **stateless APIs and externalized state** .

---

# 🧠 10 Arena Power Lines (Memorize)

These lines instantly signal **strong backend understanding** .

1️⃣ Most objects die young, which is why .NET uses **generational GC** .

2️⃣ `throw ex` destroys the **original stack trace** .

3️⃣ Generics avoid **boxing and heap allocations** .

4️⃣ `IQueryable` pushes filtering **to the database** .

5️⃣ Finalizers delay memory cleanup and increase **GC cost** .

6️⃣ Improper `HttpClient` usage causes **socket exhaustion** .

7️⃣ Blocking async calls can cause **thread pool starvation** .

8️⃣ Unbounded caches lead to **Gen2 GC pauses** .

9️⃣ `DbContext` must be **scoped because it's not thread-safe** .

🔟 Stateless APIs are required for **horizontal scaling** .

Absolutely! Here’s a **brain-friendly, arena-ready cheat sheet** for the 10 topics you listed. I’ve structured it to cover: **question** , **best answer** , **arena insight** , **production insight** , and **visual/memory tick** —all in a compact format.

---

# **Backend Arena Kill Sheet (Part 2)**

---

### 1️⃣ **Circular Reference (85)**

**Q:** What are circular references and why are they dangerous?

**Best Answer:**
Circular references occur when objects reference each other directly or indirectly, preventing garbage collection from freeing memory.

**Arena Expectation:**
Tests memory management knowledge and ability to prevent **memory leaks in complex object graphs** .

**Production Insight:**
Leaked memory in services with long-lived objects or cached entities can cause **GC pressure and OutOfMemory exceptions** .

**Memory Tick:**

```
A → B → C → A  ❌ GC cannot collect
```

---

### 2️⃣ **ConfigureServices vs Configure (92/93)**

**Q:** Difference between ConfigureServices and Configure in ASP.NET Core?

**Best Answer:**

- `ConfigureServices`: Register dependencies in **DI container** .
- `Configure`: Build **HTTP middleware pipeline** .

**Arena Expectation:**
Tests understanding of **startup lifecycle** and **DI vs middleware separation** .

**Production Insight:**
Middleware **order matters** ; wrong order breaks routing/auth.

**Memory Tick:**

```
ConfigureServices → what exists
Configure → how requests flow
```

---

### 3️⃣ **Request Processing Pipeline (94)**

**Q:** How does an HTTP request travel in ASP.NET Core?

**Best Answer:**
Client → Kestrel → Middleware chain → Routing → Controller → Business logic → Response back through middleware → Client

**Arena Expectation:**
Shows **holistic understanding of request lifecycle** .

**Production Insight:**
Middleware **order matters** ; short-circuiting or branching is common in prod apps.

**Memory Tick (6-line diagram):**

```
Client
 ↓
Kestrel
 ↓
Middleware
 ↓
Routing → Controller
 ↓
Response back
```

---

### 4️⃣ **Custom Middleware (104)**

**Q:** Why use custom middleware?

**Best Answer:**
To handle **cross-cutting concerns** like logging, authentication, error handling in one centralized place.

**Arena Expectation:**
Tests ability to implement **reusable, centralized logic** in the request pipeline.

**Production Insight:**
Efficient for logging, correlation IDs, request timing, and centralized error handling.

**Memory Tick:**

```
Request → Middleware → Controller
Response ← Middleware
```

---

### 5️⃣ **Request Delegate (106)**

**Q:** What is a RequestDelegate?

**Best Answer:**
It’s a function that receives `HttpContext` and represents the **next middleware** in the pipeline.

**Arena Expectation:**
Tests **low-level understanding** of middleware chaining.

**Production Insight:**
Understanding RequestDelegate helps in **custom middleware, pipeline short-circuiting, and minimal APIs** .

**Memory Tick:**

```
Middleware1 → Middleware2 → Middleware3 → Endpoint
Each calls _next(HttpContext)
```

---

### 6️⃣ **DI Lifetimes (AddSingleton, AddScoped, AddTransient) (120/121)**

**Q:** Differences between DI lifetimes and captive dependencies?

**Best Answer:**

- **Singleton** : One instance app-wide
- **Scoped** : One instance per HTTP request
- **Transient** : New instance per injection

**Captive dependency:** A long-lived service (Singleton) depends on a short-lived service (Scoped) → causes concurrency bugs.

**Arena Expectation:**
Checks awareness of **object lifetimes and concurrency issues** .

**Production Insight:**
Singleton holding DbContext → shared state → race conditions → production crashes.

**Memory Tick:**

```
Transient → Scoped → Singleton ✅
Singleton → Scoped ❌
```

---

### 7️⃣ **Connected vs Disconnected Architecture (172)**

**Q:** Difference and use case?

**Best Answer:**

- **Connected:** Keeps live DB connection; uses Change Tracker
- **Disconnected:** Fetches data, detaches, modifies, reattaches to save

**Arena Expectation:**
Tests **knowledge of entity tracking vs stateless data flow** .

**Production Insight:**
Disconnected architecture fits **web apps/microservices** ; avoids long-lived connections and memory pressure.

**Memory Tick:**

```
Connected: Fetch → Modify → Save
Disconnected: Fetch → Detach → Modify → Reattach → Save
```

---

### 8️⃣ **ORM Approaches (180)**

**Q:** Code-First vs DB-First?

**Best Answer:**

- **Code-First:** Define C# classes → generate DB → migrations → CI/CD
- **DB-First:** Generate C# classes from existing DB; manual sync

**Arena Expectation:**
Checks **ability to plan CI/CD-friendly DB strategy** .

**Production Insight:**
Code-First is preferred for **greenfield apps** ; DB-First is for legacy.

**Memory Tick:**

```
Code-First: C# → DB → Migration → CI/CD
DB-First: DB → C# → Manual sync
```

---

### 9️⃣ **Web API vs MVC Controller (189)**

**Q:** Difference and when to use?

**Best Answer:**

- **MVC Controller:** Returns Views + Data; can be stateful
- **Web API Controller:** Returns JSON/XML; stateless; automatic content negotiation

**Arena Expectation:**
Tests **API vs server-rendered app design awareness** .

**Production Insight:**
Modern SPAs + mobile apps → always use Web API controllers; MVC only for legacy pages.

**Memory Tick:**

```
MVC → Views + Data
API → Data only, Stateless
```

---

### 🔟 **Basic vs API Key vs JWT Auth (191/195)**

**Q:** Differences for N-tenant apps?

**Best Answer:**

- **Basic:** Username/password per request; unsafe over HTTP
- **API Key:** Service token; good for internal APIs
- **JWT:** Signed claims; stateless, scalable; supports multi-tenant

**Arena Expectation:**
Tests ability to **choose proper authentication** for scale and tenants.

**Production Insight:**
JWT preferred for **multi-tenant APIs and SPAs** ; Basic Auth only for legacy; API Key for service-to-service calls.

**Memory Tick:**

Basic = Password (unsafe)
API Key = Service token
JWT = Claims + Signature (stateless)
