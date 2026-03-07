# PodTracker Backend

This project follows a layered architecture using **ASP.NET Core**, **.NET Aspire**, and **Entity Framework Core**.

## Folder Structure

backend
│
├── PodTracker.slnx
│   Solution file that manages all backend projects.
│
├── PodTracker.AppHost
│   Aspire host project responsible for running and orchestrating services.
│
├── PodTracker.Api
│   ASP.NET Core Web API project.
│   Contains controllers, endpoints, and Swagger configuration.
│
├── PodTracker.BusinessLogic
│   Contains business rules and service implementations.
│
├── PodTracker.Repository
│   Handles data access logic and repository implementations.
│
├── PodTracker.Db
│   Contains database configuration and DbContext setup.
│
└── PodTracker.Entities
    Contains entity models and DTOs used across the application.

## Architecture Flow

Client Request
↓
PodTracker.Api (Controllers / Endpoints)
↓
PodTracker.BusinessLogic (Application Services)
↓
PodTracker.Repository (Data Access)
↓
PodTracker.Db (DbContext / Database)
↓
PodTracker.Entities (Domain Models)

## Running the Project

Run the Aspire host:

dotnet run --project PodTracker.AppHost

Aspire dashboard will open at:

https://localhost:17281/

Swagger UI for the API:

https://localhost:7184/swagger/index.html