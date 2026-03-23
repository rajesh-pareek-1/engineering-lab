# 📘 C# Coding & OOP Revision Notes

---

# 🟣 OOP (Interface + Abstract)

## 🔹 Interface Example

```csharp
interface IShape
{
    int Area();
}

public class Circle : IShape
{
    public int Radius { get; set; }

    public Circle(int radius)
    {
        Radius = radius;
    }

    public int Area()
    {
        return (int)(3.14m * Radius * Radius);
    }
}
```

---

## 🔹 Abstract Class Example

```csharp
public abstract class Vehicle
{
    public abstract void Start();
}

public class Car : Vehicle
{
    public void Horn()
    {
        Console.WriteLine("Car Honking");
    }

    public override void Start()
    {
        Console.WriteLine("Car Started");
    }
}
```

---

# 🟢 Arrays

## 🔹 Second Largest Element

```csharp
int[] arr = { 3, 5, 4, 6, 1 };

Array.Sort(arr);
Array.Reverse(arr);

Console.WriteLine(arr[1]);
```

---

## 🔹 Find Duplicates

```csharp
List<int> list = new() { 3, 4, 2, 1, 2, 4 };

Dictionary<int, int> dict = new();
List<int> duplicates = new();

foreach (var x in list)
{
    if (dict.ContainsKey(x))
        duplicates.Add(x);
    else
        dict[x] = 1;
}

Console.WriteLine(string.Join(", ", duplicates));
```

---

## 🔹 Remove Duplicates

```csharp
int[] arr = { 1, 2, 3, 4, 5, 6 };

var result = arr.Distinct();

Console.WriteLine(string.Join(", ", result));
```

---

## 🔹 Frequency Count

```csharp
int[] arr = { 1, 2, 2, 3, 3, 3, 4 };

Dictionary<int, int> dict = new();

foreach (var x in arr)
{
    if (dict.ContainsKey(x))
        dict[x]++;
    else
        dict[x] = 1;
}

foreach (var item in dict)
{
    Console.WriteLine($"{item.Key} -> {item.Value}");
}
```

---

## 🔹 Rotate Array (Left)

```csharp
int[] arr = { 1, 2, 3, 4, 5 };
int k = 2;

k = k % arr.Length;

int[] rotated = new int[arr.Length];

for (int i = 0; i < arr.Length; i++)
{
    rotated[(i + arr.Length - k) % arr.Length] = arr[i];
}

Console.WriteLine(string.Join(", ", rotated));
```

---

# 🔵 Strings

## 🔹 Reverse String & Palindrome

```csharp
string str = "pep";

var reversed = new string(str.Reverse().ToArray());

Console.WriteLine(reversed);
Console.WriteLine(str == reversed);
```

---

## 🔹 Count Vowels & Consonants

```csharp
string str = "hello world";
str = str.ToLower();

int vowels = 0, consonants = 0;

foreach (char c in str)
{
    if (char.IsLetter(c))
    {
        if ("aeiou".Contains(c))
            vowels++;
        else
            consonants++;
    }
}

Console.WriteLine($"Vowels: {vowels}, Consonants: {consonants}");
```

---

## 🔹 Remove Duplicate Characters

```csharp
string str = "programming";

HashSet<char> seen = new();
string result = "";

foreach (char c in str)
{
    if (!seen.Contains(c))
    {
        seen.Add(c);
        result += c;
    }
}

Console.WriteLine(result);
```

---

## 🔹 First Non-Repeating Character

```csharp
string str = "programming";

Dictionary<char, int> dict = new();

foreach (var c in str)
{
    if (dict.ContainsKey(c))
        dict[c]++;
    else
        dict[c] = 1;
}

var first = dict.First(x => x.Value == 1).Key;

Console.WriteLine(first);
```

---

# 🟡 Collections

## 🔹 Word Frequency

```csharp
string sentence = "this is a test this is a test";

var words = sentence.Split(' ');

Dictionary<string, int> dict = new();

foreach (var word in words)
{
    if (dict.ContainsKey(word))
        dict[word]++;
    else
        dict[word] = 1;
}

foreach (var item in dict)
{
    Console.WriteLine($"{item.Key} -> {item.Value}");
}
```

---

## 🔹 Common Elements (LINQ)

```csharp
var list1 = new List<int> { 1, 2, 3, 4 };
var list2 = new List<int> { 3, 4, 5, 6 };

var common = list1.Intersect(list2);

Console.WriteLine(string.Join(", ", common));
```

---

## 🔹 Grouping (Even/Odd)

```csharp
var numbers = new[] { 1, 2, 3, 4, 5, 6 };

var grouped = numbers.GroupBy(x => x % 2 == 0 ? "Even" : "Odd");

foreach (var group in grouped)
{
    Console.WriteLine(group.Key);

    foreach (var num in group)
        Console.WriteLine(num);
}
```

---

# 🔴 LINQ

## 🔹 Filter

```csharp
var employees = new List<Employee>
{
    new Employee { Name = "Rajesh", Salary = 30000 },
    new Employee { Name = "Amit", Salary = 50000 }
};

var result = employees.Where(e => e.Salary > 40000);
```

---

## 🔹 Group By

```csharp
var grouped = employees
    .GroupBy(e => e.Department)
    .Select(g => new
    {
        Department = g.Key,
        Count = g.Count()
    });
```

---

## 🔹 Sorting

```csharp
var sorted = employees
    .OrderBy(e => e.Salary)
    .ThenBy(e => e.Name);
```

---

# 🧠 LINQ Execution Order

```text
Where → GroupBy → OrderBy → Select
```

---

# ⚡ Quick Tips (Revision Gold)

- `Dictionary` → counting
- `HashSet` → duplicates removal
- `LINQ` → clean transformations
- `ToList()` → triggers execution
- `IEnumerable` → in-memory
- `IQueryable` → DB-side

---

# 🚀 FINAL NOTE

👉 You now have:

- ✔️ OOP basics
- ✔️ Arrays
- ✔️ Strings
- ✔️ Collections
- ✔️ LINQ
