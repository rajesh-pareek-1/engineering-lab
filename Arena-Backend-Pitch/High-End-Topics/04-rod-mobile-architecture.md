# High-End Topic 04 — ROD Driver Mobile Architecture

> **Scope:** `dm-driver-mobile-app`, the React Native driver application—not the dispatch-manager web SPA.

---

## Architecture in one sentence

> **“The ROD driver app is a React Native + TypeScript application organized around screens, reusable components, hooks, navigation, context providers, and service-layer API clients; it combines secure session storage with device capabilities such as location, documents, push notifications, and native iOS/Android builds.”**

```text
iOS / Android native shell
        ↓
React Native app providers + navigation
        ↓
screens → hooks/components
        ↓
service-layer API clients + Axios
        ↓ Bearer JWT / multipart upload
ROD ASP.NET Core backend
        ↓
SQL tenant database, Blob storage, notification services
```

---

## 1. Repository map and responsibility

```text
dm-driver-mobile-app/
├── android/                       native Android project/configuration
├── ios/                           native iOS/Xcode project/configuration
├── src/
│   ├── App.tsx                    app composition
│   ├── navigation/                routes, bottom tabs, drawer/navigation rules
│   ├── screens/                   route-level driver experiences
│   ├── components/                reusable visual building blocks
│   ├── hooks/                     reusable device/UI behavior
│   ├── context/                   auth, loading, analytics, localization state
│   ├── services/                  API clients and device/domain services
│   ├── services/api/              endpoint-specific clients and interfaces
│   ├── services/geofencing/       location/geofence processing and queues
│   ├── utils/                     keychain, validation, permissions, helpers
│   ├── constants/                 routes, endpoint paths, labels, storage keys
│   ├── types/                     TypeScript contracts
│   ├── theme/ and styles/         tokens and common styling
│   ├── localization/              English/Spanish translations
│   └── assets/                    images, fonts, animations
├── __tests__/                     Jest tests
└── .azuredevops/                  Azure DevOps pipeline/support configuration
```

```text
screens      = user journeys: login, dashboard, shipments, documents, check-in
components   = shared reusable visual pieces
hooks        = screen behavior separated from rendering
context      = narrow app-wide state such as auth/loading/localization
services     = backend/device integration boundary
navigation   = which screen is available and how users move
native dirs  = iOS/Android capabilities, signing, build configuration
```

---

## 2. Application composition

`src/App.tsx` is intentionally small:

```text
NativeBaseProvider
        ↓
ApiLoadingProvider
        ↓
AuthProvider
        ↓
Routes
        ↓
location-permission modal / permission modal / optional geofence debug overlay
```

This keeps global infrastructure at the root instead of every screen implementing it separately.

```text
NativeBaseProvider  → shared mobile UI/theme primitives
AuthProvider        → secure session/bootstrap state
ApiLoadingProvider  → API loading coordination
Routes              → public/private navigation
```

---

## 3. Navigation architecture

```text
navigation/Routes.tsx
        ↓
auth state decides public vs authenticated stack
        ↓
drawer navigation / bottom tab navigation
        ↓
screen
        ↓
screen hooks + services
```

The repo uses React Navigation native stack, drawer, and bottom-tab packages. Navigation is a UX boundary, not API security.

```text
Mobile UI can hide a screen
but backend JWT/roles/tenant isolation must still reject a forbidden API request.
```

---

## 4. Authentication and session recovery flow

```text
Login screen/hook
        ↓
services/api/authentication/authentication.ts
        ↓
Axios call to ROD auth endpoint
        ↓
JWT + refresh token + tenant/roles returned
        ↓
persistAuthSession(...)
        ↓
react-native-keychain secure storage
        ↓
AuthContext updates → authenticated navigation
```

On startup:

```text
AuthProvider.loadUserData()
        ↓
first launch? clear stale credentials
        ↓
getAuthData() from Keychain
        ↓
refreshAuthSession(...)
        ↓
persist rotated/current session
        ↓
render authenticated or public routes
```

Why Keychain matters:

```text
Web localStorage = JavaScript-accessible browser storage
Mobile Keychain/Keystore = OS-backed secure credential storage
```

The source retries an API request once after a 401 by refreshing the session; if refresh fails with 401, it clears auth data and returns the user to a signed-out state.

---

## 5. Real mobile API path

```text
Dashboard / shipment / document screen
        ↓
screen hook, for example useDashboard/useUploadDocument
        ↓
services/api/<feature>/<feature>.ts
        ↓
serviceInstance.apiCall(...)
        ↓
Axios instance request interceptor
        ↓
Authorization: Bearer <access token>
        ↓
ROD API
        ↓
response → hook state/context → screen render
```

`serviceInstance.ts` separates normal JSON calls, multipart attachment calls, and Blob/download response calls.

```text
JSON request            → Content-Type: application/json
document upload         → multipart/form-data
file download/preview   → responseType: blob
```

---

## 6. Device-specific responsibilities

| Concern | Source-area responsibility |
|---|---|
| Document capture/upload | document picker, image picker/scanner, image compression/conversion, attachment service |
| Location/check-in | geolocation, permission checks, check-in location API |
| Geofencing | `services/geofencing`, background/headless task, action queue, position watcher |
| Notifications | Firebase messaging, native push libraries, device-registration API, notification UI |
| Secure credentials | `react-native-keychain` helper |
| Maps | native maps/Apple map wrapper/geocoding |
| Analytics | PostHog context/hooks, privacy-aware identification |
| Native builds | `ios/`, `android/`, Fastlane/CI configuration |

Important interview line:

> “React Native shares JavaScript/TypeScript feature code, but permissions, build signing, push registration, background execution, and native SDK behavior still require iOS and Android integration.”

---

## 7. Example: document upload flow

```text
Profile/document screen
        ↓
document-list hook or upload component
        ↓
picker/scanner/image conversion if needed
        ↓
build FormData with file + document metadata
        ↓
customAxiosAttachments(...)
        ↓
multipart request + Bearer token
        ↓
ROD attachment endpoint
        ↓
tenant-aware backend stores metadata + Blob/file content
        ↓
refresh document list / show upload result
```

Why this is structured through services instead of placing Axios in the screen:

```text
screens remain focused on user flow
token/timeout/retry/error behavior is consistent
multipart configuration is not duplicated
service can be unit-tested/mocked more easily
```

---

## 8. Why this architecture fits a driver app

```text
Screens + hooks
→ keeps complex workflow behavior out of JSX/render functions.

Context for auth/loading
→ cross-cutting state without forcing every concern into a global Redux store.

Service layer
→ isolates backend contracts and native integrations.

React Navigation
→ native-feeling stack/tab/drawer flows.

Native modules
→ access camera, GPS, secure keychain, push, background tasks.
```

### Advantages

```text
clear UI/service/device boundaries
secure OS-backed session storage
shared TypeScript code across iOS and Android
API retries/session recovery centralized
feature folders make driver workflows discoverable
native capabilities can be encapsulated behind services
```

### Trade-offs

```text
native dependency upgrades can affect Android and iOS differently
background location/geofencing is complex and battery-sensitive
permission denial must be treated as a real product state
large React Native dependency set requires upgrade/testing discipline
Context can cause broad rerenders if it becomes a dumping ground
```

---

## 9. Other architecture options

| Option | Fits when | Trade-off |
|---|---|---|
| Native iOS + Android apps | platform-specific UX/performance is dominant | two codebases and teams |
| Flutter | organization prefers Dart/rendering model | different ecosystem/team skills |
| Redux Toolkit/Zustand | global client workflow state becomes much larger | more state conventions/boilerplate |
| Feature-based folders with co-located services | teams work independently by feature | can duplicate shared abstractions if undisciplined |
| BFF/mobile API | mobile needs tailored aggregation/offline contracts | another service to own and monitor |

---

## 10. Production and performance thinking

```text
Do not block UI on long file processing → resize/compress/offload where suitable.
Do not make location polling aggressive → preserve battery and respect consent.
Do not retry indefinitely → bounded retry + refresh once + clear failure state.
Do not log tokens/PII/location indiscriminately → redact and apply retention rules.
Do not send every event online immediately → queue safely if offline, deduplicate server-side.
```

Useful metrics:

```text
app startup and time-to-interactive
screen render time / dropped frames
API latency and 401-refresh failures
upload duration/failure rate
crash-free users
location permission and geofence success rate
push registration/delivery rate
```

---

## 11. 90-second spoken answer

> “The ROD driver app is a React Native and TypeScript application supporting both iOS and Android. The root composes UI, loading, and authentication providers, then navigation chooses public or authenticated routes. Screens represent driver workflows such as dashboard, shipment details, check-in, documents, notifications, and profile; hooks hold screen behavior; reusable components handle presentation; and services own API and device integration.
>
> Authentication uses an auth context. A session is persisted through Keychain/Keystore-backed storage, refreshed at startup, and attached as a bearer token by Axios clients. If an API call returns 401, the client attempts one refresh and retries once; if refresh is unauthorized, it clears the session safely.
>
> The app also handles mobile-specific concerns such as multipart document upload, GPS/geofencing, permissions, push notification registration, and native builds. I keep those capabilities behind services so screens remain focused on user flow and the backend remains the source of truth for authorization and tenant data isolation.”

---

## Rapid cross-questions

| Question | Answer |
|---|---|
| Why Keychain instead of AsyncStorage for tokens? | Keychain/Keystore is OS-backed secure storage; AsyncStorage is appropriate for non-sensitive preferences, not long-lived credentials. |
| What happens after access-token expiry? | API gets 401, refreshes once using stored refresh credentials, retries the original call; failed refresh clears auth and signs out. |
| How do you upload a document? | Create `FormData`, use multipart content type, attach bearer token, validate/size-compress client-side as appropriate, then let backend authorize and store it. |
| How do you handle permissions? | Request only when needed, explain why, support denial in UI, re-check on resume, and never assume location/camera access. |
| React Native performance issue? | Profile first with Flipper/native tools, reduce unnecessary rerenders, virtualize long lists, optimize large images, and avoid expensive work on the JS thread. |
