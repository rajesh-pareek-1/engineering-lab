# 4. C# Fundamentals

## Master mind map

```text
C#
├── Type system
│   ├── value vs reference
│   ├── nullable
│   └── boxing / casting
├── Object model
│   ├── class / struct / record
│   ├── interface / abstract
│   └── access modifiers
├── Collections and LINQ
├── Delegates, events, lambdas
├── Exceptions and disposal
└── async / await
```

## Value type vs reference type

Mnemonic: **V-C, R-L** - value copies its **Content**; reference copies its **Location**.

> Value types such as `int`, `bool`, enums, and structs normally contain their value directly. Assignment copies the value. Reference-type variables such as classes, arrays, and strings hold a reference to an object; assignment copies that reference. A value type can still be boxed onto the managed heap, and object allocation is an implementation/runtime concern, so I avoid reducing the answer to “struct is stack and class is heap.”

Cross-question: **Why is string a reference type but immutable?**

> Multiple variables can reference the same string safely because its contents cannot be changed. An operation such as `Replace` returns a new string.

## `class` vs `struct` vs `record`

- **Class:** reference semantics; good for entities and objects with identity/lifecycle.
- **Struct:** value semantics; best for small, immutable values.
- **Record:** concise data-centric type with value-based equality by default; record classes are reference types.

> I would use a class for an EF entity such as `Shipment`, a small immutable struct for a value such as a coordinate if justified, and a record for an immutable request/result model where value equality is useful.

## `var`, `dynamic`, and `object`

- `var`: compile-time inferred, still strongly typed.
- `object`: base type; members often need casting.
- `dynamic`: binding deferred until runtime; errors can become runtime errors.

> I use `var` when the type is clear from the right side. I avoid `dynamic` unless interacting with a genuinely dynamic API.

## Boxing and unboxing

> Boxing converts a value type to `object` or an implemented interface, generally requiring an object allocation and copy. Unboxing extracts it back to the exact value type. Generics such as `List<int>` avoid the boxing that older non-generic collections could cause.

## Nullable types and null safety

> `int?` is `Nullable<int>`. Nullable reference types are compiler annotations and analysis that warn about possible nulls; they do not create a different runtime reference type. I enable them and validate data at boundaries.

Operators:

- `?.` null-conditional
- `??` fallback
- `??=` assign if null
- `!` suppress warning; use only when an invariant truly guarantees non-null

## Collections: **L-D-H-S-Q**

- **List:** ordered, indexed, duplicates; general-purpose collection.
- **Dictionary:** key → value; average O(1) lookup.
- **HashSet:** uniqueness and fast membership.
- **Stack:** last-in-first-out.
- **Queue:** first-in-first-out.

Cross-question: **`IEnumerable<T>` vs `IQueryable<T>`?**

> `IEnumerable<T>` represents in-process iteration. LINQ operators run as .NET code. `IQueryable<T>` carries an expression tree that a provider such as EF Core translates, usually into SQL. I keep filtering and projection on `IQueryable` until the database work is defined, then materialize once with `ToListAsync`.

## Deferred execution

> Many LINQ queries execute only when enumerated. This allows composition, but repeated enumeration can repeat work or database queries. Materialization with `ToList`, `First`, or similar triggers execution.

## Delegate, lambda, and event

> A delegate is a type-safe reference to one or more methods. A lambda is concise syntax that can become a delegate or expression tree. An event uses delegates but restricts invocation to the declaring publisher, supporting publisher-subscriber communication.

Examples in backend code:

- predicate passed to LINQ;
- callback or strategy;
- domain/in-process event;
- EF Core expression translated to SQL.

## Exceptions: **C-L-R**

- **Catch** only where you can handle, translate, or add useful context.
- **Log** once at the appropriate boundary with structured context.
- **Rethrow** with `throw;`, not `throw ex;`, to preserve stack trace.

> Exceptions represent exceptional failures, not normal branching. In an API I use centralized exception middleware to convert known exceptions into consistent responses and unexpected failures into a generic 500 without exposing internals.

Cross-question: **`finally`?**

> It runs whether the `try` succeeds or throws, and is useful for cleanup. For disposable resources, `using` is clearer.

## `IDisposable` and `using`

> `IDisposable` provides deterministic cleanup for resources such as streams and database connections. `using` compiles to `try/finally`. `await using` supports `IAsyncDisposable` for asynchronous cleanup.

## Garbage collection

Mnemonic: **0-1-2 + LOH**.

> .NET GC manages memory for managed objects. New short-lived objects begin in generation 0; survivors can move to generations 1 and 2. Large objects normally use the Large Object Heap. GC handles managed memory, but scarce unmanaged resources still need disposal.

## Equality

- `ReferenceEquals`: same object reference.
- `Equals`: semantic equality, overridable.
- `==`: operator; behavior depends on type/overload.
- Records provide value-based equality by default.

> If overriding equality in a class, maintain consistency with `GetHashCode`, especially when used in hash collections.

## Generics

> Generics provide reusable, type-safe code without many casts and can avoid boxing for value types. Constraints communicate required capabilities, such as `where T : class` or an interface.

## Rapid fire

**`const` vs `readonly`?** `const` is compile-time and implicitly static; `readonly` can be assigned at declaration or in a constructor.

**`ref` vs `out` vs `in`?** `ref` passes an initialized variable by reference; `out` must be assigned by the callee; `in` passes a read-only reference.

**Extension method?** Static method called with instance syntax; useful for focused reusable operations, but not a place to hide unclear dependencies.

**Partial class?** One class split across files; common with generated code.

**Sealed class?** Cannot be inherited; communicates final behavior and can enable runtime optimizations.

**StringBuilder?** Useful for many string mutations because repeated string concatenation can allocate many immutable strings.

