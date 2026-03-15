using PokemonConsole.Models;
using StackExchange.Redis;
using System.Collections.Concurrent;
using System.Text.Json;

namespace PokemonConsole.Services;

public class CacheService
{
    private readonly ConcurrentDictionary<string, string> memory = new();
    private static readonly Dictionary<string, object> locks = new();
    public readonly IDatabase redis;

    public CacheService()
    {
        var mux = ConnectionMultiplexer.Connect("localhost:6379");
        redis = mux.GetDatabase();
    }

    public async Task<Pokemon?> GetPokemonAsync(string name)
    {
        if (memory.ContainsKey(name))
        {
            Console.WriteLine($"Memory cache hit pokemon: {name}");
            return JsonSerializer.Deserialize<Pokemon>(memory[name]);
        }

        var redisValue = await redis.StringGetAsync(name);

        if (redisValue.HasValue)
        {
            Console.WriteLine($"Redis cache hit pokemon : {name}");
            memory[name] = redisValue!;
            return JsonSerializer.Deserialize<Pokemon?>(redisValue!);
        }

        return null;
    }

    public async Task SetPokemon(Pokemon pokemon)
    {
        var serializedPokemon = JsonSerializer.Serialize(pokemon);
        memory[pokemon.Name] = serializedPokemon;
        await redis.StringSetAsync(pokemon.Name, serializedPokemon);
    }
}