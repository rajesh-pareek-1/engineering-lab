# C# Output Traps

## Core Mental Model

```text
Value type assignment copies data.
Reference type assignment copies address.
Mutation affects shared object.
Reassignment changes only local variable.
ref changes caller variable itself.
string is immutable.
boxing creates a new object copy.
```

## Reference Assignment

```csharp
var a1 = new A { X = 10 };
var a2 = a1;
a2.X = 50;
Console.WriteLine(a1.X);
```

Output:

```text
50
```

Rule:

```text
Both variables point to the same object.
```

## Value Type Assignment

```csharp
int x = 10;
int y = x;
y = 50;
Console.WriteLine(x);
```

Output:

```text
10
```

## Reassignment Trap

```csharp
void Change(A obj)
{
    obj = new A { X = 100 };
}
```

Rule:

```text
Reassigning parameter does not affect caller unless passed with ref.
```

## ref Keyword

```csharp
void Change(ref A obj)
{
    obj = new A { X = 100 };
}
```

Rule:

```text
ref lets the method replace the caller's variable.
```

## Boxing Trap

```csharp
int x = 10;
object obj = x;
x = 20;
Console.WriteLine(obj);
```

Output:

```text
10
```

Rule:

```text
Boxing creates a separate heap object copy.
```

## Shallow Copy

```csharp
var list1 = new List<Student> { new Student { Name = "A" } };
var list2 = new List<Student>(list1);
list2[0].Name = "B";
Console.WriteLine(list1[0].Name);
```

Output:

```text
B
```

Rule:

```text
New list does not mean new objects.
```

## Deep Copy

```csharp
var list2 = list1
    .Select(s => new Student { Name = s.Name })
    .ToList();
```

For nested objects, clone every level.

## Deep Swap

Wrong:

```csharp
var temp = l2[5];
l2[5] = l1[5];
l1[5] = temp;
```

This swaps references.

Better:

```csharp
var temp = l2[5].Clone();
l2[5] = l1[5].Clone();
l1[5] = temp;
```

## Polymorphism Output

```csharp
A a = new B();
a.GetA();
a.GetB();
a.GetCommon();
```

If `GetCommon` is virtual/override:

- `a.GetA()` works if defined on `A`.
- `a.GetB()` compile error if not defined on `A`.
- `a.GetCommon()` executes `B.GetCommon()`.

Rule:

```text
Method access is compile-time. Virtual method execution is runtime.
```

## No Default Constructor

```csharp
class A
{
    public A(int x) {}
}

new A(); // compile error
```

Rule:

```text
Default constructor is generated only when no constructor is defined.
```

## Delegates

```csharp
delegate int Calc(int x);

Calc c = x => x + 1;
c += x => x * 2;
Console.WriteLine(c(5));
```

Output:

```text
10
```

Rule:

```text
Multicast delegates execute all methods but return the last return value.
```

## Closure Trap

```csharp
var actions = new List<Action>();

for (int i = 0; i < 3; i++)
{
    actions.Add(() => Console.Write(i));
}

foreach (var action in actions) action();
```

Output:

```text
333
```

Fix:

```csharp
for (int i = 0; i < 3; i++)
{
    int temp = i;
    actions.Add(() => Console.Write(temp));
}
```

## Events

Rule:

```text
Event is a restricted delegate. Outside code can subscribe/unsubscribe but cannot invoke or overwrite it.
```

Memory leak:

```text
Publisher holds subscriber through event handler. Unsubscribe if subscriber lifetime is shorter.
```

## Async Traps

### async void

```csharp
async void Test() { throw new Exception("Boom"); }
try { Test(); } catch { Console.WriteLine("Caught"); }
```

Exception is not caught normally because `async void` cannot be awaited.

### .Result / .Wait()

```csharp
var result = GetDataAsync().Result;
```

Risk:

```text
Blocks thread and can deadlock.
```

### Sequential vs Parallel Await

Sequential:

```csharp
await AAsync();
await BAsync();
```

Parallel:

```csharp
var a = AAsync();
var b = BAsync();
await Task.WhenAll(a, b);
```

## Generics and Variance

Allowed:

```csharp
IEnumerable<string> strings = new List<string>();
IEnumerable<object> objects = strings;
```

Not allowed:

```csharp
List<string> strings = new();
List<object> objects = strings;
```

Rule:

```text
Only interfaces/delegates designed with out/in support variance.
```

