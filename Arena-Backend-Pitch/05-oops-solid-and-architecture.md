# 5. OOP, SOLID, Dependency Injection, and Architecture

## OOP mnemonic: **A-PIE**

- **A - Abstraction:** expose what an object does, hide unnecessary detail.
- **P - Polymorphism:** one contract, multiple behaviors.
- **I - Inheritance:** derive specialized behavior from a base type.
- **E - Encapsulation:** protect state and invariants behind behavior.

### Backend examples

- **Abstraction:** `IShipmentService` hides workflow implementation from controller.
- **Polymorphism:** different notification providers implement one interface.
- **Inheritance:** a base service/controller can share genuinely common behavior.
- **Encapsulation:** a domain object prevents invalid status transitions.

Cross-question: **Abstraction vs encapsulation?**

> Abstraction reduces what a consumer needs to understand through a useful contract. Encapsulation protects internal state and implementation by controlling access. An interface is an abstraction; private fields and validated methods are encapsulation.

## Interface vs abstract class

> An interface defines a capability/contract and supports multiple interface implementation. An abstract class can contain shared state, constructors, and implemented behavior, but C# permits only one base class. I prefer an interface for service boundaries and an abstract base only when implementations have a true “is-a” relationship and meaningful shared behavior.

## Composition over inheritance

> Composition builds behavior from injected collaborators and is usually easier to change and test. Inheritance tightly couples derived classes to a base. I use inheritance only when substitutability and a stable hierarchy are real.

## SOLID mnemonic: **Change - Extend - Substitute - Focus - Invert**

### S - Single Responsibility

> A class should have one reason to change. A controller should not contain SQL, notification formatting, and billing logic. It should delegate the use case to focused services.

### O - Open/Closed

> A component should be extendable without repeatedly modifying stable orchestration. A notification strategy can add a new channel through another implementation.

### L - Liskov Substitution

> Any implementation must honor the expectations of its contract. A derived repository that unexpectedly throws for a supported operation violates substitutability.

### I - Interface Segregation

> Consumers should not depend on methods they do not use. Several focused interfaces are better than one huge service contract.

### D - Dependency Inversion

> High-level policy depends on abstractions, not concrete infrastructure. A reminder service can depend on `INotificationService`, while configuration selects the Azure implementation.

Cross-question: **Does every class need an interface?**

> No. Interfaces are useful at meaningful boundaries, for multiple implementations, decoupling, or test seams. Creating an interface for every class can add ceremony without flexibility.

## Dependency Injection

> DI supplies a class's dependencies from the outside, commonly through constructor injection. ASP.NET Core's container creates the object graph and manages lifetimes. It reduces hard coupling and makes dependencies explicit.

### Interview answer: benefits of DI

Mnemonic: **S-T-L-C**

- **S - Swappable implementations:** configuration can select a different provider.
- **T - Testability:** unit tests inject mocks or fakes.
- **L - Lifetime management:** the container manages transient, scoped, and singleton objects.
- **C - Clear dependencies:** constructor parameters show what a class needs.

> Dependency injection means a class receives its dependencies instead of constructing them. In Roll On Dispatch, a service can receive `IShipmentRepository`, `IEmailIntegration`, or `ILogger<T>` through its constructor. This reduces coupling, improves unit testing with Moq, centralizes object creation and lifetime configuration, and makes dependencies visible. DI itself does not automatically create good design; very large constructors can reveal that a class has too many responsibilities.

### “Program to an interface, not an implementation”

Bad coupling:

```csharp
public class DocumentReminderService
{
    private readonly TwilioEmailService _email = new();
}
```

The business service chooses and constructs one infrastructure implementation.

Better:

```csharp
public class DocumentReminderService
{
    private readonly IEmailIntegration _email;

    public DocumentReminderService(IEmailIntegration email)
    {
        _email = email;
    }
}
```

Registration:

```csharp
services.AddScoped<IEmailIntegration, TwilioEmailService>();
```

Test:

```csharp
var email = new Mock<IEmailIntegration>();
var service = new DocumentReminderService(email.Object);
```

> Programming to an interface means the high-level service depends on the capability it needs, not a specific provider. The composition root selects the implementation. This follows Dependency Inversion and makes replacement and testing easier. I do not create an interface for every class; I use one at meaningful boundaries or where alternative implementations/test seams add value.

### Lifetimes: **T-S-S**

- **Transient:** new instance each resolution; lightweight stateless service.
- **Scoped:** one per request/scope; typical for `DbContext` and business services.
- **Singleton:** one for application lifetime; must be thread-safe and cannot directly capture scoped dependencies.

Cross-question: **Why not singleton `DbContext`?**

> `DbContext` is not thread-safe, holds change-tracking state, and represents a unit of work. Sharing it across requests causes concurrency and stale-state problems.

Cross-question: **How can a singleton use scoped services?**

> Create an explicit scope through `IServiceScopeFactory` for each operation, as a hosted service does, then resolve and dispose scoped dependencies inside it.

## Controller-service-repository flow

```text
Controller = HTTP translation
    ↓
Service = use case + business coordination
    ↓
Repository/DbContext = persistence
    ↓
SQL Server
```

> A repository should add domain-specific persistence value, not merely duplicate every EF Core method. EF Core already provides repository/unit-of-work behavior. In an existing repository-based codebase, I follow the established pattern while keeping queries focused.

### Repository pattern advantages

Mnemonic: **P-T-R-C**

- **P - Persistence isolation:** business services do not contain repeated EF/query details.
- **T - Test seam:** services can use mocked repository contracts.
- **R - Reusable queries:** tenant filters, includes, projections, and common data operations stay consistent.
- **C - Centralized change:** persistence changes have a focused location.

```csharp
public interface IShipmentRepository
{
    Task<Shipment?> GetForDispatchAsync(
        int shipmentId,
        Guid tenantId,
        CancellationToken cancellationToken);

    Task UpdateAsync(
        Shipment shipment,
        CancellationToken cancellationToken);
}
```

> In ROD, repositories encapsulate EF Core access for shipments, driver loads, attachments, and tenant data. The service expresses the business workflow while the repository expresses the persistence operation. This improves consistency and testability. The trade-off is extra abstraction; a generic repository that only repeats `DbSet` methods adds little value, can hide useful EF features, and may create inefficient one-size-fits-all queries.

Cross-question: **Is EF Core already a repository and unit of work?**

> `DbSet<T>` provides repository-like access and `DbContext` acts as a unit of work. A custom repository is justified when it adds domain-focused queries, enforces data-access conventions, or creates a useful boundary—not simply because every entity must have one.

## Clean Architecture

```text
Outer: API / UI / infrastructure
              ↓ depends inward
Application: use cases and ports
              ↓
Core: domain rules and entities
```

> The dependency rule is the key: inner business logic should not depend on ASP.NET Core, SQL Server, or Azure details. Infrastructure implements interfaces defined closer to the use cases.

## Roll On Dispatch project architecture, layers, and domain

```text
Client layer
  ├── dm-web React application
  └── React Native driver application
           ↓ REST + JWT
API/presentation layer - RollOnDispatch
  ├── controllers, DTO/models, validation
  └── middleware/authentication/HTTP responses
           ↓
Application/business layer - Services and Helpers
  ├── shipment, driver-load, attachment, invoice workflows
  └── tenant rules, status transitions, job coordination
           ↓
Data-access layer - RollOnDispatch.Data
  ├── repositories and EF Core context
  ├── entity configurations and migrations
  └── SQL Server queries/transactions
           ↓
Infrastructure/integration
  ├── Azure Blob, notification services, Service Bus
  ├── Hangfire, QuickBooks, email/SMS
  └── logging and monitoring

Cross-cutting/domain support
  ├── RollOnDispatch.Common
  └── TenantManagement
```

### Spoken answer

> Roll On Dispatch is a layered modular monolith. Controllers are the HTTP boundary and receive DTOs. Services coordinate business use cases such as shipment, driver-load, attachment, and notification workflows. Repositories and EF Core handle persistence against SQL Server. Common code contains shared enums, exceptions, constants, and utilities, while TenantManagement handles tenants, users, roles, and authentication-related services. Infrastructure integrations include blob storage, Hangfire, notifications, messaging, and QuickBooks. Dependency injection connects the layers. The codebase follows layered and clean-architecture principles, although I would not claim it is a textbook strict Clean Architecture implementation.

### What is the domain?

> A domain is the business area and its rules, not simply a database folder. ROD's logistics domain includes shipments, shipment locations, customers/brokers, drivers, driver loads, cargo, trailers, documents, dispatch status transitions, invoicing, and tenant-specific operations. A business rule such as “a driver-load attachment may change operational status” belongs in the service/domain behavior, not in the controller or React client.

Cross-question: **Entity vs domain model vs DTO?**

> An EF entity represents persisted state. A domain model expresses business concepts and invariants; in many layered applications an entity may also carry some domain behavior. A DTO is a transport contract for the API and should not expose persistence details directly.

Cross-question: **Is your project strictly Clean Architecture?**

> It uses layered separation, interfaces, dependency injection, and reusable services. I would say it applies several clean-architecture principles, but I would not claim strict conformance without evaluating all dependency directions.

## Modular monolith

> A modular monolith deploys as one application but separates business modules with explicit boundaries. It keeps operational simplicity while reducing coupling. Modules should own their logic and avoid directly reaching into each other's internals.

### Modular monolith vs microservices

> Microservices add independent deployment and scaling but also network failures, distributed transactions, observability, and operational overhead. For many teams, a well-structured modular monolith is the better starting point. Extract a service only for a demonstrated boundary or scaling/ownership need.

## Patterns relevant to the projects

- **Repository:** encapsulates focused data-access operations.
- **Strategy:** interchangeable calculation or notification behavior.
- **Factory:** creates tenant-specific contexts or providers.
- **Decorator/middleware:** cross-cutting logging, exception handling, authorization.
- **Observer/pub-sub:** events or messages notify multiple consumers.
- **Outbox:** save business change and event in one SQL transaction, publish reliably later.

## Design pattern 1: Strategy Pattern

### Definition

> Strategy encapsulates interchangeable algorithms or providers behind one contract so the caller can select or receive a behavior without containing every implementation detail.

### ROD-grounded example

ROD tenant management registers multiple email integrations:

```csharp
public interface IEmailIntegration
{
    Task SendMail(EmailModel email);
    Task SendEmailWithAttachment(
        EmailModel email,
        Dictionary<string, byte[]> attachments);
}

public class TwilioEmailService : IEmailIntegration { /* ... */ }
public class AzureEmailService : IEmailIntegration { /* ... */ }
```

Registration:

```csharp
services.AddScoped<IEmailIntegration, AzureEmailService>();
services.AddScoped<IEmailIntegration, TwilioEmailService>();
```

Selection/orchestration:

```csharp
public EmailService(IEnumerable<IEmailIntegration> integrations)
{
    _emailProvider = integrations.First(
        provider => provider is TwilioEmailService);
}
```

> The providers are strategy implementations behind `IEmailIntegration`; `EmailService` is the context/orchestrator. The current code selects by concrete type, but a more extensible design would expose a provider key or `CanHandle` method and use configuration or a small factory. That avoids modifying the orchestrator whenever a new provider is added.

### Cleaner selection

```csharp
public interface IEmailStrategy
{
    string Provider { get; }
    Task SendAsync(EmailModel email);
}

public class EmailSender
{
    private readonly IReadOnlyDictionary<string, IEmailStrategy> _strategies;

    public EmailSender(IEnumerable<IEmailStrategy> strategies)
    {
        _strategies = strategies.ToDictionary(x => x.Provider);
    }

    public Task SendAsync(string provider, EmailModel email) =>
        _strategies[provider].SendAsync(email);
}
```

Benefits: removes large conditionals, supports extension, isolates provider logic, and makes each behavior testable. Cost: more types and selection/configuration complexity.

## Design pattern 2: Repository Pattern

> Repository provides a collection-like, domain-focused boundary over persistence. ROD services depend on repository interfaces such as shipment, driver-load, and attachment repositories. It separates use-case logic from EF Core query details and creates a test seam. It should expose meaningful operations such as `GetForDispatchAsync`, not merely copy every `DbSet` method.

Cross-question: **Strategy vs Factory?**

> Strategy represents interchangeable behavior used to perform work. Factory is responsible for creating or selecting an object. A factory may select a strategy, but the patterns solve different problems.

## Architecture cross-question chain

## System-design exercise: Student Documents with OCP

### First clarify the phrase "without developer changes"

> Open/Closed means the stable processing code is closed for modification but the system is open for extension. If the requirement is that administrators can add a new document type without a deployment, I would make document types and their validation metadata data-driven rather than adding a new enum value or `if/else` block. Completely new behavior can still require a new strategy implementation, but existing orchestration should remain unchanged.

Avoid this design:

```csharp
public enum DocumentType { Aadhaar, Passport }

if (type == DocumentType.Aadhaar) { /* rules */ }
else if (type == DocumentType.Passport) { /* rules */ }
// Every new type modifies and redeploys this code.
```

Use configuration entities instead:

```csharp
public class Student
{
    public long Id { get; set; }
    public string Name { get; set; } = default!;
    public ICollection<StudentDocument> Documents { get; set; } = [];
}

public class DocumentType
{
    public int Id { get; set; }
    public string Code { get; set; } = default!;       // PASSPORT
    public string DisplayName { get; set; } = default!;
    public bool RequiresExpiry { get; set; }
    public long MaxFileSizeBytes { get; set; }
    public string AllowedMimeTypes { get; set; } = default!;
    public bool IsActive { get; set; }
    public ICollection<DocumentFieldDefinition> Fields { get; set; } = [];
}

public class DocumentFieldDefinition
{
    public int Id { get; set; }
    public int DocumentTypeId { get; set; }
    public string Key { get; set; } = default!;        // passportNumber
    public string DataType { get; set; } = default!;   // string/date/number
    public bool IsRequired { get; set; }
    public string? ValidationPattern { get; set; }
}

public class StudentDocument
{
    public long Id { get; set; }
    public long StudentId { get; set; }
    public int DocumentTypeId { get; set; }
    public string BlobKey { get; set; } = default!;
    public string OriginalFileName { get; set; } = default!;
    public DateTimeOffset? Expiry { get; set; }
    public DocumentStatus Status { get; set; }
    public byte[] RowVersion { get; set; } = default!;
    public ICollection<StudentDocumentFieldValue> Values { get; set; } = [];
}
```

Generic validation reads definitions instead of branching by type:

```csharp
var type = await db.DocumentTypes
    .Include(x => x.Fields)
    .SingleAsync(x => x.Code == request.TypeCode && x.IsActive);

if (type.RequiresExpiry && request.Expiry is null)
    throw new ValidationException("Expiry is required.");

foreach (var definition in type.Fields.Where(x => x.IsRequired))
{
    if (!request.Fields.ContainsKey(definition.Key))
        throw new ValidationException($"{definition.Key} is required.");
}
```

An administrator can add `VISA` by inserting `DocumentType` and field-definition rows. Upload, list, expiry, and validation orchestration do not change.

### Cardinality

```text
Student       1 ───── * StudentDocument
DocumentType  1 ───── * StudentDocument
DocumentType  1 ───── * DocumentFieldDefinition
StudentDocument 1 ─── * StudentDocumentFieldValue
```

- One student can upload many documents.
- Each uploaded document has exactly one type.
- One type can describe many uploaded documents.
- A type can define zero or many configurable fields.
- A document can contain zero or many values for those definitions.

Useful constraints:

```csharp
modelBuilder.Entity<DocumentType>()
    .HasIndex(x => x.Code)
    .IsUnique();

modelBuilder.Entity<StudentDocument>()
    .Property(x => x.RowVersion)
    .IsRowVersion();

modelBuilder.Entity<StudentDocumentFieldValue>()
    .HasIndex(x => new { x.StudentDocumentId, x.DocumentFieldDefinitionId })
    .IsUnique();
```

### OCP cross-question

**Why not create `PassportDocument : StudentDocument`?**

> Inheritance works when document types have genuinely different behavior implemented by developers. It does not satisfy the requirement that operations can add types without code. Metadata-driven types fit that requirement better. If a future type needs special external verification, I would add an `IDocumentVerificationStrategy` selected by a key while keeping the upload workflow unchanged.

### Architecture cross-question chain continued

**Why layers?** Separation, testability, change isolation.

**What is the cost?** More types, mapping, and navigation.

**Where do transactions belong?** At the use-case boundary that knows which writes form one operation.

**Where does validation belong?** DTO shape at boundary, business rules in application/domain, integrity constraints in database.

**Where do logs belong?** Middleware for request-level data and services at meaningful business transitions/failures.

**How do you avoid an anemic service layer?** Put actual use-case coordination and domain decisions there, not only one-line repository pass-through methods.
