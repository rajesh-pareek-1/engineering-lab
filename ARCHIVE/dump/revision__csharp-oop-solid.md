# C# OOP And SOLID Revision

## Must-Say Lines

- Encapsulation protects state; abstraction hides implementation details.
- Interface is a contract/capability; abstract class can share state or partial behavior.
- Overloading is same name different parameters; overriding is runtime polymorphism from base to child.
- If a child throws for parent behavior, the inheritance model is probably wrong.
- DIP is the principle; dependency injection is one implementation technique.
- Constructor injection is preferred for required dependencies.

## OOP Quick Map

| Concept | Interview line |
| --- | --- |
| Class | Blueprint. |
| Object | Runtime instance. |
| Encapsulation | Keep state and behavior together, expose safe operations. |
| Abstraction | Show what matters, hide implementation. |
| Inheritance | Reuse/extend common behavior. |
| Polymorphism | Same call can execute different implementation. |

Edge cases:

- If any constructor is defined, C# does not generate the default parameterless constructor.
- `static` belongs to type, not instance.
- `sealed` prevents inheritance.
- `internal` means same assembly.

## Interface vs Abstract Class

| Interface | Abstract class |
| --- | --- |
| Capability/contract | Shared base behavior/template |
| Multiple can be implemented | Only one base class |
| Best for DI and testing | Best for related family with shared state |
| Flexible composition | Stronger inheritance coupling |

Strong answer:

```text
I use interfaces for dependencies and capabilities. I use abstract classes when related types share implementation or state. Interfaces keep design flexible because a class can implement many, but inherit only one base class.
```

## SOLID

| Principle | Speakable version | Interview edge |
| --- | --- | --- |
| SRP | One reason to change. | Avoid service that does validation, DB, email, logging, and mapping all together. |
| OCP | Extend without editing stable code. | Strategy/polymorphism can replace long if-else chains. |
| LSP | Child can replace parent safely. | Do not put `Fly()` on all birds if some cannot fly. |
| ISP | Small client-specific interfaces. | Avoid forcing unused methods. |
| DIP | High-level code depends on abstractions. | DI helps but over-abstraction can slow simple features. |

Project example:

```text
In an API, controllers depend on services, services depend on repository/client abstractions, and concrete EF/API clients are injected. That keeps business flow testable and replaceable.
```

## Dependency Injection Lifetimes

| Lifetime | Meaning | Good use |
| --- | --- | --- |
| Transient | New each resolve | Lightweight stateless services |
| Scoped | One per request | DbContext, request context |
| Singleton | One for app lifetime | Configuration, stateless shared clients/cache wrappers |

Edge cases:

- DbContext is scoped because it tracks a unit of work and is not thread-safe.
- Captive dependency: singleton holding scoped service.
- Singleton must not keep user/tenant/request state.

## Patterns

- Repository: separates persistence from business logic; avoid hiding optimized EF queries too early.
- Factory: centralizes object creation.
- Strategy: swaps behavior without editing a conditional chain.
- Singleton: one instance; must be thread-safe and stateless or carefully synchronized.

Common questions:

- Explain SOLID with real examples.
- Interface vs abstract class?
- Why constructor injection?
- Why should DbContext not be singleton?
- What is LSP violation?
