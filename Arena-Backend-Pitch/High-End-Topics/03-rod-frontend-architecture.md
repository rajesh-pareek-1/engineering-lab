# High-End Topic 03 — ROD Web Frontend Architecture

> **Scope:** The current `dm-web` React application, not the older embedded `ReactFrontend` folder inside the backend solution.

---

## Architecture in one sentence

> **“ROD web is a React 18 + TypeScript single-page application with route-level access control, Redux Toolkit/RTK Query for shared state and generated API access, plus feature-oriented pages, reusable common components, and Axios-based integration paths.”**

```text
Browser
  ↓
React root providers
  ↓
routes / authenticated layout
  ↓
pages + reusable components/hooks
  ↓
Redux state / RTK Query cache / Axios API clients
  ↓ Bearer JWT
ROD ASP.NET Core API
```

---

## 1. Repository map and responsibility

```text
dm-web/src/
├── index.tsx                 application bootstrap/providers/error boundary
├── App.tsx                   routes, protected layout, i18n, toast boundary
├── useApp.tsx                application-level route/auth behavior
├── pages/                    route screens and feature UI
├── components/               reusable presentational/shared UI
├── common/                   reusable domain UI + hooks/reducers
├── api/                      feature API clients and interfaces
├── redux/                    store, slices, RTK Query generated APIs
├── services/                 authentication/session/API constants
├── utils/                    routes, helpers, hooks, validations
├── types/                    TypeScript models
├── featureFlags/             client feature configuration
├── i18n/                     translations and language initialization
└── assets/                   images, icons, styles
```

```text
pages        = compose a user-facing feature/screen
components   = reusable UI building blocks
common       = reusable behavior/domain UI shared by many features
api/redux    = data boundary; do not put HTTP calls throughout JSX
services     = session and cross-feature infrastructure
utils/types  = shared pure helpers/contracts
```

---

## 2. Application bootstrap flow

```text
src/index.tsx
        ↓
createRoot(...)
        ↓
ErrorBoundary
        ↓
optional PostHog provider
        ↓
Redux <Provider store={store}>
        ↓
<BrowserRouter>
        ↓
<App />
```

`App.tsx` adds:

```text
Suspense + AppLoader
i18next provider
ToastContainer
authenticated Header/layout
public/private route selection
role-based route guard
NotFound fallback
```

This means startup concerns are composed once rather than copied into every page.

---

## 3. Routing and authorization

```text
useApp()
        ↓
isAuthenticated?
        ├── no  → PUBLIC_ROUTES
        └── yes → PRIVATE_ROUTES
                      ↓
                isProtectedRoute(requiredRoles)?
                      ↓
                 render page / Navigate to '/'
```

The frontend route guard improves user experience, but it is **not security**.

```text
Frontend: hides/redirects UI
Backend: JWT + roles/permissions enforce the real access decision
```

Never say “React authorization protects the API.” The backend must reject an unauthorized direct HTTP request.

---

## 4. State and server-data architecture

```text
Redux Toolkit store
├── auth state
├── feature slices, for example MCS orders/drafts/review
└── RTK Query root API cache + middleware

Local component state
└── modal open/close, form inputs, temporary visual state

Server data
└── RTK Query endpoints / feature API clients
```

`redux/store.ts` uses `configureStore`, the root reducer, and RTK Query middleware. API code is partly generated from the backend OpenAPI/Swagger contract through `rtk-query/codegen-openapi` and partly maintained as feature Axios clients under `src/api`.

Why this is useful:

```text
generated contract client → fewer manual API type mistakes
RTK Query                → cache, loading/error state, invalidation conventions
Redux slices             → shared client workflow state
local state              → avoids putting every input/modal into Redux
```

---

## 5. Real login-to-API flow

```text
Login page
        ↓
services/auth/index.ts → signInUser(...)
        ↓
GET auth endpoint with Basic credentials for login
        ↓
Backend returns JWT + refresh token + tenant ID + roles + permissions
        ↓
saveLoginData(...) + Redux auth actions
        ↓
private routes become available
        ↓
API client sends Authorization: Bearer <access token>
        ↓
ROD backend validates JWT and resolves tenant database
```

The source supports “remember me” by using `localStorage` or `sessionStorage`; it decodes the JWT for client display/state and stores tenant/role/permission data for UX.

### Security line for interviews

> “The frontend can decode a JWT for display decisions, but it never validates or trusts it as the authority. The ASP.NET Core API validates the signature and enforces authorization.”

### Improvement without blaming existing code

```text
Access tokens in localStorage are exposed to XSS if malicious script executes.

For a modern browser-first design, prefer:
short-lived access token in memory
refresh token in Secure + HttpOnly + SameSite cookie
CSRF protection if cookie auth is used
strong Content Security Policy and XSS prevention
```

---

## 6. Real page-to-API path

```text
User opens feature page
        ↓
pages/<Feature>/... component
        ↓
feature hook / event handler
        ↓
RTK Query hook OR src/api/<feature>/<feature>Api.ts
        ↓
Axios / generated endpoint
        ↓
Bearer token attached
        ↓
ASP.NET Core REST endpoint
        ↓
response normalised into component state / Redux cache
        ↓
component renders loading, error, empty, or data state
```

Example source conventions:

```text
src/api/trailer/trailerApi.ts          feature-specific API contract
src/redux/Apis/...                    RTK Query base/generated endpoints
src/common/hooks/...                  reusable feature behavior
src/pages/...                         route-level composition
```

---

## 7. Reliability and user-experience boundaries

| Need                       | ROD web mechanism                                                    |
| -------------------------- | -------------------------------------------------------------------- |
| React render failure       | root`ErrorBoundary` with fallback page                             |
| Dynamic-code/chunk failure | `window.onerror` / unhandled-rejection handler routes chunk errors |
| Async route/loading state  | `Suspense` + app loader                                            |
| User feedback              | toast notifications                                                  |
| API cache/loading/error    | RTK Query conventions and API clients                                |
| Feature rollout/analytics  | feature configuration + optional PostHog provider                    |
| Localization               | `i18next` provider and English/Spanish resource files              |

---

## 8. Why this architecture fits

```text
React SPA
→ rich dispatch UI, interactive forms, maps, data grids, workflow screens.

TypeScript
→ catches contract/state mistakes earlier.

RTK Query + API generation
→ keeps client contract closer to Swagger/OpenAPI.

Feature folders and reusable common components
→ avoid one enormous page/App component.

BrowserRouter
→ client-side navigation without full page loads.
```

### Advantages

```text
clear entry point and global providers
reusable UI/hook layers
typed shared API models
central session handling
cached server data where RTK Query is used
route-level roles improve UX
```

### Trade-offs

```text
two data-access styles (Axios feature APIs + RTK Query) can create inconsistency
Redux can be overused for local UI state
CRA/react-scripts is a legacy build choice for new applications
browser storage of tokens needs XSS discipline
large SPA bundles need route/component code splitting and performance measurement
```

---

## 9. Alternatives and when to choose them

| Option                    | Better when                                             | Trade-off                                             |
| ------------------------- | ------------------------------------------------------- | ----------------------------------------------------- |
| React + Vite SPA          | modern client-heavy application                         | still needs separate API/auth/SEO design              |
| Next.js                   | SSR/SEO/server rendering/BFF is valuable                | more deployment/rendering complexity                  |
| Feature-local React Query | app has mostly server state, little global client state | adds a different cache convention                     |
| Context only              | small application with simple shared state              | can cause broad rerenders/unclear boundaries at scale |
| Micro-frontends           | independent teams/releases truly need separation        | adds runtime, routing, contract, and UX complexity    |

Strong line:

> “I choose state tools by state type: local component state for temporary UI, RTK Query for server cache, and Redux slices only for shared client workflow state.”

---

## 10. 90-second spoken answer

> “The ROD web application is a React 18 and TypeScript SPA. The entry point composes the Redux provider, browser router, error boundary, localization, analytics, and optional feature infrastructure. `App.tsx` selects public or private routes and applies route-level role checks, while the backend remains the actual authorization boundary.
>
> The UI is organized around pages for route-level features, reusable components and common hooks, typed API contracts, and Redux Toolkit. RTK Query is used for generated/cached API integration, while some feature clients use Axios. The login flow receives a JWT, refresh token, tenant ID, roles, and permissions; the client uses this for session UX and attaches the access token to API calls. On the backend, JWT validation and tenant resolution determine what data the user can actually access.
>
> The design is practical for a workflow-heavy dispatch application. Its next improvements would be standardizing on one server-data access pattern, reducing token exposure in browser storage, and measuring/code-splitting heavy feature routes.”

---

## Rapid cross-questions

| Question                             | Answer                                                                                                                                                           |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Why Redux and Context both exist?    | Redux is for predictable shared app state/server cache integration; Context is suited to narrow cross-cutting state. Neither should replace local state blindly. |
| Does route guard secure an endpoint? | No. It only controls UI navigation; API authorization is server-side.                                                                                            |
| Why RTK Query?                       | It provides endpoint hooks, cache, invalidation, loading/error states, and less hand-written request lifecycle code.                                             |
| How do you avoid stale API data?     | Invalidate relevant tags after mutation, refetch on focus/arguments as needed, and make cache ownership explicit.                                                |
| How would you speed a large screen?  | Server pagination/filtering, virtualization, avoid unnecessary global state/rerenders, memoize only after profiling, and code-split heavy routes.                |
