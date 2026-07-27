# 10. Full-Stack Mock Interview and Rapid Revision

## Two-hour plan

| Time | Sheet | Target |
|---:|---|---|
| 10 min | 1 | Introduction and honest boundaries |
| 20 min | 2 | ROD pitch and attachment flow |
| 15 min | 3 | React/TypeScript fundamentals |
| 10 min | 4 | Hooks, forms, routing |
| 15 min | 5 | Redux Toolkit and RTK Query |
| 15 min | 6 | JWT, API, errors |
| 10 min | 7 | Debugging, performance, tests |
| 15 min | 8 | .NET, EF Core, SQL bridge |
| 5 min | 9 | Git, CI/CD, collaboration |
| 5 min | 10 | Speak final answers aloud |

## Answer engine: **H-E-A-R-T**

1. **Headline:** answer immediately.
2. **Explain:** principle.
3. **Apply:** ROD example.
4. **Risk:** trade-off/failure.
5. **Tie:** decision/result.

## Mock questions

### Tell me about yourself

Use Sheet 1. Lead with production SaaS and ROD, then backend strength plus frontend system understanding.

### Explain Roll On Dispatch end to end

> ROD has a React/TypeScript web client using Redux Toolkit and RTK Query, communicating over authenticated REST APIs with a .NET 8 backend using ASP.NET Core, EF Core, and SQL Server. A user action such as uploading a driver document begins in a component/hook, sends a typed authenticated request, reaches a controller and service, updates blob and SQL state, then returns metadata so the UI can refresh its cache and show success or error. My strongest direct contribution was backend reliability in that attachment flow and document-expiry notifications.

### React props vs state

> Props are read-only inputs from a parent. State is data owned by a component or external store that changes and drives renders. I keep state at the narrowest correct owner.

### `useEffect`

> It synchronizes a component with an external system after render. Dependencies declare values used by the effect; cleanup removes subscriptions or timers. I do not use it for values that can be calculated during render.

### Redux vs RTK Query

> Redux slices manage global client workflow state. RTK Query manages server state: requests, cache, loading/error state, deduplication, invalidation, and refetching. ROD injects generated endpoints into a shared root API.

### How is JWT attached?

> The RTK Query base prepares the Authorization Bearer header using the current token. The server independently validates the token and authorizes tenant/resource access. Protected React routes are UX, not the security boundary.

### How do you handle API errors?

> Map status and structured ProblemDetails into actionable UI: field errors for validation, login/refresh behavior for 401, access message for 403, refresh/conflict action for 409, and generic message plus trace ID for unexpected 500. Preserve logs without exposing internals.

### How do you optimize a React page?

> Measure first. Check bundle, requests, component render cost, list size, and state subscriptions. Use server pagination, virtualization, lazy loading, focused selectors, and memoization only where profiling shows value.

### How do you optimize a slow full-stack feature?

> Start with browser timing, separate frontend rendering from network time, inspect API traces and EF SQL, then the execution plan and external dependencies. Fix the measured layer and compare before/after with representative data.

### Explain a transaction

> Related SQL changes form one atomic unit: commit all or rollback all. One EF `SaveChanges` is transactional by default; explicit control is useful across multiple database operations. Blob storage is not part of SQL transaction, so use compensation or recoverable states.

### Unit vs integration test

> A unit test isolates behavior. An integration test verifies components together. ROD frontend uses Jest/React Testing Library dependencies; backend uses xUnit, Moq, FluentAssertions, and `WebApplicationFactory` integration tests.

### What did you personally build in the frontend?

> My strongest verified implementation work is backend. On the web side, my experience includes understanding and supporting API integration flows, contract debugging, and tracing React/Redux behavior around backend features. I can explain the existing frontend architecture, but I do not claim sole ownership of modules whose code history is not mine.

### Why call yourself full stack?

> Full stack does not mean equal depth in every technology. My deeper skill is .NET backend engineering, while I can understand, debug, and contribute across the React/TypeScript integration boundary. I am pursuing full-stack roles to increase that frontend ownership while already bringing production backend depth.

### PostgreSQL experience

> My hands-on project database is SQL Server. PostgreSQL in the tailored resume is an error. I understand relational concepts, but I would learn and verify PostgreSQL-specific behavior before claiming production expertise.

## Resume technology boundary

The current `dm-web` repository directly supports these claims:

- React 18 and TypeScript;
- Redux Toolkit, React Redux, and RTK Query;
- React Router, Bootstrap, i18next, and Google Maps;
- Jest and React Testing Library dependencies;
- Swagger/OpenAPI RTK Query code generation;
- ESLint, Prettier, Husky, Git, and Azure Static Web App pipeline.

The current repository does **not** directly establish personal production ownership of 70+ generated endpoints, AG Grid, Chart.js, FullCalendar, Vite, Vitest, or the complete frontend modules. It uses Create React App rather than Vite and Jest-oriented testing rather than Vitest. Discuss those technologies only when you have a separate real project/example.

### React Native boundary

> ROD also has a separate React Native driver application supporting mobile operational workflows. My full-stack explanation focuses on `dm-web` plus `dm-api`. If asked about mobile, I can explain the API-contract, JWT, notification, geolocation, and offline-sync concerns, but I will distinguish integration exposure from features I personally implemented.

## Rapid fire

1. Props vs state.
2. Controlled input.
3. `useEffect` cleanup.
4. `useMemo` vs `useCallback`.
5. Stable list keys.
6. `type` vs `interface`.
7. `any` vs `unknown`.
8. Redux vs Context.
9. Redux slice vs RTK Query cache.
10. Query vs mutation.
11. Cache invalidation.
12. Optimistic update.
13. Protected route vs API authorization.
14. `401` vs `403`.
15. Access vs refresh token.
16. Axios vs RTK Query.
17. Client vs server validation.
18. CORS.
19. Component vs custom hook.
20. Debounce vs throttle.
21. Lazy loading vs virtualization.
22. DTO vs entity.
23. Eager vs lazy EF loading.
24. `IQueryable` vs `IEnumerable`.
25. Transaction and ambient transaction.
26. Index and execution plan.
27. Unit vs integration test.
28. Docker multi-stage build.
29. CI vs CD.
30. How to debug stale UI.

## Five-minute memory palace

Imagine the dispatch office:

1. **Door:** JWT login and protected route.
2. **Form desk:** React component and validation.
3. **Dispatch board:** Redux state and RTK Query cache.
4. **Telephone:** REST contract and status codes.
5. **Manager:** ASP.NET Core service rules.
6. **Filing room:** EF Core and SQL Server.
7. **Document cabinet:** blob attachment consistency.
8. **Security camera:** logs, analytics, error boundary.
9. **Workshop:** frontend/backend tests.
10. **Delivery truck:** Git, pipeline, Azure deployment.

## Questions for interviewer

- How is full-stack ownership divided between React and .NET work?
- Which frontend modules have the highest performance or maintainability challenges?
- How does the team manage API contract changes between frontend and backend?
- What would successful delivery in the first three months look like?

## Final reset

Your strongest position is not “I built everything.” It is: **I understand the whole flow, I can prove my backend work, I can debug the React integration boundary, and I am ready to own more of the frontend.**
