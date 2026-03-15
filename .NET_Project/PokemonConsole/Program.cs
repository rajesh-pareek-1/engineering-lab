using PokemonConsole.Services;

var CacheService = new CacheService();
var pokedexService = new PokedexService();

var worker = new TrainerWorker(CacheService, pokedexService);

var trainers = new[]
{
    "Ash",
    "Rajesh",
    "Mishty",
    "Aditya"
};

var tasks = trainers.Select(trainer => Task.Run(() => worker.Start(trainer)));
await Task.WhenAll(tasks);