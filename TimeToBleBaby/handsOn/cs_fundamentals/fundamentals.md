# ⚔️ C# Fundamentals — Day 1 & Day 2 Mastery

---

# 🧠 CORE MENTAL MODEL (read first)

```
Value Type  → copy value
Reference   → copy address

Mutation    → affects original
Reassignment→ local only

ref         → modifies caller variable

object      → hides actual type
casting     → restores access

string      → immutable
boxing      → creates new object
```

---

# 🧨 DAY 1 — MEMORY MODEL

---

## 🔹 Q1 — Reference Assignment

```csharp
var a1 = new A { X = 10 };
var a2 = a1;
a2.X = 50;
Console.WriteLine(a1.X);
```

✅ Output: **50**

🔥 Rule:

> Assignment copies reference, not object.

---

## 🔹 Q2 — Value Type

```csharp
int x = 10;
int y = x;
y = 50;
Console.WriteLine(x);
```

✅ Output: **10**

🔥 Rule:

> Value types copy data.

---

## 🔹 Q3 — Equality Trap

```csharp
var a1 = new A { X = 5 };
var a2 = new A { X = 5 };
Console.WriteLine(a1 == a2);
```

✅ Output: **false**

🔥 Rule:

> Default equality = reference equality.

---

## 🔹 Q4 — Same Reference

```csharp
var a1 = new A { X = 5 };
var a2 = a1;
Console.WriteLine(a1 == a2);
```

✅ Output: **true**

🔥 Rule:

> Same reference → equal.

---

## 🔹 Q5 — Mutation via Method

```csharp
void Change(A obj) { obj.X = 100; }
```

✅ Output: **100**

🔥 Rule:

> Mutation affects original object.

---

## 🔹 Q6 — Reassignment Trap

```csharp
void Change(A obj) { obj = new A(); }
```

✅ Output: **no change**

🔥 Rule:

> Reassigning parameter does not affect caller.

---

## 🔹 Q7 — ref Keyword

```csharp
void Change(ref A obj) { obj = new A(); }
```

✅ Output: **changed**

🔥 Rule:

> `ref` modifies caller variable itself.

---

# 🧨 DAY 2 — STRINGS, OBJECT, BOXING

---

## 🔹 Q1 — String Immutability

```csharp
string s1 = "hello";
string s2 = s1;
s2 = "world";
Console.WriteLine(s1);
```

✅ Output: **hello**

🔥 Rule:

> Strings are immutable — reassignment creates new object.

---

## 🔹 Q2 — String Parameter

```csharp
void Change(string s) { s = "changed"; }
```

✅ Output: **original**

🔥 Rule:

> Reference passed by value (unless ref used).

---

## 🔹 Q3 — Boxing

```csharp
int x = 10;
object obj = x;
x = 20;
Console.WriteLine(obj);
```

✅ Output: **10**

🔥 Rule:

> Boxing creates a new object copy.

---

## 🔹 Q4 — Unboxing

```csharp
object obj = 10;
int x = (int)obj;
x = 50;
Console.WriteLine(obj);
```

✅ Output: **10**

🔥 Rule:

> Unboxing copies value out.

---

## 🔹 Q5 — Object Reference

```csharp
object obj = a;
a.X = 20;
Console.WriteLine(((A)obj).X);
```

✅ Output: **20**

🔥 Rule:

> Casting restores access to original type.

---

## 🔹 Q6 — Object Mutation

```csharp
((A)obj).X = 100;
```

✅ Output: **100**

🔥 Rule:

> Underlying reference remains same.

---

## 🔹 Q7 — Boxing + Reassignment

```csharp
object obj = 10;

void Change(object o)
{
    o = 50;
}
```

✅ Output: **10**

🔥 Rule:

> Reassignment changes local reference only.

---

# 🧠 CRITICAL CONCEPT — object vs actual type

```csharp
object o = new A();
```

| Type     | Meaning               |
| -------- | --------------------- |
| `object` | what compiler sees    |
| `A`      | actual runtime object |

---

### ❌ Not allowed

```csharp
o.x
```

### ✅ Allowed

```csharp
((A)o).x
```

🔥 Rule:

> Access depends on reference type, not actual type.

---

# 🧠 typeof vs GetType

```csharp
typeof(A)   // compile-time
o.GetType() // runtime
```

🔥 Rule:

> typeof → static, GetType → dynamic

---

# ⚔️ FINAL CHEAT RULES

- Assignment copies reference
- Mutation affects original
- Reassignment does not
- `ref` modifies caller
- Strings are immutable
- Boxing creates new object
- `object` hides structure
- Casting reveals structure
- Compiler trusts reference type only

---

# 🔥 ONE-LINE MASTERY

> **“Assignment moves references, mutation changes data, and casting reveals hidden structure.”**
