var builder = DistributedApplication.CreateBuilder(args);

// Register API project
var api = builder.AddProject<Projects.PodTracker_Api>("podtracker-api")
    ;

builder.Build().Run();