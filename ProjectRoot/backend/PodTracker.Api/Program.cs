var builder = WebApplication.CreateBuilder(args);

// Add Swagger services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Enable Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Root endpoint
app.MapGet("/", () => "PodTracker API Running");

// Test endpoint
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild",
    "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};
app.MapGet("/businesslogic", () =>
{
    var checkresp = new PodTracker.BusinessLogic.Class1();
    return ;

});
app.MapGet("/dbLogic", () =>
{
    var checkresp = new PodTracker.Db.Class1();
    return ;

});
app.MapGet("/entityLogic", () =>
{
    var checkresp = new PodTracker.Entities.Class1();
    return ;

});
app.MapGet("/repoLogic", () =>
{
    var checkresp = new PodTracker.Repository.Class1();
    return ;

});
app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast(
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        )).ToArray();

    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}