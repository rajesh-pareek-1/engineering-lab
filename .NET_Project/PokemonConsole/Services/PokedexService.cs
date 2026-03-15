using PokemonConsole.Models;

namespace PokemonConsole.Services;

public class PokedexService
{
    private static Random rand = new();

    public async Task<Pokemon> FetchPokemon(string name)
    {
        await Task.Delay(30000);
        return new Pokemon
        {
            Name = name,
            Type = "Electric",
            Power = rand.Next(30, 100)
        };
    }
}