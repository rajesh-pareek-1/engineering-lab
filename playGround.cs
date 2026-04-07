Func<int> f = () => { Console.Write("A "); return 1; };
f += () => { Console.Write("B "); throw new Exception(); };
f += () => { Console.Write("C "); return 3; };

try
{
    var result = f();
    Console.Write(result);
}
catch
{
    Console.Write("Caught ");
}