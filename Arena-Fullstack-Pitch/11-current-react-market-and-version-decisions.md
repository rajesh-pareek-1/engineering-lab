# 11. Current React Market and Version Decisions

> **Purpose:** 45 concise questions for React + .NET interviews: versions, architecture choices, performance, security, and market direction.
> **Checked:** 23 August 2026. Do not confuse a current version with a compulsory upgrade.

## Your credibility rule

```text
Actual dm-web stack: React 18.2, TypeScript 4.9, Redux Toolkit 2.3, React Router 6
Current major line: React 19 (19.2 is the latest documented minor line)
Interview rule: say “I used React 18 in this project; I understand the React 19 direction.”
```

## Answer engine: **U-D-T**

```text
U — User/product need
D — Design decision
T — Trade-off and proof to measure
```

## A. React, framework, and runtime choices

|  # | Interview question                                     | Sharp answer                                                                                                                                                                                                                      |
| -: | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  1 | What React version is current?                         | React 19 is the current major line; React 19.2 added features such as`useEffectEvent`, `<Activity>`, and performance tooling. My project used React 18, so I describe the upgrade path honestly.                              |
|  2 | Is React 18 still a bad choice?                        | No—an existing stable React 18 application can be maintained safely. Upgrade to React 19 for supported ecosystem features or specific benefits after dependency compatibility and regression testing.                            |
|  3 | What is new in React 19 that matters in interviews?    | Actions improve mutation/form workflows; React 19 also modernizes refs and metadata handling. The important skill is still correct state ownership, effects, accessibility, and API error handling.                               |
|  4 | What changed with Create React App?                    | Create React App is deprecated for new applications. For a new app, choose a React framework when its server/routing capabilities fit, or a maintained build tool such as Vite when a client-rendered SPA is appropriate.         |
|  5 | Vite or Next.js?                                       | Vite is excellent for a client-rendered SPA with fast local tooling and a separate .NET API. Next.js fits when server rendering, SEO, framework data-fetching, or one integrated web server are real needs.                       |
|  6 | Is Next.js required for every React job?               | No. It is a valuable framework, not a replacement for understanding React. An authenticated internal operations app with a .NET API can be well served by React + Vite + React Router.                                            |
|  7 | What is React Server Components?                       | They are components rendered on the server by a supporting framework, reducing client JavaScript and allowing server-only data access. They are not a replacement for REST APIs or a feature enabled by plain client React alone. |
|  8 | SSR, CSR, and hydration?                               | CSR renders after JavaScript loads; SSR sends initial HTML from the server; hydration attaches React behavior to server-rendered HTML. Choose based on SEO, first-render performance, interactivity, infrastructure, and caching. |
|  9 | What is the current Next.js direction?                 | Next.js 16.x emphasizes Turbopack, caching/partial rendering, React 19.2, and server/client boundaries. I would adopt it for demonstrated product needs, not migrate a functioning SPA just because it is fashionable.            |
| 10 | Which Node.js version should a new frontend build use? | Use an Active or Maintenance LTS line, not an arbitrary “latest current” version. As checked, Node 24 is LTS while Node 26 is current; production CI should pin and patch an LTS version.                                       |
| 11 | Why does TypeScript version matter?                    | It affects compiler behavior, library types, build compatibility, and tooling. TypeScript 5.9 is current in this sheet; upgrade deliberately because stricter inference or DOM type changes can reveal real issues.               |
| 12 | `strict: true` or relaxed TypeScript?                | Prefer`strict: true` for new code and fix errors incrementally in legacy code. It moves null and unsafe-data mistakes earlier, but needs a realistic migration plan rather than one massive risky PR.                           |
| 13 | `any` or `unknown` for API data?                   | Use`unknown` at untrusted boundaries, validate/narrow it, then map to typed UI models. `any` turns off the safety TypeScript was added to provide.                                                                            |
| 14 | ESM or CommonJS?                                       | Prefer ESM for modern web tooling and align`tsconfig`, Node version, and package settings. Mixed module systems can cause build/runtime surprises, so compatibility matters more than syntax preference.                        |

## B. State, data, and React architecture

|  # | Interview question                                         | Sharp answer                                                                                                                                                                                                                                 |
| -: | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 15 | Where should state live?                                   | Keep state as close as possible to where it is used. Local UI state stays in the component; shared client state may use Redux; server data belongs in a server-state cache such as RTK Query or TanStack Query.                              |
| 16 | Redux Toolkit still relevant?                              | Yes, especially for explicit shared client state and teams that value predictable reducers/devtools. Use Redux Toolkit rather than hand-written legacy Redux boilerplate.                                                                    |
| 17 | RTK Query versus TanStack Query?                           | Both solve server-state fetching, caching, invalidation, and loading/error states. RTK Query integrates naturally with a Redux store; TanStack Query is framework-focused and independent of Redux—choose one rather than duplicate caches. |
| 18 | Why is “server state” different from normal React state? | Server data can become stale outside the browser, needs caching/refetching, invalidation, retries, and synchronization. A plain`useState` array does not solve those lifecycle concerns.                                                   |
| 19 | When use optimistic update?                                | For a safe, frequent action where fast feedback matters. Update UI immediately, retain rollback data, reconcile with the server response, and avoid it for irreversible or high-risk operations without idempotency/conflict design.         |
| 20 | What should`useEffect` be used for?                      | Synchronizing with an external system: fetching, subscriptions, timers, browser APIs. It is not a general place for derived state; derive values during render where possible.                                                               |
| 21 | What is`useEffectEvent`?                                 | A React 19.2 API for non-reactive logic called from an Effect, reducing dependency-array hacks and stale closures. I use it only when an Effect genuinely needs that separation.                                                             |
| 22 | What is a custom hook for?                                 | It packages reusable stateful behavior—such as`useDocuments`, auth refresh, or upload state—while keeping component rendering focused. It is reuse, not a global singleton.                                                              |
| 23 | Should every API call go through Redux?                    | No. A component-local call can be enough for isolated work. Use RTK Query/Redux when shared cache, invalidation, global coordination, and consistent loading/error handling justify it.                                                      |
| 24 | What is a BFF?                                             | Backend for Frontend: a backend layer shaped for one UI’s needs. It can aggregate services, protect browser credentials, and reduce chatty requests, but adds another component to secure and operate.                                      |
| 25 | Why use OpenAPI client generation?                         | It reduces manual drift between .NET DTOs and TypeScript types. It still does not remove the need for server validation, business-rule tests, error handling, or reviewed API changes.                                                       |

## C. Performance and user experience

|  # | Interview question                                  | Sharp answer                                                                                                                                                                                                                     |
| -: | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 26 | What is React Compiler?                             | It is now stable and automatically memoizes eligible React components/hooks at build time. It can reduce manual`memo`, `useMemo`, and `useCallback`, but it does not fix slow APIs, huge lists, or incorrect state design. |
| 27 | Should I remove all`useMemo` and `useCallback`? | No. First profile. The compiler can reduce the need for manual memoization, but existing code and libraries still need correctness; add or remove memoization based on measured rerender cost.                                   |
| 28 | How do you optimize a large grid/list?              | Server-side filter/sort/pagination first, then virtualize rows, render stable keys, minimize row props/state, and measure browser/Network/API bottlenecks. Virtualization cannot fix an API returning 100,000 rows.              |
| 29 | What is code splitting?                             | Load a route or expensive feature only when needed, usually with dynamic import and`lazy`/Suspense. It improves initial load, but too many tiny chunks create request overhead.                                                |
| 30 | How do you prevent frontend request waterfalls?     | Fetch independent data in parallel, use a server/BFF aggregation endpoint when it meaningfully reduces round trips, preload likely routes, and avoid sequential effects that do not have data dependencies.                      |
| 31 | What do Web Vitals tell you?                        | They indicate user-perceived loading, interaction responsiveness, and visual stability. I combine them with API latency, browser performance recordings, and real-user telemetry before changing architecture.                   |
| 32 | How do you handle a component crash?                | Use an Error Boundary for render/lifecycle errors, show a recovery UI, log a correlation ID, and keep critical workflows recoverable. It does not catch every async event-handler/API failure, so those still need`try/catch`. |
| 33 | What does accessible UI mean to an engineer?        | Semantic controls, labels, keyboard navigation, visible focus, useful validation messages, and appropriate ARIA only when native HTML is insufficient. Accessibility is functional correctness, not polish.                      |
| 34 | Why not store a`File` object in Redux?            | It is non-serializable, often large, and short-lived. Keep it in component state/ref, submit as`FormData`, then store only upload metadata/status in shared state if required.                                                 |

## D. Security, contracts, and .NET integration

|  # | Interview question                                | Sharp answer                                                                                                                                                                                                                                                  |
| -: | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 35 | Where should browser tokens live?                 | It depends on the threat model. HttpOnly Secure SameSite cookies reduce JavaScript/XSS access but require CSRF protection; browser storage is accessible to JavaScript, so never call it completely secure.                                                   |
| 36 | Is CORS authentication?                           | No. CORS is a browser rule controlling cross-origin JavaScript requests. The .NET API still needs authentication and authorization for every request.                                                                                                         |
| 37 | How do you reduce XSS risk?                       | Avoid unsafe HTML rendering, escape untrusted data by default, validate/sanitize rich text when it is required, use a strong CSP where feasible, and never expose tokens/secrets in rendered content.                                                         |
| 38 | How do you handle CSRF with cookie auth?          | Use SameSite appropriately, anti-forgery tokens or other CSRF defenses for state-changing requests, and verify Origin/Referer where part of the design. Bearer-token APIs have different trade-offs.                                                          |
| 39 | How does React upload a document to .NET?         | Build`FormData`, send `multipart/form-data` with authorization, show loading/progress/error, and let ASP.NET Core bind `[FromForm]` plus `IFormFile`. The server validates file type/size/ownership and stores metadata separately from the binary.   |
| 40 | What is the correct file-storage design?          | Blob/object storage holds the binary; SQL holds metadata, status, owner, expiry/version, and audit information. If Blob succeeds but SQL fails, use compensation or Pending/Completed plus reconciliation; one SQL transaction cannot roll back Blob Storage. |
| 41 | REST or GraphQL for a React application?          | REST is strong for stable resource commands and clear HTTP behavior. GraphQL can reduce over/under-fetching for complex connected screens, but requires resolver authorization, complexity limits, and N+1 protection.                                        |
| 42 | How does real-time UI fit .NET?                   | SignalR can push a small event such as`ShipmentUpdated`; the client updates/invalidate its cached query. Durable business work belongs in the backend/database/queue, not only in a live socket.                                                            |
| 43 | How do you make client/server contracts reliable? | Agree on route, verb, auth, DTO schema, nullability, status/error shape, pagination, and idempotency. OpenAPI plus generated types help, while backend validation remains authoritative.                                                                      |
| 44 | Should we use microfrontends?                     | Only when independently owned/deployed frontend domains justify the integration cost. A modular monolith frontend with clear feature boundaries is simpler for most teams.                                                                                    |
| 45 | How should a full-stack engineer use AI tools?    | Use AI to accelerate drafts, tests, and investigation, then review output for correctness, security, accessibility, performance, licensing, and data exposure. Never send production secrets, patient/customer data, or tokens to an unapproved tool.         |

## ROD/dm-web delivery lines

```text
dm-web used React 18.2, TypeScript 4.9, Redux Toolkit 2.3, and React Router 6.
I would not pretend it already used React 19, React Compiler, Vite, or Next.js.

For a new authenticated operations SPA with a separate .NET API:
React + TypeScript + Vite + React Router + RTK Query is a sensible baseline.

For SEO/server rendering and a React-owned web backend:
consider a framework such as Next.js—but define BFF/auth/cache ownership clearly.
```

## Primary sources for version facts

- [React 19.2 release](https://react.dev/blog/2025/10/01/react-19-2)
- [React Compiler 1.0](https://react.dev/blog/2025/10/07/react-compiler-1)
- [Create React App deprecation and current setup guidance](https://react.dev/blog/2025/02/14/sunsetting-create-react-app)
- [TypeScript 5.9 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-9.html)
- [Node.js release/LTS schedule](https://nodejs.org/en/about/previous-releases)
- [Next.js 16](https://nextjs.org/blog/next-16)
- [ASP.NET Core OpenAPI support](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0)
