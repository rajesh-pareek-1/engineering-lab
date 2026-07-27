# 1. Introduction and Full-Stack Interview Map

## 90-second introduction

> Hi, I am Rajesh Pareek. I am a software engineer with around two and a half years of experience working on production SaaS applications. My strongest project is Roll On Dispatch, a multi-tenant logistics platform with a React and TypeScript web application, React Native mobile clients, and a .NET 8 backend using ASP.NET Core, EF Core, and SQL Server.
>
> My strongest hands-on contribution is on the backend, including driver-load attachments, SQL transaction handling, document-expiry notification logic, REST APIs, and integration debugging. I also understand the web application end to end: React components and hooks, Redux state, RTK Query API calls, JWT-protected routes, forms, load-board and shipment workflows, and how frontend contracts map to ASP.NET Core endpoints.
>
> I am comfortable tracing a feature from a user action in the browser through Redux and the REST API into controller, service, EF Core, and SQL Server, then back to loading, success, or error state in the UI. I have also worked with tests, structured logging, Git, Docker, Azure DevOps, and production support. I am looking for a full-stack role where I can use my .NET strength while taking deeper ownership across the React frontend.

## Mnemonic: **F-L-O-W-S**

- **F - Frontend:** React, TypeScript, components, hooks.
- **L - Logic/state:** Redux Toolkit and RTK Query.
- **O - Operations:** shipments, drivers, loads, documents.
- **W - Web API:** ASP.NET Core, JWT, DTOs.
- **S - Storage/support:** EF Core, SQL Server, logs, tests, deployment.

## Full-stack mind map

```text
User action
  → React component
  → hook / form validation
  → Redux Toolkit or RTK Query
  → HTTP + JWT
  → ASP.NET Core controller
  → service / business rules
  → EF Core / SQL Server
  → JSON response
  → cache/state update
  → UI loading, success, or error
```

## Claim calibration

Use language precisely:

- **“I implemented”** only for code you personally implemented.
- **“I contributed to”** for shared features.
- **“I supported the integration”** for API-contract and debugging work.
- **“The application uses”** when describing architecture visible in the repository.
- **“My understanding from working with the flow is...”** when you can explain it but did not own it.

The `dm-web` Git history does not show commits under your name. Therefore, do not claim sole ownership of shipment builder, load board, Google Maps, RTK Query generation, or the frontend architecture unless you can identify your work under another author identity.

## Three answer lengths

### One line

> I am a .NET-strong full-stack developer who can trace Roll On Dispatch features from React UI through ASP.NET Core and SQL Server.

### 30 seconds

> I have 2.5 years of experience in production SaaS, mainly on Roll On Dispatch and Feedlot Manager. My strongest skills are C#, ASP.NET Core, EF Core, SQL Server, React, and TypeScript integration. I have worked directly on backend reliability features and collaborated across web and mobile API flows, with exposure to Redux Toolkit, RTK Query, JWT security, testing, and Azure DevOps.

### Project transition

> The best way to explain my full-stack understanding is through Roll On Dispatch, because its web client and backend clearly show the complete request and data flow.

## How to answer any feature: **U-I-B-D-R**

1. **U - User:** what is the user trying to accomplish?
2. **I - Interface:** component, form, validation, loading state.
3. **B - Backend:** endpoint, authorization, business rule.
4. **D - Data:** EF Core query, SQL transaction, external service.
5. **R - Result:** state/cache refresh, message, logging, test.

## Honest corrections

### PostgreSQL

> My hands-on work on these projects used SQL Server. PostgreSQL was included in a tailored resume by mistake. I understand transferable relational concepts, but I do not claim production PostgreSQL expertise.

### React-first wording

> My strongest verified contribution is backend work. I have substantial understanding of the React application's structure and integration flow, but I distinguish that from claiming that I personally built every frontend module.

## Confidence rule

Do not try to sound like you wrote the entire platform. Sound like an engineer who understands the complete system, knows exactly what he owned, and can reason about the parts around it.

