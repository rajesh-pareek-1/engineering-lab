# 6. API Integration, Authentication, and Error Handling

## HTTP flow

```text
UI event
  → typed RTK Query request
  → base URL + JWT header
  → HTTPS
  → ASP.NET Core middleware
  → controller DTO binding
  → authorization + validation
  → service / database
  → status + JSON/ProblemDetails
  → RTK Query success/error state
  → UI feedback
```

## Contract checklist: **R-V-H-B-S-E**

- **R - Route and method.**
- **V - Version and validation.**
- **H - Headers/authentication.**
- **B - Body/query parameters.**
- **S - Success response/status.**
- **E - Error response/status.**

## JWT in dm-web

The root RTK Query base adds a Bearer token from storage or Redux state:

```ts
prepareHeaders: (headers, { getState }) => {
    const token =
        sessionStorage.getItem('token') ??
        localStorage.getItem('token') ??
        (getState() as RootState).auth.signInData.token;

    if (token) {
        headers.set('Authorization', `Bearer ${token}`);
    }

    return headers;
}
```

The backend validates signature, issuer, audience, and expiry, then applies role/policy/resource authorization.

### Security nuance

> `localStorage` and `sessionStorage` are accessible to JavaScript, so an XSS vulnerability can steal tokens. HttpOnly Secure SameSite cookies reduce JavaScript access but require CSRF design. The correct choice depends on architecture and threat model; never claim browser storage is completely secure.

## Authentication vs authorization

> Authentication answers who the user is. Authorization answers whether that user may access this tenant, route, and specific shipment. React route checks improve UX, but only backend authorization provides security.

## Refresh-token flow

```text
access token expires
  → client sends refresh credential
  → server validates session/token
  → new access + rotated refresh token
  → client retries original request once
  → failure clears session and redirects login
```

> Prevent infinite refresh loops. Refresh tokens should be protected, rotated, revocable, and checked for reuse. The client must coordinate simultaneous 401 responses so it does not launch many refresh operations.

## REST status handling

- `200`: successful read/update.
- `201`: created.
- `204`: success without response body.
- `400`: malformed/basic validation.
- `401`: missing/invalid authentication.
- `403`: authenticated but forbidden.
- `404`: resource not found.
- `409`: concurrency/current-state conflict.
- `422`: semantically invalid business request when API convention uses it.
- `500`: unexpected server failure.

## Typed error mapping

```ts
type ApiProblem = {
    title?: string;
    detail?: string;
    traceId?: string;
    errors?: Record<string, string[]>;
};

function getApiMessage(error: unknown): string {
    if (isFetchBaseQueryError(error)) {
        const problem = error.data as ApiProblem | undefined;
        return problem?.detail ?? `Request failed (${error.status})`;
    }

    return 'An unexpected client error occurred';
}
```

> Show a useful message to the user, preserve field errors when available, and keep trace/correlation information for support. Do not display stack traces or raw SQL errors.

## Axios vs RTK Query

The project contains older/custom Axios-style APIs and generated RTK Query endpoints.

> Axios is an HTTP client. RTK Query is server-state and caching tooling that can use a base query. Axios is useful for custom requests or existing wrappers; RTK Query reduces manual caching and loading logic. A migration should be incremental and avoid two competing sources of truth for the same server data.

## File upload

```ts
const body = new FormData();
body.append('file', file);
body.append('type', documentType);

await uploadAttachment({ driverLoadId, body }).unwrap();
```

Important checks:

- client type/size check for UX;
- server type, size, ownership, and content validation;
- safe generated blob name, not trusted path;
- malware scanning if required;
- no sensitive storage URL leakage;
- loading, cancellation, retry, and duplicate handling.

## CORS

> CORS is a browser policy controlling cross-origin frontend calls. It is not authentication. The backend should allow only required origins, headers, and methods. Credentialed requests must not use an unrestricted wildcard origin.

## End-to-end error investigation

> I first inspect the browser network request. If it never fired, I inspect UI validation and event logic. If it fired, I check method, URL, token, payload, status, and response. A 400/422 points toward contract or business validation; 401/403 toward identity/access; 500 toward backend logs using trace ID. Then I trace controller, service, EF SQL, and external dependencies.

