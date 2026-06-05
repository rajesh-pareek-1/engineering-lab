# CODING_DRILLS

Fast coding/output practice. Predict first, run only if needed.

## C# Coding Drills

## OOP Mini Examples

Interface:

```csharp
public interface IShape
{
    int Area();
}

public sealed class Circle : IShape
{
    public int Radius { get; init; }
    public int Area() => (int)(3.14m * Radius * Radius);
}
```

Abstract class:

```csharp
public abstract class Vehicle
{
    public abstract void Start();
}

public sealed class Car : Vehicle
{
    public override void Start() => Console.WriteLine("Car started");
}
```

## Arrays

### Second Largest

```csharp
int SecondLargest(int[] arr)
{
    return arr.Distinct()
        .OrderByDescending(x => x)
        .Skip(1)
        .First();
}
```

### Find Duplicates

```csharp
var duplicates = numbers
    .GroupBy(x => x)
    .Where(g => g.Count() > 1)
    .Select(g => g.Key)
    .ToList();
```

### Frequency Count

```csharp
Dictionary<int, int> freq = new();

foreach (var x in numbers)
{
    freq[x] = freq.TryGetValue(x, out var count) ? count + 1 : 1;
}
```

### Rotate Left

```csharp
int[] RotateLeft(int[] arr, int k)
{
    k %= arr.Length;
    return arr.Skip(k).Concat(arr.Take(k)).ToArray();
}
```

## Strings

### Reverse and Palindrome

```csharp
bool IsPalindrome(string s)
{
    var reversed = new string(s.Reverse().ToArray());
    return string.Equals(s, reversed, StringComparison.OrdinalIgnoreCase);
}
```

### Count Vowels and Consonants

```csharp
var vowels = 0;
var consonants = 0;

foreach (var c in input.ToLowerInvariant())
{
    if (!char.IsLetter(c)) continue;
    if ("aeiou".Contains(c)) vowels++;
    else consonants++;
}
```

### First Non-Repeating Character

```csharp
char? FirstNonRepeating(string s)
{
    var freq = s.GroupBy(c => c).ToDictionary(g => g.Key, g => g.Count());
    return s.FirstOrDefault(c => freq[c] == 1);
}
```

## Collections

### Word Frequency

```csharp
var frequency = sentence
    .Split(' ', StringSplitOptions.RemoveEmptyEntries)
    .GroupBy(w => w)
    .ToDictionary(g => g.Key, g => g.Count());
```

### Common Elements

```csharp
var common = list1.Intersect(list2).ToList();
```

### Group Even/Odd

```csharp
var grouped = numbers.GroupBy(x => x % 2 == 0 ? "Even" : "Odd");
```

## LINQ Execution

Execution order in query reasoning:

```text
Where -> GroupBy -> OrderBy -> Select
```

Materialization triggers:

- `ToList()`
- `First()`
- `Count()`
- `foreach`

## SQL-to-EF Core Conversions

| SQL | EF Core |
| --- | --- |
| EXISTS | `.Any()` |
| WHERE | `.Where()` |
| JOIN | Navigation property or `.Join()` |
| SELECT columns | `.Select(dto)` |
| GROUP BY | `.GroupBy()` |

## Problem-Solving Checklist

1. Clarify input and expected output.
2. Mention brute force.
3. Optimize using dictionary/hashset/sort/two-pointer as needed.
4. State time and space complexity.
5. Test edge cases: empty input, duplicates, nulls, one element.

## C# Output Traps

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

## JavaScript This Bind Closures

## call

`call` executes a function immediately with a custom `this`.

```js
show.call(obj, 1, 2);
```

Key line:

```text
call executes now.
```

## apply

`apply` is like `call`, but arguments are passed as an array.

```js
show.apply(obj, [1, 2]);
```

## bind

`bind` returns a new function with fixed `this` and optional pre-filled arguments.

```js
const fn = show.bind(obj, 1);
fn(2);
```

Key line:

```text
bind returns later.
```

## setTimeout Trap

Wrong:

```js
setTimeout(show.call(obj), 0);
```

Why:

```text
show.call(obj) executes immediately and returns its result. setTimeout expects a function.
```

Correct:

```js
setTimeout(show.bind(obj), 0);
setTimeout(() => show.call(obj), 0);
```

## Method Extraction Bug

```js
const fn = obj.show;
setTimeout(fn, 0);
```

Problem:

```text
Function is detached from object, so this is lost.
```

Fix:

```js
setTimeout(obj.show.bind(obj), 0);
setTimeout(() => obj.show(), 0);
```

## Arrow vs Normal Function

| Function | this behavior |
| --- | --- |
| Normal function | Dynamic `this`, depends on caller |
| Arrow function | Lexical `this`, inherited from surrounding scope |

Key line:

```text
Arrow functions ignore bind/call/apply for this binding.
```

## Partial Application

```js
function multiply(a, b, c) {
  return a * b * c;
}

const doubleThen = multiply.bind(null, 2);
console.log(doubleThen(3, 4)); // 24
```

## Constructor plus bind

```js
function Person(name) {
  this.name = name;
}

const obj = { name: "Arena" };
const BoundPerson = Person.bind(obj);
const p = new BoundPerson("JS");

console.log(p.name); // JS
```

Rule:

```text
new beats bind. Constructor call creates a fresh this.
```

## Missing Arguments

```js
function show(a, b) {
  console.log(a, b);
}

show.call(null, 1);     // 1 undefined
show.apply(null, [1]);  // 1 undefined
```

Rule:

```text
JavaScript does not enforce argument count. Missing args become undefined.
```

## Closures

A closure is when a function remembers variables from its outer scope.

```js
function makeCounter() {
  let count = 0;

  return function () {
    count++;
    return count;
  };
}
```

Common loop trap:

```js
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
```

Output:

```text
3 3 3
```

Fix:

```js
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0);
}
```

## React / React Native Callback Line

```text
Most callback bugs come from lost this, stale closures, or functions executing now instead of being passed for later.
```
