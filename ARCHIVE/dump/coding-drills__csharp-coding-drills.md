# C# Coding Drills

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

