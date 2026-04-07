var list = new List<int> { 1, 2, 3 };

var query = list.Where(x => x > 1);
var materialized = list.Where(x => x > 1).ToList();

list.Add(10);

foreach (var x in query)
    Console.Write(x + " ");

Console.Write("| ");

foreach (var x in materialized)
    Console.Write(x + " ");