# ⚔️ C# DAY 4 — DELEGATES, FUNC, ACTION, EVENTS

---

# 🧠 CORE MENTAL MODEL

```text
Delegate  → type-safe method pointer
Multicast → chain of methods
Return    → only last value survives

Action    → delegate (void return)
Func      → delegate (returns value)
Predicate → Func<T, bool>

Event     → restricted delegate (safe wrapper)
Closure   → captures variable (not value)
```

---

# 🧨 1. BASIC DELEGATE

```csharp
delegate int MyDel(int x);

int Square(int x) => x * x;

MyDel d = Square;

Console.WriteLine(d(5));
```

✅ Output: **25**

🔥 Rule:

> **“Delegate stores method reference, executes on call.”**

---

# 🧨 2. MULTICAST DELEGATE

```csharp
delegate void MyDel();

void A() => Console.Write("A ");
void B() => Console.Write("B ");

MyDel d = A;
d += B;

d();
```

✅ Output:

```text
A B
```

🔥 Rule:

> **“Multicast executes methods in order of subscription.”**

---

# 🧨 3. RETURN VALUE TRAP

```csharp
delegate int MyDel();

int A() { Console.Write("A "); return 1; }
int B() { Console.Write("B "); return 2; }

MyDel d = A;
d += B;

Console.WriteLine(d());
```

✅ Output:

```text
A B 2
```

🔥 Rule:

> **“Multicast delegates return only the last method’s value.”**

---

# 🧨 4. REMOVE DELEGATE

```csharp
d -= A;
d();
```

✅ Output:

```text
B
```

🔥 Rule:

> **“-= removes specific method from invocation list.”**

---

# 🧨 5. ACTION

```csharp
Action<int> act = x => Console.WriteLine(x * 2);

act(5);
```

✅ Output: **10**

🔥 Rule:

> **“Action = delegate with no return type.”**

---

# 🧨 6. FUNC

```csharp
Func<int, int, int> add = (a, b) => a + b;

Console.WriteLine(add(2, 3));
```

✅ Output: **5**

🔥 Rule:

> **“Func’s last generic parameter is return type.”**

---

# 🧨 7. PREDICATE

```csharp
Predicate<int> p = x => x > 5;

Console.WriteLine(p(10));
```

✅ Output: **True**

🔥 Rule:

> **“Predicate = Func<T, bool> (specialized delegate).”**

---

# 🧨 8. CLOSURE TRAP ❌

```csharp
var actions = new List<Action>();

for (int i = 0; i < 3; i++)
{
    actions.Add(() => Console.Write(i));
}

foreach (var a in actions)
{
    a();
}
```

❌ Output:

```text
3 3 3
```

---

🔥 Why:

- Lambda captures **variable `i`**
- Loop ends → `i = 3`

---

🔥 Rule:

> **“Closures capture variables, not values.”**

---

# 🧨 9. CLOSURE FIX ✅

```csharp
for (int i = 0; i < 3; i++)
{
    int temp = i;
    actions.Add(() => Console.Write(temp));
}
```

✅ Output:

```text
0 1 2
```

---

🔥 Rule:

> **“Use temp variable to freeze value in closure.”**

---

# 🧨 10. INVOCATION LIST

```csharp
foreach (var del in d.GetInvocationList())
{
    del.DynamicInvoke();
}
```

✅ Output:

```text
A B
```

---

🔥 Rule:

> **“GetInvocationList exposes individual delegate methods.”**

---

# 🧨 11. FUNC MULTICAST TRAP

```csharp
Func<int, int> f = x => x + 1;
f += x => x * 2;

Console.WriteLine(f(5));
```

✅ Output: **10**

---

🔥 Why:

- Both run → 6 and 10
- Only last returned

---

🔥 Rule:

> **“Multicast Func executes all but returns last.”**

---

# 🧨 12. EVENT (SAFE DELEGATE)

```csharp
class Publisher
{
    public event Action OnNotify;

    public void Raise()
    {
        OnNotify?.Invoke();
    }
}
```

---

🔥 Rule:

> **“Event restricts delegate access.”**

---

# 🧨 13. EVENT RESTRICTION

```csharp
p.OnNotify = null; // ❌ not allowed
p.OnNotify();     // ❌ not allowed
```

---

🔥 Allowed:

```csharp
p.OnNotify += Handler;
p.OnNotify -= Handler;
```

---

🔥 Rule:

> **“Only declaring class can invoke event.”**

---

# 🧨 14. DELEGATE DANGER

```csharp
public Action OnNotify; // ❌ not event
```

👉 External code can:

```csharp
p.OnNotify = null; // wipes all handlers
```

---

🔥 Rule:

> **“Public delegate = unsafe API.”**

---

# 🧨 15. NULL DELEGATE TRAP

```csharp
Action a = null;

a(); // 💥 crash
```

---

✅ Safe:

```csharp
a?.Invoke();
```

---

🔥 Rule:

> **“Always null-check before invoking delegate.”**

---

# 🧨 16. MEMORY LEAK (IMPORTANT)

```csharp
pub.OnNotify += sub.Handle;
```

---

💥 Problem:

- `pub` holds reference to `sub`
- GC cannot collect `sub`

---

🔥 Rule:

> **“Event subscription creates strong reference.”**

---

# 🧠 FINAL VISUAL MODEL

```text
Delegate:
  A → B → C  (chain)

Invoke:
  executes all
  returns last

Event:
  protected delegate

Closure:
  captures variable (shared)
```

---

# 🔥 ARENA-LEVEL ONE-LINERS

- **“Delegate stores reference, not execution.”**
- **“Multicast executes all, returns last.”**
- **“Closures capture variables, not values.”**
- **“Event is a safe delegate wrapper.”**
- **“Event subscription can prevent GC.”**
- **“GetInvocationList reveals delegate chain.”**
