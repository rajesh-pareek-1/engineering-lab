# DOTNET_DEEP

Deep source material. Do not open during final-hour revision.

## Web API Deep Dive

## .NET Platform Evolution

`.NET Framework -> .NET Core -> .NET 5+`

Interview line:

```text
.NET Framework was Windows-only and legacy. .NET Core made the platform cross-platform, modular, and faster. Modern .NET 5+ unified the platform for web, cloud, APIs, desktop, and services.
```

## MVC vs Web API

| Topic | MVC | Web API |
| --- | --- | --- |
| Purpose | UI web apps | Data/API communication |
| Output | HTML views | JSON/XML |
| Main caller | Browser | SPA, mobile app, service |
| Controller style | ViewResult | IActionResult / ActionResult<T> |

Interview line:

```text
MVC renders UI. Web API exposes data and behavior to clients using HTTP.
```

## Razor vs MVC

- Razor is a view engine.
- MVC is an architectural framework.
- Razor lets C# generate dynamic HTML inside MVC views.

## ASP.NET Core Request Lifecycle

```text
Client -> Kestrel -> Middleware pipeline -> Routing -> Controller -> Action -> Response returns through middleware in reverse
```

Typical middleware order:

```csharp
app.UseExceptionHandler();
app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

Key line:

```text
Middleware works at pipeline level. Filters work around controller/action execution.
```

## Middleware

Middleware is a component that handles request/response flow.

Key points:

- Order matters.
- It can short-circuit.
- It uses `HttpContext`.
- Good for cross-cutting concerns like auth, logging, exception handling, rate limiting, correlation IDs.

Custom middleware skeleton:

```csharp
public sealed class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;

    public ErrorHandlingMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(new { error = "Unexpected error" });
        }
    }
}
```

## Filters

Filters run inside MVC/Web API action execution.

Common types:

- Authorization filter
- Resource filter
- Action filter
- Exception filter
- Result filter

Use middleware for global request concerns. Use filters for controller/action-specific policies.

## Model Binding

Model binding maps request data to action parameters.

Sources:

- Route values
- Query string
- Request body
- Headers
- Form data

Example:

```csharp
[HttpPost("{tenantId}")]
public async Task<ActionResult<ShipmentDto>> Create(Guid tenantId, CreateShipmentRequest request)
```

## IActionResult vs ActionResult<T>

| Type | Use |
| --- | --- |
| `IActionResult` | Flexible response type, no compile-time body type |
| `ActionResult<T>` | Flexible status code plus typed response body |

Interview line:

```text
I prefer ActionResult<T> for APIs because it keeps response shape clear while still allowing NotFound, BadRequest, and other HTTP results.
```

## Global Exception Handling

Good API exception handling should:

- Catch unhandled errors once.
- Log with correlation/request ID.
- Return consistent error shape.
- Avoid leaking stack traces.

Production line:

```text
In production I would centralize exception handling in middleware so controllers stay clean and clients receive consistent error responses.
```

## JWT Authentication

Flow:

1. User logs in.
2. Server validates credentials.
3. Server issues JWT with claims.
4. Client sends `Authorization: Bearer <token>`.
5. Authentication middleware validates token and fills `HttpContext.User`.
6. Authorization checks roles/policies/claims.

Auth vs authz:

```text
Authentication verifies who you are. Authorization verifies what you can access.
```

## OAuth vs OpenID Connect

- OAuth: authorization, delegated access.
- OpenID Connect: authentication layer on top of OAuth, gives identity information.

Memory line:

```text
OAuth is access. OpenID Connect is login.
```

## Securing Web APIs

Checklist:

- HTTPS only
- JWT validation with issuer/audience/expiry
- Role/policy-based authorization
- Input validation
- Rate limiting
- CORS locked to known origins
- Structured logging
- No secrets in code
- Consistent error handling
- Pagination limits

## API Versioning

Options:

- URL: `/api/v1/shipments`
- Header: `api-version: 1`
- Query: `?api-version=1`

Interview line:

```text
Versioning allows API evolution without breaking existing clients.
```

## Newtonsoft.Json vs System.Text.Json

| Topic | Newtonsoft.Json | System.Text.Json |
| --- | --- | --- |
| Strength | Flexible, mature, many features | Faster, built into modern .NET |
| Use case | Complex converters/legacy behavior | Default modern APIs |

Circular reference options:

```csharp
options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
```

Best fix is often DTO projection instead of serializing EF entities directly.

## Caching

| Cache | Use | Tradeoff |
| --- | --- | --- |
| In-memory | Single instance, low latency | Not shared across servers |
| Distributed/Redis | Shared cache for web farms | Network hop and invalidation complexity |
| Response cache | Cache HTTP responses | Must handle auth and stale data carefully |

Interview line:

```text
Caching improves read latency and reduces DB load, but cache invalidation and stale data must be designed explicitly.
```

## Queues and Background Processing

Use queues/background jobs when:

- Work is slow.
- External systems may be offline.
- The API should respond quickly.
- Retries are needed.

Examples:

- Hangfire for invoice generation and scheduled jobs.
- Azure Service Bus for QuickBooks sync or service-to-service asynchronous work.

## High Request Load

For 100+ requests/second:

- Use async all the way.
- Add pagination and max limits.
- Cache hot reads.
- Move heavy work to queues.
- Optimize DB queries and indexes.
- Use rate limiting.
- Add observability.
- Scale horizontally if stateless.

## Idempotency

Idempotency means the same request can be retried safely.

Use for:

- Payments
- Invoice creation
- External sync
- Queue consumers

Pattern:

```text
Client sends idempotency key -> server checks processed table -> returns existing result or processes once
```

## HttpClient

Bad:

```csharp
using var client = new HttpClient();
```

Problem: socket exhaustion due to many TCP connections in `TIME_WAIT`.

Good:

```csharp
builder.Services.AddHttpClient<IQuickBooksClient, QuickBooksClient>();
```

## Monolith vs Microservices

| Topic | Monolith | Microservices |
| --- | --- | --- |
| Complexity | Lower | Higher |
| Deployment | One unit | Many units |
| Data | Shared DB possible | Database per service preferred |
| Communication | In-process | REST/gRPC/queue |

Interview line:

```text
Microservices help independent scaling and ownership, but add operational complexity, network failures, observability needs, and distributed data consistency problems.
```

## API Gateway

An API gateway is a single entry point for multiple services.

Responsibilities:

- Routing
- Authentication
- Rate limiting
- Request aggregation
- TLS termination
- Observability

## Misc Quick Lines

- `bin` contains final compiled output.
- `obj` contains intermediate build artifacts.
- Debug builds include symbols and less optimization.
- Release builds are optimized for production.
- NuGet is .NET's package manager.
- Kestrel is the cross-platform ASP.NET Core web server.

## C# Runtime Performance Deep Dive

## CLR, JIT, MSIL

Flow:

```text
C# source -> compiler -> IL/MSIL -> assembly -> CLR loads -> JIT compiles to machine code -> executes
```

Definitions:

- CLR: runtime engine for .NET. Handles memory, GC, exceptions, security, and JIT.
- MSIL/IL: intermediate language generated by C# compiler.
- JIT: converts IL to machine code at runtime.
- Assembly: compiled deployable unit, usually `.dll` or `.exe`.
- Namespace: logical code organization.
- Manifest: assembly metadata.
- GAC: global assembly cache from older .NET Framework world.

## Managed vs Unmanaged Code

| Managed | Unmanaged |
| --- | --- |
| Runs under CLR | Runs outside CLR |
| GC handles memory | Manual/resource-specific cleanup |
| C#, F#, VB.NET | Native C/C++ style code |

## Value Type vs Reference Type

| Topic | Value type | Reference type |
| --- | --- | --- |
| Examples | `int`, `bool`, `DateTime`, `struct` | `class`, `string`, arrays, objects |
| Assignment | Copies value | Copies reference/address |
| Mutation | Independent copy | Shared object can mutate |

Interview line:

```text
Assignment copies references, mutation changes shared object state, and reassignment changes only the local variable unless passed by ref.
```

## String vs StringBuilder

- `string` is immutable.
- Repeated string concatenation creates many objects.
- `StringBuilder` is better for repeated modifications.

## ref vs out

| Topic | ref | out |
| --- | --- | --- |
| Must be initialized before call | Yes | No |
| Must be assigned inside method | No | Yes |
| Use | Method may read and modify | Method returns extra value |

## var vs dynamic

| Topic | var | dynamic |
| --- | --- | --- |
| Type decided | Compile time | Runtime |
| Safety | Compile-time checked | Runtime failures possible |
| Use | Cleaner local variable syntax | Interop/dynamic payloads |

## const vs readonly

| Topic | const | readonly |
| --- | --- | --- |
| Value set | Compile time | Constructor/runtime |
| Belongs to | Type | Instance or type |
| Use | True constants | Runtime initialized immutable values |

## Throw vs Throw ex

```csharp
catch (Exception)
{
    throw; // preserves original stack trace
}
```

Avoid:

```csharp
catch (Exception ex)
{
    throw ex; // resets stack trace
}
```

Interview line:

```text
Using throw ex hides the real source of the exception, which is painful in production debugging.
```

## finally vs Finalize vs Dispose

| Topic | Meaning |
| --- | --- |
| `finally` | Code block that runs after try/catch flow. |
| `Finalize`/destructor | GC-time cleanup hook for unmanaged resources. Non-deterministic. |
| `Dispose` | Deterministic cleanup method for resources like files, DB connections, sockets. |

Use `using` for `IDisposable`:

```csharp
using var stream = File.OpenRead(path);
```

## Garbage Collection

GC automatically releases managed memory for unreachable objects.

Generations:

- Gen 0: short-lived objects.
- Gen 1: survivors from Gen 0.
- Gen 2: long-lived objects.

Production insight:

```text
Frequent Gen 2 collections can pause the app. Reduce allocations, avoid boxing in hot paths, and dispose external resources quickly.
```

## Boxing and Unboxing

Boxing:

```csharp
int x = 10;
object o = x; // boxes value into heap object
```

Unboxing:

```csharp
int y = (int)o;
```

Problem:

- Heap allocation
- Extra GC pressure
- Runtime cast risk

Generics avoid boxing:

```csharp
List<int> safe = new();
ArrayList boxed = new(); // legacy, boxes ints
```

## Generics

Generics provide:

- Type safety
- Reuse
- Less boxing
- Compile-time checks

Constraints:

```csharp
class Repo<T> where T : class, new() {}
class ValueRepo<T> where T : struct {}
class Service<T> where T : IHandler {}
```

Trap:

```text
new() only supports parameterless constructors.
```

## Delegates, Func, Action, Events

- Delegate: type-safe method pointer.
- `Action<T>`: delegate with no return.
- `Func<T, TResult>`: delegate with return.
- `Predicate<T>`: `Func<T, bool>`.
- Event: restricted delegate, only owner can invoke.

Multicast trap:

```text
Multicast delegates execute all methods but return only the last return value.
```

Memory leak trap:

```text
Publisher holds subscriber through event subscription. Unsubscribe when subscriber lifetime is shorter.
```

## Thread vs Task vs Async

| Topic | Meaning |
| --- | --- |
| Thread | OS-level execution resource. |
| Task | Work abstraction, often scheduled on thread pool. |
| async/await | Non-blocking async flow, best for I/O. |

Key lines:

- `await` pauses the method, not the thread.
- Async is not the same as parallelism.
- CPU-bound work may use `Task.Run`.
- I/O-bound work should use native async APIs.

## Deadlock and Blocking Traps

Avoid:

```csharp
var result = GetDataAsync().Result;
GetDataAsync().Wait();
```

Prefer:

```csharp
var result = await GetDataAsync();
```

`async void`:

- Avoid except UI/event handlers.
- Cannot be awaited.
- Exceptions escape normal try/catch flow.

`Task.WhenAll`:

```csharp
var a = FetchAAsync();
var b = FetchBAsync();
await Task.WhenAll(a, b);
```

## Locks and Thread Safety

`lock` allows one thread at a time into a critical section.

Use when shared mutable state must be protected.

Prefer avoiding shared mutable state when possible.

## ConcurrentDictionary

Use for thread-safe dictionary operations across multiple threads.

Still design carefully: thread-safe collection does not make the entire workflow atomic.

## HttpClient and Connection Pooling

Do not create `HttpClient` per request. Use `IHttpClientFactory`.

DB connection pooling reuses physical connections and reduces connection overhead.

Trap:

```text
Not disposing connections or leaking DbContexts can cause pool exhaustion.
```

## C# OOP SOLID Deep Dive

## Core OOP Terms

| Concept | Interview answer |
| --- | --- |
| Class | Blueprint for objects. |
| Object | Runtime instance of a class. |
| Encapsulation | Wrap data and behavior together and protect state. |
| Abstraction | Expose what is needed and hide implementation details. |
| Inheritance | Reuse/extend behavior from a base class. |
| Polymorphism | Same call can execute different implementations at runtime. |

## Constructor Types

| Type | Meaning |
| --- | --- |
| Default constructor | Parameterless constructor. Auto-created only if no constructor is defined. |
| Parameterized constructor | Accepts values needed to initialize object state. |
| Copy constructor | Creates a new object from another object. |
| Static constructor | Initializes static members once before first use. Cannot take parameters. |

Key trap:

```text
If you define any constructor, C# does not auto-generate the parameterless constructor.
```

## Interface vs Abstract Class

| Topic | Interface | Abstract class |
| --- | --- | --- |
| Purpose | Contract/capability | Shared base behavior plus contract |
| State | Usually no instance state | Can contain state |
| Constructor | No instance constructor | Can have constructor |
| Multiple inheritance | A class can implement many interfaces | A class inherits one base class |
| Best for | Capabilities like `ICanFly`, `IRepository` | Shared template like `BaseEntityService` |

Interview line:

```text
Interface defines what a type can do. Abstract class can define partial how plus shared state or behavior.
```

## Overloading vs Overriding

| Topic | Overloading | Overriding |
| --- | --- | --- |
| Where | Same class | Base/derived class |
| Signature | Same name, different parameters | Same signature |
| Binding | Compile time | Runtime |
| Keywords | None | `virtual`, `override` |

## Access and Type Modifiers

- `public`: accessible everywhere.
- `private`: only inside same class.
- `protected`: inside class and derived classes.
- `internal`: same assembly.
- `static`: belongs to type, not instance.
- `sealed`: cannot be inherited.
- `partial`: class split across files.
- `abstract`: cannot instantiate directly.

## SOLID Overview

| Letter | Principle | One-line memory |
| --- | --- | --- |
| S | Single Responsibility | One reason to change. |
| O | Open/Closed | Open for extension, closed for modification. |
| L | Liskov Substitution | Child should replace parent without breaking behavior. |
| I | Interface Segregation | Keep interfaces small and client-specific. |
| D | Dependency Inversion | Depend on abstractions, not concrete details. |

## Single Responsibility Principle

Bad smell:

```text
One class handles visitors, staff, animals, billing, logging, and DB access.
```

Better:

```text
Visitor, Staff, Animal, TicketService, AuditLogger
```

Interview line:

```text
SRP reduces merge conflicts, improves testability, and makes change impact easier to reason about.
```

## Open/Closed Principle

Bad:

```csharp
if (bird.Type == "Sparrow") FlyFast();
else if (bird.Type == "Eagle") FlyHigh();
else if (bird.Type == "Peacock") FlyLow();
```

Better:

```csharp
public interface IFlyBehavior
{
    void Fly();
}

public sealed class EagleFlyBehavior : IFlyBehavior
{
    public void Fly() => Console.WriteLine("Fly high");
}
```

Interview line:

```text
I use polymorphism or strategy patterns when new behavior should be added without editing a large if-else chain.
```

## Liskov Substitution Principle

Violation:

```text
Bird has Fly(), but Kiwi cannot fly and throws NotSupportedException.
```

Better:

```csharp
public abstract class Bird
{
    public abstract void Speak();
}

public interface ICanFly
{
    void Fly();
}

public sealed class Sparrow : Bird, ICanFly
{
    public override void Speak() {}
    public void Fly() {}
}
```

Interview line:

```text
If a child type has to throw or ignore a parent behavior, the inheritance model is probably wrong.
```

## Interface Segregation Principle

Bad:

```csharp
public interface IWorker
{
    void Work();
    void Eat();
    void Fly();
    void Swim();
}
```

Better:

```csharp
public interface IWorker { void Work(); }
public interface IFlyer { void Fly(); }
public interface ISwimmer { void Swim(); }
```

Interview line:

```text
Clients should not implement methods they do not use. Thin interfaces keep code flexible and testable.
```

## Dependency Inversion Principle

High-level code should not create low-level dependencies directly.

Bad:

```csharp
public sealed class InvoiceService
{
    private readonly SqlInvoiceRepository _repo = new();
}
```

Better:

```csharp
public sealed class InvoiceService
{
    private readonly IInvoiceRepository _repo;

    public InvoiceService(IInvoiceRepository repo)
    {
        _repo = repo;
    }
}
```

Interview line:

```text
DIP is the principle. Dependency injection is one practical way to achieve it.
```

## Dependency Injection Types

- Constructor injection: preferred for required dependencies.
- Property injection: optional dependency.
- Method injection: dependency needed for one operation.

DI lifetime quick table:

| Lifetime | Scope | Common use |
| --- | --- | --- |
| Transient | New every resolve | Lightweight stateless services |
| Scoped | One per request | DbContext, request services |
| Singleton | One for app | Config, caches, stateless clients |

DbContext should be scoped because it tracks changes and is not thread-safe.

## Design Pattern Quick Lines

- Singleton: one instance, must be thread-safe.
- Factory: centralizes object creation.
- Abstract factory: creates related object families.
- Strategy: swaps behavior without if-else chains.
- Repository: separates data access from business logic.

## EF Core LINQ Deep Dive

## IEnumerable vs IEnumerator

| Topic | Meaning |
| --- | --- |
| `IEnumerable` | Represents something that can be iterated. |
| `IEnumerator` | Holds iteration state: `MoveNext`, `Current`. |

`foreach` uses an enumerator internally.

## IEnumerable vs IQueryable

| Topic | IEnumerable | IQueryable |
| --- | --- | --- |
| Executes | In memory | Provider/database |
| Query form | Delegates | Expression tree |
| Risk | Pulls too much data if used early | Provider translation limits |

Interview line:

```text
IQueryable lets EF Core translate filtering/projection into SQL. IEnumerable means the data is already in memory.
```

Bad:

```csharp
var users = await _context.Users.ToListAsync();
var active = users.Where(x => x.IsActive);
```

Better:

```csharp
var active = await _context.Users
    .Where(x => x.IsActive)
    .ToListAsync();
```

## Deferred Execution

LINQ queries run when enumerated.

Execution triggers:

- `foreach`
- `ToList()`
- `First()`
- `Count()`
- `Any()`

Trap:

```text
Multiple enumeration can repeat expensive work or repeat DB queries.
```

## Expression Trees

`IQueryable` captures query logic as an expression tree. EF Core translates it into SQL.

If EF cannot translate an expression, rewrite it or explicitly move to memory only after filtering.

## First, Single, Any, Count

| Method | Meaning |
| --- | --- |
| `First()` | Returns first match, throws if none. |
| `FirstOrDefault()` | Returns first match or default. |
| `Single()` | Requires exactly one match, throws if zero or many. |
| `SingleOrDefault()` | Allows zero or one, throws if many. |
| `Any()` | Existence check, stops early. |
| `Count()` | Counts all matching rows/items. |

Use `Any()` for existence checks.

## Include vs Select

| Method | Use |
| --- | --- |
| `Include` | Eager-load related entities. |
| `Select` | Project only required fields. |

Prefer projection for API DTOs:

```csharp
var shipments = await _context.Shipments
    .Where(x => x.Status == ShipmentStatus.Open)
    .Select(x => new ShipmentListItem
    {
        Id = x.Id,
        Number = x.Number,
        DriverName = x.Driver.Name
    })
    .ToListAsync();
```

## Lazy vs Eager Loading

- Lazy loading loads related data on demand.
- Eager loading loads related data upfront.
- Lazy loading can cause N+1 queries.

## N+1 Problem

Problem:

```text
1 query loads parent rows. Then N extra queries load children for each parent.
```

Fixes:

- Projection with `Select`
- `Include`
- Batching
- Explicit joins where needed

## AsNoTracking

Use for read-only queries:

```csharp
var rows = await _context.Shipments
    .AsNoTracking()
    .Where(x => x.TenantId == tenantId)
    .ToListAsync();
```

Benefit:

```text
No change tracking means less memory and faster read queries.
```

## SaveChanges

`SaveChanges` / `SaveChangesAsync`:

- Detects tracked entity changes.
- Wraps operations in a transaction by default for many providers.
- Sends SQL to DB.
- Updates entity states.

Avoid multiple `SaveChanges` in one workflow unless the partial commit is intentional.

## DbContext Lifetime

Use scoped lifetime.

Reasons:

- DbContext is not thread-safe.
- Tracks changes per unit of work/request.
- One request usually equals one transaction boundary.

## Transactions and ACID

ACID:

- Atomicity: all or nothing.
- Consistency: valid state.
- Isolation: concurrent transactions do not corrupt each other.
- Durability: committed data survives failure.

Use transactions when multiple operations must succeed or fail together.

## Repository Pattern

Repository separates data access from business logic.

Good use:

- Shared query helpers.
- Encapsulating DB details.
- Testing service layer.

Risk:

```text
Do not hide IQueryable too early if callers need composition. Avoid generic repository that prevents optimized queries.
```

## ORM, Code First, DB First

- ORM maps objects to relational data.
- EF Core is an ORM.
- Code First: classes drive schema/migrations.
- DB First: existing DB drives models.

## Production Query Checklist

Before saying "I optimized the query", mention:

1. Filter early.
2. Project only needed columns.
3. Avoid N+1.
4. Add indexes on WHERE/JOIN/ORDER columns.
5. Use `AsNoTracking` for read-only.
6. Check execution plan.
7. Add pagination/max limits.
8. Avoid unnecessary `ToList()`.
