# ⚔️ C# COLLECTIONS + COPY — MASTER CHEAT SHEET

---

# 🧠 CORE MENTAL MODEL

```text
List<T> copy:
  → new container
  → same object references (by default)

Mutation:
  → affects all references

Replacement:
  → affects only that container

Deep Copy:
  → new container + new objects (ALL levels)
```

---

# 🧨 1. SHALLOW COPY (ROOT TRAP)

```csharp
class A { public int X; }

var list1 = new List<A> { new A { X = 1 } };
var list2 = new List<A>(list1);

list2[0].X = 100;

Console.WriteLine(list1[0].X);
```

✅ Output: **100**

💥 Why:

- New list created
- Same `A` object shared

🔥 Rule:

> **“List copy copies container, not objects.”**

---

# 🧨 2. SAME LIST REFERENCE

```csharp
var list1 = new List<int> { 1, 2, 3 };
var list2 = list1;

list2[0] = 100;

Console.WriteLine(list1[0]);
```

✅ Output: **100**

🔥 Rule:

> **“Assigning list = list shares same container.”**

---

# 🧨 3. VALUE TYPE SAFE CASE

```csharp
var list1 = new List<int> { 1, 2, 3 };
var list2 = new List<int>(list1);

list2[0] = 100;

Console.WriteLine(list1[0]);
```

✅ Output: **1**

💥 Why:

- `int` is value type → copied

🔥 Rule:

> **“Value types behave like deep copy inside collections.”**

---

# 🧨 4. REPLACE vs MUTATE

```csharp
var list2 = new List<A>(list1);

list2[0] = new A { X = 999 };

Console.WriteLine(list1[0].X);
```

✅ Output: **1**

💥 Why:

- Only reference replaced in list2

🔥 Rule:

> **“Replacing breaks link, mutation doesn’t.”**

---

# 🧨 5. FAKE DEEP COPY (foreach trap)

```csharp
var list2 = new List<A>();

foreach (var item in list1)
{
    list2.Add(item);
}

list2[0].X = 50;

Console.WriteLine(list1[0].X);
```

✅ Output: **50**

🔥 Rule:

> **“Copying via Add still copies references.”**

---

# 🧨 6. REAL BUG — CLEAR()

```csharp
var original = new List<A> { new A(), new A() };
var copy = original;

copy.Clear();

Console.WriteLine(original.Count);
```

✅ Output: **0**

🔥 Rule:

> **“Same list reference = shared destruction.”**

---

# 🧨 7. LINQ SHALLOW COPY TRAP

```csharp
var list2 = list1.Select(x => x).ToList();

list2[0].X = 999;

Console.WriteLine(list1[0].X);
```

✅ Output: **999**

🔥 Rule:

> **“Select(x => x) = identity = no copy.”**

---

# 🧨 8. NESTED OBJECT TRAP

```csharp
class Order
{
    public List<Item> Items = new();
}

class Item
{
    public int Price;
}

var o2 = new Order
{
    Items = o1.Items
};

o2.Items[0].Price = 999;

Console.WriteLine(o1.Items[0].Price);
```

✅ Output: **999**

🔥 Rule:

> **“Nested reference = shared mutation.”**

---

# 🧨 9. PARTIAL DEEP COPY (DANGEROUS)

```csharp
var o2 = new Order
{
    Items = o1.Items.Select(x => x).ToList()
};
```

❌ Still shallow

🔥 Rule:

> **“New list ≠ new objects.”**

---

# 🧨 10. TRUE DEEP COPY (SINGLE LEVEL)

```csharp
var o2 = new Order
{
    Items = o1.Items
        .Select(x => new Item { Price = x.Price })
        .ToList()
};
```

✅ Safe

🔥 Rule:

> **“New object per element = deep copy.”**

---

# 🧨 11. DOUBLE NESTED TRAP

```csharp
var c2 = new Customer
{
    Order = new Order
    {
        Items = o1.Items
    }
};
```

✅ Output reflects changes

🔥 Rule:

> **“Top-level copy is useless if inner references are reused.”**

---

# 🧨 12. MUTATION CHAIN

```csharp
var list2 = new List<Order>(list1);

list2[0].Items[0].Price = 888;

Console.WriteLine(list1[0].Items[0].Price);
```

✅ Output: **888**

🔥 Rule:

> **“Reference chains propagate mutations.”**

---

# 🧨 13. REPLACE NESTED SAFE CASE

```csharp
list2[0] = new Order
{
    Items = new List<Item> { new Item { Price = 111 } }
};
```

✅ list1 unaffected

🔥 Rule:

> **“Replacing outer object breaks entire chain.”**

---

# 🧨 14. LINQ DEEP COPY TRAP

```csharp
var list2 = list1
    .Select(o => new Order
    {
        Items = o.Items
    })
    .ToList();
```

❌ Not deep

🔥 Rule:

> **“New parent + old children = bug.”**

---

# 🧨 15. TRUE FULL DEEP COPY (FINAL FORM)

```csharp
var list2 = list1
    .Select(o => new Order
    {
        Items = o.Items
            .Select(i => new Item { Price = i.Price })
            .ToList()
    })
    .ToList();
```

✅ Fully safe

---

# 🧠 FINAL VISUAL (LOCK THIS)

```text
Level 1: List
Level 2: Object (Order)
Level 3: Nested List (Items)
Level 4: Object (Item)

Deep copy must recreate ALL levels
```

---

# 🔥 ARENA-LEVEL ONE-LINERS

- **“New list ≠ new objects.”**
- **“Mutation travels through references.”**
- **“Replacing breaks links, mutation doesn’t.”**
- **“If any inner reference is reused → it’s not deep copy.”**
- **“Deep copy must clone the entire object graph.”**

---

# ⚔️ FINAL TEST (MENTAL)

```csharp
var list2 = list1.ToList();
list2[0].Items.Clear();
```

👉 If original is affected → why?

(Answer: shared nested reference)

---

# 🚀 YOU NOW MASTER

✔ Shallow vs Deep
✔ Nested copy
✔ LINQ traps
✔ Mutation chains
✔ Real-world bugs
