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

# Clone the Repository

Clone the project:

git clone <repository-url>

Navigate into backend folder:

cd backend

---

# Restore Dependencies

Restore NuGet packages:

dotnet restore

---

# Build the Solution

Build the project:

dotnet build

---

# Open Project in Visual Studio

1. Open **Visual Studio**
2. Click **Open a project or solution**
3. Navigate to the backend folder
4. Select:

PodTracker.slnx

5. Click **Open**

---

# Run the Project

Set the startup project:

PodTracker.AppHost

Then run the application:

F5

or click **Start Debugging**.

---


## Running the Project

Run the Aspire host:

dotnet run --project PodTracker.AppHost

Aspire dashboard will open at:

https://localhost:17281/

Swagger UI for the API:

https://localhost:7184/swagger/index.html