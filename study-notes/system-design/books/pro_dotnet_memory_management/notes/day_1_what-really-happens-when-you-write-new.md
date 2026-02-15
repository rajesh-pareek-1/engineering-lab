
---

# Day 1 — What Really Happens When You Write `new`

If you don’t understand allocation, you don’t understand performance.

---

## The Myth

Most developers assume:

* `new` calls the OS
* It searches for memory
* It behaves like `malloc`
* It is expensive

All incorrect.

---

## The Reality: Bump Pointer Allocation

When the process starts, the CLR:

* Reserves large contiguous memory segments from the OS.
* Manages allocation inside those segments.

Inside Gen 0, allocation looks like this:

```
| Obj1 | Obj2 | Obj3 |        Free Space         |
                         ^
                  Allocation Pointer
```

When you execute:

```csharp
var obj = new MyClass();
```

The CLR:

1. Checks if enough space exists.
2. Writes object header.
3. Zeroes memory.
4. Advances the allocation pointer.
5. Returns the reference.

No searching.
No fragmentation handling.
No free lists.

Just pointer increment.

Allocation is O(1).

---

## Why `new` Is Cheap

* Linear contiguous allocation
* Cache-friendly memory layout
* No free-space scanning
* Hardware-optimized memory clearing

Allocation is cheap.

Collection is expensive.

---

## Why Memory Is Zeroed

Memory is zeroed because:

* C# guarantees default values (`int = 0`, `ref = null`)
* Prevents data leakage from previously freed objects
* Avoids false references that could break GC correctness

Zeroing is required for safety and determinism.

---

## Why Compaction Exists

After a GC cycle:

```
| A | _ | C | _ | E |
```

Dead objects create holes.

Without compaction:

* Allocation would require scanning for gaps
* Fragmentation would increase
* Allocation would become slower over time

With compaction:

```
| A | C | E |     Free Space     |
```

Compaction restores linear allocation.

Compaction protects allocation speed.

---

## The Large Object Heap (LOH)

Objects larger than ~85,000 bytes go to the LOH.

Why?

Because copying large objects during compaction is expensive.

LOH characteristics:

* Collected during Gen 2 GC
* Not compacted by default
* Can fragment over time

---

## What Is Churn

Churn = High allocation rate + short lifetime.

Example:

```csharp
new byte[100_000]; // 2,000 times per second
```

What happens over time:

1. Allocated in LOH
2. Becomes unreachable quickly
3. Leaves holes
4. LOH does not compact
5. Heap grows
6. Gen 2 GC frequency increases
7. Latency becomes unstable

This is not a memory leak.

It is fragmentation under churn.

---

## Why Pooling Exists

Instead of repeatedly allocating:

```
Allocate → Die → Allocate → Die
```

Use:

```csharp
var buffer = ArrayPool<byte>.Shared.Rent(100_000);
// use buffer
ArrayPool<byte>.Shared.Return(buffer);
```

Effects:

* Memory reused
* No LOH churn
* Fewer Gen 2 collections
* Stable memory footprint

Pooling replaces GC pressure with ownership discipline.

---

## Pooling Risk

If you return a buffer before async work completes:

* Another request may rent the same buffer
* Data corruption can occur
* No exception will warn you

Pooling increases performance but reduces safety guarantees.

---

## Allocation Flow Overview

```
Application Starts
        ↓
CLR Reserves Large Memory Segment
        ↓
Gen 0 Allocation (Bump Pointer)
        ↓
Object Survives?
    ↓           ↓
   No          Yes
    ↓           ↓
Collected    Promoted
                  ↓
              Gen 2 / LOH
                  ↓
Compacted?  (SOH: Yes / LOH: No)
```

---

## Core Mental Models Built Today

* `new` is pointer bump allocation.
* Compaction preserves O(1) allocation.
* LOH trades compaction for reduced copy cost.
* Fragmentation is not a leak.
* High churn breaks generational assumptions.
* Pooling stabilizes large-object allocation patterns.

---
