# C# Runtime Revision

## Must-Say Lines

- C# compiles to IL; CLR loads it; JIT compiles to machine code at runtime.
- Value type assignment copies data; reference type assignment copies the reference.
- Mutation through a shared reference is visible; reassignment changes only the local variable unless passed by `ref`.
- `throw` preserves stack trace; `throw ex` resets it.
- Dispose releases external resources deterministically; GC frees managed memory later.
- Boxing copies a value type into a heap object; generics avoid boxing.
- `await` frees the current flow while I/O waits; async is not automatic parallelism.

## Runtime

Interview answer:

```text
C# source compiles to IL inside an assembly. The CLR provides services like GC, exceptions, type safety, and JIT. When code runs, JIT compiles IL into machine code for the current platform.
```

Edge cases:

- .NET runtime is the platform; C# is only the language.
- Assemblies are usually `.dll` or `.exe`.
- GAC is mostly old .NET Framework context.

## Memory And Types

Value vs reference:

| Concept | Interview behavior |
| --- | --- |
| Value type | Assignment copies value. |
| Reference type | Assignment copies reference to object. |
| String | Reference type but immutable. |
| Struct | Value type; copying large structs can be expensive. |

Edge cases:

- Do not reduce answer to "stack vs heap"; copying behavior matters more.
- Strings do not mutate; concatenation creates new strings.
- Shallow copy duplicates collection shell, not nested objects.

## Parameters

| Keyword | Use |
| --- | --- |
| `ref` | Caller variable must be initialized; method can read and replace/modify. |
| `out` | Caller variable need not be initialized; method must assign before return. |

Common trap:

```text
Passing a reference type without ref lets the method mutate the object, but not replace the caller variable.
```

## Exceptions And Cleanup

- `finally`: code block after try/catch.
- `Dispose`: deterministic cleanup for files, sockets, DB connections.
- `Finalize`: non-deterministic GC safety hook.
- `using`: reliable way to call Dispose.

Edge cases:

- GC does not close external resources immediately.
- `throw ex` hurts production debugging.
- Swallowing exceptions in cleanup can hide data loss.

## GC, Boxing, Generics

GC generations:

- Gen 0: short-lived.
- Gen 1: survived once.
- Gen 2: long-lived.

Performance lines:

- Reduce allocations in hot paths.
- Avoid boxing in loops or high-volume code.
- Use generic collections like `List<int>` instead of legacy `ArrayList`.

Boxing edge cases:

- `object o = 10` boxes.
- Interface calls on structs can box depending on usage.
- Unboxing requires exact value type.

## Delegates, Events, Closures

- Delegate: type-safe method reference.
- `Action`: no return.
- `Func`: returns value.
- Event: restricted delegate; outside code can subscribe/unsubscribe but not invoke.

Traps:

- Multicast delegates return only the last return value.
- Publisher holds subscriber through event subscription; unsubscribe when subscriber lifetime is shorter.
- Closures capture variables, not just values.

## Async And Concurrency

Must-say:

```text
Async/await is best for I/O scalability. It does not automatically make CPU-bound work parallel.
```

Use:

- `await` async DB/API calls.
- `Task.WhenAll` for independent I/O started before awaiting.
- `Task.Run` only for CPU-bound work that should move to thread pool.
- `lock` for shared mutable state.
- `ConcurrentDictionary` for thread-safe dictionary operations, not whole-workflow atomicity.

Avoid:

- `.Result` / `.Wait()` in async flows.
- `async void` except UI/event handlers.
- Shared mutable state when state can be local or immutable.

Common questions:

- Thread vs Task vs async?
- Why can `.Result` deadlock?
- When is `Task.WhenAll` better than sequential awaits?
- What is thread pool starvation?
