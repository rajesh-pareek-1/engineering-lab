# 🧠 DAY 6 — GENERICS, COLLECTIONS, LINQ, DELEGATES, EVENTS

---

# ⚔️ CORE MENTAL MODEL

```text

Generics   → type safety + reuse

Collections→ data structures + behavior contracts

LINQ       → query over data (deferred execution)

Delegate   → method pointer

Event      → safe delegate

Copy       → reference vs value vs deep

```

---

# 🧨 1. GENERICS — CONSTRAINTS

### ✅ Valid combos

```csharp

class Repo<T> where T : class, new() { }

class Repo<T> where T : struct { }

class Repo<T> where T : BaseClass { }

class Repo<T> where T : IInterface { }

```

---

### ❌ Invalid

```csharp

where T : int        // ❌ cannot use concrete type

where T : struct, new() // ❌ redundant

```

---

### 🔥 Rule

> **“Generics don’t know constructors → use constraints.”**

---

### 🧨 Param constructor trap

```csharp

class A { public A(int x) {} }


class Repo<T> where T : new()

{

    public T Create() => new T(); // ❌ fails

}

```

---

### ✅ Fix (Factory)

```csharp

new Repo<A>(() => new A(10));

```

---

### 🔥 Rule

> **“new() only works with parameterless constructors.”**

---

# 🧨 2. COVARIANCE / CONTRAVARIANCE

```csharp

IEnumerable<string> s = new List<string>();

IEnumerable<object> o = s; // ✅

```

---

### ❌ Not allowed

```csharp

List<string> s = new List<string>();

List<object> o = s; // ❌

```

---

### 🔥 Rule

> **“Only interfaces/delegates with out/in support variance.”**

---

# 🧨 3. COLLECTIONS — INTERFACE HIERARCHY

```text

IEnumerable → iterate only

   ↓

ICollection → add/remove/count

   ↓

IList       → index access

```

---

### 🧠 Meaning

| Interface | Use |

| ----------- | ------------------- |

| IEnumerable | read-only iteration |

| ICollection | modify collection |

| IList | index-based access |

---

### 🔥 Rule

> **“Use lowest interface needed.”**

---

# 🧨 4. COLLECTION TRAPS

### ❌ Modify during iteration

```csharp

foreach(var x in list)

    list.Add(4); // 💥 crash

```

---

### ✅ Fix

```csharp

foreach(var x in list.ToList())

```

---

### 🔥 Rule

> **“Enumerator detects modification → throws exception.”**

---

# 🧨 5. ARRAYLIST vs LIST `<T>`

```csharp

ArrayList a = new ArrayList();

a.Add(1);

a.Add("text"); // ✅ unsafe


List<int> l = new List<int>();

l.Add("text"); // ❌ compile error

```

---

### 🔥 Rule

> **“ArrayList = unsafe, List `<T>` = type-safe.”**

---

# 🧨 6. DELEGATES — MULTICAST

```csharp

delegate int Calc(int x);


Calc c = A;

c += B;


c(5); // returns last method

```

---

### 🔥 Rule

> **“Multicast executes all, returns last.”**

---

# 🧨 7. EVENTS — SAFE DELEGATE

```csharp

public event Action OnChange;

```

---

### ❌ Not allowed outside

```csharp

p.OnChange();      // ❌

p.OnChange = null; // ❌

```

---

### ✅ Allowed

```csharp

p.OnChange += handler;

p.OnChange -= handler;

```

---

### 🔥 Rule

> **“Event = restricted delegate (safe access).”**

---

# 🧨 8. MEMORY LEAK TRAP

```csharp

publisher.OnChange += subscriber.Handle;

```

---

### 💥 Problem

- publisher holds reference to subscriber
- subscriber never gets GC’d

---

### 🔥 Rule

> **“Event subscription = strong reference.”**

---

# 🧨 9. LINQ — SHALLOW COPY TRAP

```csharp

var copy = list.Select(o => new Order {

    Id = o.Id,

    Items = o.Items // ❌ same reference

});

```

---

### 🔥 Rule

> **“LINQ Select does NOT deep copy automatically.”**

---

# 🧨 10. DEEP COPY (CORRECT)

```csharp

var deep = list.Select(o => new Order {

    Id = o.Id,

    Items = o.Items.Select(i => new Item {

        Price = i.Price

    }).ToList()

});

```

---

### 🔥 Rule

> **“Deep copy = new object at every level.”**

---

# 🧨 11. VALUE vs REFERENCE (LISTS)

### 🧠 Value types

```csharp

List<int> a = new() {1};

List<int> b = new() {2};


swap → copies values ✅ safe

```

---

### 🧠 Reference types

```csharp

List<Order> → swaps references only

```

---

### 🔥 Rule

> **“Value types copy value, reference types copy pointer.”**

---

# 🧨 12. SWAP LOGIC

```csharp

var temp = list1[i];

list1[i] = list2[i];

list2[i] = temp;

```

---

### 🔥 Rule

> **“Swap works for both — but deep copy needed for nested objects.”**

---

# ⚔️ FINAL MIND MAP

```text

Generics → constraints → safety

Collections → behavior → interfaces

LINQ → query → shallow by default

Delegate → execution chain

Event → safe delegate

Copy → value vs reference vs deep

```

---

# 🔥 ARENA-LEVEL ONE LINERS

- **“Generics need constraints to enforce behavior.”**
- **“new() only supports parameterless constructors.”**
- **“IEnumerable is covariant, List is not.”**
- **“LINQ does shallow copy unless explicitly deep.”**
- **“Events prevent unsafe delegate invocation.”**
- **“Value types copy data, reference types copy address.”**
- **“Modifying collection during iteration = crash.”**

---

# 🚀 YOU NOW MASTER DAY 6

You now have:

✔ Generics deep clarity

✔ Collection hierarchy + traps

✔ Delegate & event edge cases

✔ LINQ shallow/deep behavior

✔ Value vs reference mastery
