using System.Collections.Concurrent;

namespace PokemonConsole.Services;

public class TrainerWorker
{
    public readonly CacheService cache;
    private readonly PokedexService pokedex;
    private static string[] pokemonList =
    {
        "Pikachu","Charmander","Squirtle","Bulbasaur","Snorlax","Gengar"
    };
    private static Random rand = new();
    private static ConcurrentDictionary<string, object> pokemonLocks = new();

    public TrainerWorker(CacheService cache, PokedexService pokedex)
    {
        this.cache = cache;
        this.pokedex = pokedex;
    }

    public async Task Start(string trainer)
    {
        while (true)
        {
            var pokemonName = pokemonList[rand.Next(0, pokemonList.Length)];
            Console.WriteLine($"{trainer} encountered pokemon : {pokemonName}");

            var pokemon = await cache.GetPokemonAsync(pokemonName);
            if (pokemon == null)
            {
                var pokemonLock = pokemonLocks.GetOrAdd(pokemonName, _ => new object());
                lock (pokemonLock)
                {
                    pokemon = cache.GetPokemonAsync(pokemonName).Result;
                    if (pokemon == null)
                    {
                        Console.WriteLine($"fetching from pokedex: {pokemonName}");
                        pokemon = pokedex.FetchPokemon(pokemonName).Result;
                        cache.SetPokemon(pokemon).Wait();
                    }
                }


            }

            Console.WriteLine($"{trainer} caught Pokemon : {pokemon.Name},(Power : {pokemon.Power})");
            await Task.Delay(2000);
        }
    }
}