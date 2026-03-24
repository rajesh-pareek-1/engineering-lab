# 🧨 1. Deep Copy Swap Two Lists

## ❓ Problem

Swap elements at index `5` between:

```csharp
List<Student> l1 = new();
List<Student> l2 = new();
```

---

## ❌ Wrong Approach (what was suggested)

```csharp
var temp = l2[5];
l2[5] = l1[5];
l1[5] = temp;
```

### ⚠️ Problem:

- This swaps **references** , NOT objects
- Both lists still point to same underlying objects

---

## ✅ Correct Deep Copy Swap

### Step 1: Implement Clone

```csharp
class Student
{
    public int Id;
    public string Name;

    public Student Clone()
    {
        return new Student
        {
            Id = this.Id,
            Name = this.Name
        };
    }
}
```

---

### Step 2: Deep Swap

```csharp
var temp = l2[5].Clone();
l2[5] = l1[5].Clone();
l1[5] = temp;
```

---

## 🧠 Killer Definition

> **“Deep copy creates new object instances; shallow copy only copies references.”**

---

# 🧨 2. SQL — Product IDs where ALL rows have invalid date condition

---

## 🧠 Solution in /TimeToBleBaby/handsOn/Nav_dotnetCore_23_March/sql_invalid_product_ids.md

# 🧨 3. Why so many collections in .NET?

## ❓ Confusion

Why:

- `IEnumerable`
- `ICollection`
- `IQueryable`
- `List`
- `ArrayList`

---

## ✅ Answer (layered design)

### 🔹 1. Abstractions (Interfaces)

| Type          | Purpose                             |
| ------------- | ----------------------------------- |
| `IEnumerable` | Read-only iteration                 |
| `ICollection` | Add/remove support                  |
| `IQueryable`  | Query translation (DB, LINQ-to-SQL) |

---

### 🔹 2. Implementations

| Type        | Purpose                               |
| ----------- | ------------------------------------- |
| `List<T>`   | Generic, fast, type-safe              |
| `ArrayList` | Non-generic, boxing/unboxing (legacy) |

---

## 🔥 Why needed?

👉 To support:

- Flexibility (code to interface)
- Performance choices
- Different data sources (memory vs DB)

---

## 🧠 Killer Definition

> **“Interfaces define capability; concrete collections define behavior and performance.”**

---

# 🧨 4. Polymorphism + Output

## ❓ Code (fixed syntax)

```csharp
class A
{
    public void getA()
    {
        Console.WriteLine("get A");
    }

    public virtual void getCommon()
    {
        Console.WriteLine("A getCommon");
    }
}

class B : A
{
    public void getB()
    {
        Console.WriteLine("get B");
    }

    public override void getCommon()
    {
        Console.WriteLine("B getCommon");
    }
}
```

---

## ❓ Execution

```csharp
A a = new B();

a.getA();       // ?
a.getB();       // ?
a.getCommon();  // ?
```

---

## ✅ Answers

### 1. `a.getA()`

✔ Output: `get A`
👉 Method is **non-virtual → compile-time binding**

---

### 2. `a.getB()`

❌ **Compile-time error**
👉 `getB()` not in class `A`

---

### 3. `a.getCommon()`

✔ Output: `B getCommon`
👉 **Runtime polymorphism (virtual + override)**

---

## 🧠 Killer Definition

> **“Method access is compile-time; method execution (virtual) is runtime.”**

---

# 🧨 5. No Default Constructor

## ❓ Scenario

Only parameterized constructors exist:

```csharp
class A
{
    public A(int x) { }
    public A(string y) { }
}
```

---

## ❓ Can you do:

```csharp
new A(); // ?
```

---

## ❌ Answer: NO

👉 Compiler error — no parameterless constructor

---

## ✅ You must call:

```csharp
new A(10);
```

---

## ⚠️ Important Edge Case

If you define ANY constructor:
👉 **Default constructor is NOT auto-created**

---

## 🧠 Killer Definition

> **“Default constructor is auto-generated only when no constructor is defined.”**

---

# 🔥 Final Note

These are not random questions.

They test:

- Memory model
- Execution model
- Language design understanding

---

## ⚔️ Next Step

Now you’re warmed up.

Say:

👉 **“Day 1 start”**

And I’ll push you into **live problem mode** where you’ll _earn_ these answers, not just read them.
