# 🧨 Final Round Day 5 — Async / Await Mastery Cheat Sheet

---

## **Q1 — async void and exception handling**

```csharp
async void Test() { throw new Exception("Boom"); }
try { Test(); } catch { Console.Write("Caught"); }
```

- **Output:** ❌ Nothing
- **Why:** `async void` cannot be awaited → exception happens outside try/catch.
- **Rule:** **Never use async void** except for top-level event handlers.

---

## **Q2 — Deadlock Trap**

```csharp
async Task<string> GetData() { await Task.Delay(1000); return "data"; }
var result = GetData().Result; // deadlock danger
```

- **Output:** Program blocks for 1 sec, risks deadlock.
- **Fix:** `var result = await GetData();` → releases caller thread.
- **Rule:** **Never block async method with `.Result` or `.Wait()`** .

---

## **Q3 — Task vs Thread**

```csharp
Task.Run(() => Console.Write("Task "));
new Thread(() => Console.Write("Thread ")).Start();
```

- **Conceptual Difference:**
  - **Thread:** OS-level thread
  - **Task:** Lightweight wrapper for async execution, can use thread pool
- **Rule:** Task = syntactic sugar + scheduling + continuations

---

## **Q4 — CPU vs IO Bound**

```csharp
await Task.Run(() => HeavyCalculation()); // CPU bound
await Task.Delay(1000);                    // IO bound
```

- **Rule:** CPU-bound → Task.Run
- **Rule:** IO-bound → await non-blocking tasks

---

## **Q5 — Async Chain Example**

```csharp
async Task C() { await Task.Delay(1000); Console.Write("C "); }
async Task B() { await C(); Console.Write("B "); }
async Task A() { await B(); Console.Write("A "); }
await A();
```

- **Output:** `C B A` (~1 second)
- **Rule:** Async methods chain, execution continues **after awaited tasks complete** .

---

## **Q6 — Fire-and-Forget Trap**

```csharp
async Task Test() { throw new Exception("Error"); }
Test(); // not awaited
Console.Write("Done");
```

- **Output:** `Done`
- **Why:** Exception occurs asynchronously, not awaited → program may finish before exception surfaces
- **Rule:** **Always await tasks unless intentionally fire-and-forget safely.**

---

## **Q7 — ConfigureAwait(false)**

```csharp
await Task.Delay(1000).ConfigureAwait(false);
```

- **Effect:** Execution resumes on **any thread** , not necessarily original context
- **Use:** UI / server applications to **avoid deadlocks and improve throughput**
- **Rule:** Use in libraries / background code to avoid capturing synchronization context.

---

## **Q8 — Multiple awaits**

```csharp
await Task.Delay(1000);
await Task.Delay(1000); // sequential
```

vs

```csharp
var t1 = Task.Delay(1000);
var t2 = Task.Delay(1000);
await Task.WhenAll(t1, t2); // parallel
```

- **Rule:** Sequential → waits for first, then second (~2 sec)
- **Rule:** Parallel → tasks run concurrently (~1 sec)

---

## **Q9 — Task.FromResult vs async return**

```csharp
Task<int> Get1() { return Task.FromResult(5); } // immediately completed Task
async Task<int> Get2() { return 5; }           // async, compiler wraps in Task
```

- **Output:** Both return Task with value 5
- **Difference:** `FromResult` → already done, no async overhead
- **Rule:** Use `FromResult` if no real async operation

---

## ⚡ Key Traps & Edge Cases

1. `async void` → exceptions escape
2. `.Result` / `.Wait()` → deadlocks
3. `await` pauses method, **not thread**
4. Exceptions only propagate **when awaited**
5. Sequential vs parallel await → timing matters
6. `ConfigureAwait(false)` → prevents context capture / deadlock

---

## ✅ Arena-Level One-Liners

- **“Async runs immediately until first await, then continues later.”**
- **“Task.FromResult = completed task, no delay.”**
- **“.Result and .Wait() block thread → deadlocks.”**
- **“async void = no await, exceptions escape.”**
- **“Parallel tasks → start first, await later.”**
