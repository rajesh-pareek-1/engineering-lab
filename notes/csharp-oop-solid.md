# C# OOP and SOLID

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

