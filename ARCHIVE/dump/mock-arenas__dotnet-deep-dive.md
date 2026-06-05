# Mock Interview: .NET Deep Dive

## 1. C# vs .NET

Expected answer:

```text
C# is a language. .NET is the runtime/platform/framework ecosystem where C# code runs.
```

Weak answer:

```text
Both are same.
```

Strong answer:

```text
C# is the programming language. .NET includes the runtime, base class libraries, SDK, tooling, ASP.NET Core, EF Core ecosystem, and execution model through CLR/JIT. C# code compiles to IL, and .NET executes it.
```

## 2. CLR, IL, and JIT

Expected answer:

```text
C# compiles to IL, CLR loads it, JIT compiles to machine code at runtime.
```

Weak answer:

```text
CLR runs the program.
```

Strong answer:

```text
The C# compiler produces IL inside an assembly. The CLR provides services like GC, exception handling, security, and type safety. When code executes, JIT compiles IL into machine code for the current platform.
```

## 3. Value Type vs Reference Type

Expected answer:

```text
Value types copy values. Reference types copy references to objects.
```

Weak answer:

```text
Value is stack, reference is heap.
```

Strong answer:

```text
The important behavior is copying. With value types, assignment copies the data. With reference types, assignment copies the reference, so two variables can point to the same object. Mutation through one reference is visible through the other, but reassignment changes only that variable unless passed by ref.
```

## 4. Boxing and Unboxing

Expected answer:

```text
Boxing converts a value type into object; unboxing casts it back.
```

Weak answer:

```text
It changes type.
```

Strong answer:

```text
Boxing copies a value type into a heap object, which causes allocation and GC pressure. Unboxing extracts the value back with a runtime cast. Generics avoid boxing for value types, which is why List<int> is better than ArrayList.
```

## 5. Dispose vs Finalize

Expected answer:

```text
Dispose releases resources deterministically; Finalize runs later through GC.
```

Weak answer:

```text
Both clean memory.
```

Strong answer:

```text
GC handles managed memory, but resources like files, DB connections, and sockets need deterministic release. Dispose is called explicitly, often through using. Finalize is non-deterministic and should be for unmanaged cleanup safety, not normal resource management.
```

## 6. throw vs throw ex

Expected answer:

```text
throw preserves original stack trace; throw ex resets it.
```

Weak answer:

```text
Both throw exception.
```

Strong answer:

```text
Inside catch, using throw preserves the original failure stack trace. throw ex rethrows the same exception object but resets the stack trace from the rethrow line, hiding the real source and making production debugging harder.
```

## 7. Interface vs Abstract Class

Expected answer:

```text
Interface is contract; abstract class can share partial implementation/state.
```

Weak answer:

```text
Interface has only methods, abstract has methods with body.
```

Strong answer:

```text
I use interfaces for capabilities and dependencies, especially for DI and testing. I use abstract classes when related types share base behavior or state. A class can implement multiple interfaces but only inherit one base class, so interfaces keep design more flexible.
```

## 8. Liskov Substitution Principle

Expected answer:

```text
Child type should replace parent without breaking behavior.
```

Weak answer:

```text
It is about inheritance.
```

Strong answer:

```text
If code expects a parent type, any child type should work without surprises. Example: if Bird has Fly(), a Kiwi child that throws NotSupportedException violates LSP. Better design is Bird for common behavior and ICanFly only for birds that can fly.
```

