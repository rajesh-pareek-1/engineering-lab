# High-End Topic 07 — JWT Authentication and Authorization in ROD

> **Goal:** Explain login → token → request validation → tenant context → roles/permissions → refresh flow, using ROD’s real classes and without saying JWT is encrypted.

---

## One-line answer

> **“ROD authenticates users by validating credentials and issuing a signed JWT containing identity, tenant, role, and scope claims. ASP.NET Core validates that token on every protected request, `RequestContext` extracts trusted tenant identity, and endpoint attributes enforce role or permission authorization.”**

```text
Login credentials prove identity once
        ↓
signed short-lived JWT proves identity on API calls
        ↓
roles/permissions decide allowed action
        ↓
tenant claim selects allowed data boundary
```

---

## 1. Important vocabulary

```text
Authentication = Who are you?
Authorization  = Are you allowed to do this action?
Tenancy        = Which customer’s data boundary applies?

401 = unauthenticated: missing, invalid, expired, or unusable token
403 = authenticated but forbidden: valid identity lacks required role/permission
```

```text
JWT is signed, not encrypted.
Claims are readable by the client, but payload tampering invalidates the signature.
```

---

## 2. ROD login flow

```text
Web/mobile sends Basic credentials over HTTPS for the login endpoint
        ↓
TenantManagement/Controllers/AuthController.cs
  AuthToken()
  • decodes Basic username:password
  • calls IAuthService.Authenticate(...)
        ↓
TenantManagement/Services/AuthService.cs
  Authenticate(username, password)
  → ValiateCredentials(...)
        ↓
User repository loads user and related roles/accounts
        ↓
password hash is compared
        ↓
IssueAuthToken(user)
        ↓
LoginResponse
  access token + refresh token + refresh expiry
  tenant ID + roles + permissions + module data
        ↓
client stores session appropriately and sends Bearer token on protected requests
```

The login endpoint is `[AllowAnonymous]`; that is correct because it is the endpoint that establishes identity. Its protection must come from HTTPS, rate limiting, password-hash verification, monitoring, and brute-force controls—not a pre-existing JWT.

---

## 3. Token creation in ROD

`AuthService.IssueAuthToken` creates a `JwtSecurityToken` using a symmetric HMAC SHA-512 signing key derived from the protected application secret.

```csharp
var tokenDescriptor = new SecurityTokenDescriptor
{
    Subject = GenClaimsIdentity(user, account, transientScopes),
    IssuedAt = DateTime.UtcNow,
    Expires = DateTime.UtcNow.AddDays(1),
    SigningCredentials = new SigningCredentials(
        new SymmetricSecurityKey(key),
        SecurityAlgorithms.HmacSha512Signature),
    Issuer = _config["JwtConfig:Issuer"],
    Audience = _config["JwtConfig:Audience"]
};
```

Claims created by `GenClaimsIdentity` include:

```text
email                → user identity/display
sub                  → user ID
tid                  → tenant ID
org                  → selected account/organization where applicable
role                 → role(s)
scope                → scope(s), including transient scope where relevant
```

The access token lifetime in this source is one day. The refresh token expiry is configured as seven days.

---

## 4. Real protected-request flow

```text
Client request
Authorization: Bearer eyJ...
        ↓
RollOnDispatch/Startup.cs
  app.UseAuthentication()
        ↓
JWT bearer middleware
  validates signing key
  validates issuer
  validates audience
  validates lifetime
  uses zero clock skew in current configuration
        ↓
HttpContext.User becomes authenticated ClaimsPrincipal
        ↓
app.UseAuthorization()
        ↓
Endpoint attributes
  [Authorize]
  [AuthorizeRoles(...)]
  [CustomAuthorize(Permissions.X)]
        ↓
Controller/service/repository DI activation
        ↓
TenantManagement/Common/RequestContext.cs
  extracts TenantId, user ID, username, roles, scopes
        ↓
ITenantDbContextFactory
  creates correct tenant RollOnDispatchContext
        ↓
business operation executes
```

### File-and-method map — build a shipment

```text
POST /api/Shipment
        ↓
RollOnDispatch/Startup.cs
  UseAuthentication → UseAuthorization
        ↓
RollOnDispatch/Controllers/ShipmentController.cs
  [CustomAuthorize(BUILD_SHIPMENT)]
  Add(ShipmentRequestModel)
        ↓
TenantManagement/Extensions/CustomAuthorize.cs
  OnAuthorization(...)
  → reads role claim
  → IRolePermissionsService.HasPermission(role, BUILD_SHIPMENT)
  → ForbidResult if not allowed
        ↓
RollOnDispatch/Services/ShipmentService.cs
        ↓
tenant-aware repository
        ↓
TenantDbContextFactory → tenant SQL database
```

---

## 5. Authentication, authorization, and tenant isolation work together

```text
Valid token?
        ↓ no
401 Unauthorized

Valid token, but missing role/permission?
        ↓
403 Forbidden

Valid token and permission?
        ↓
RequestContext reads trusted tenant claim
        ↓
Tenant factory connects only to that tenant database
```

Example:

```text
Dispatcher from Tenant A
has BUILD_SHIPMENT permission
        ↓
can build shipment in Tenant A database

The same user cannot select Tenant B through request body/query string,
because database selection comes from the validated tenant claim.
```

---

## 6. What if someone changes the JWT tenant ID?

```text
JWT format
header.payload.signature

Attacker changes tid in payload
header.changed-payload.old-signature
        ↓
middleware validates signature using server key
        ↓
signature mismatch
        ↓
authentication fails before controller executes
        ↓
401 Unauthorized
```

```text
Changed claim in JWT        → invalid signature → 401
Changed tenantId in body    → ignored for database selection
Valid stolen token          → works until expiry/revocation unless additional controls exist
Leaked signing secret       → critical: attacker can forge valid JWTs
```

Correct interview sentence:

> “The JWT payload is readable, but it is integrity-protected by the signature. Any claim change—including tenant ID—invalidates the signature unless the attacker has the signing key.”

---

## 7. Refresh-token flow in ROD

```text
Access token expires / client needs renewed session
        ↓
GET /api/Auth/refresh
Authorization: Basic base64(username:refreshToken)
        ↓
AuthController.RefreshToken()
        ↓
AuthService.RefreshAuthToken(username, refreshToken)
        ↓
load user
compare stored refresh token and expiry
        ↓ valid
IssueAuthToken(user)
        ↓
new JWT + new refresh token + new expiry
        ↓
User row is updated
```

The refresh token is effectively rotated because `IssueAuthToken` creates a new refresh value and updates the user record.

Client behavior should be:

```text
API returns 401
        ↓
attempt refresh once
        ↓ valid
retry original request once
        ↓ refresh fails
clear session and sign in again
```

Avoid a refresh storm when many parallel requests get 401: use one shared refresh promise/lock on the client, then let other failed calls await it.

---

## 8. Other authentication mechanisms in ROD and the wider world

ROD also registers a named `ApiKeyAuthentication` scheme for integration/service-style calls. That is different from an end-user browser/mobile JWT session.

| Mechanism | Good fit | Key caution |
|---|---|---|
| JWT bearer token | SPA/mobile API session | expiry, refresh, secure storage, key rotation |
| Cookie session | same-site browser/server-rendered app | CSRF protection, cookie flags |
| OAuth 2.0 + OpenID Connect | external identity provider/SSO/delegated access | validate issuer, redirect URI, PKCE, scopes |
| API key | server-to-server/simple integration | scope, rotation, hashing, never use as a human login |
| mTLS | strong machine-to-machine identity | certificate lifecycle/rotation |
| Client credentials OAuth | service identity via identity provider | least-privilege scopes and secret/certificate storage |

Strong answer:

> “JWT is a token format, not a complete identity system. For enterprise SSO I would usually use OpenID Connect for login and OAuth 2.0 access tokens, then validate issuer, audience, scopes, and tenant mapping in the API.”

---

## 9. Security hardening and improvements

```text
Signing key
→ store in Azure Key Vault or managed secret store
→ rotate keys; never source-control it

Transport
→ HTTPS everywhere; never use Basic auth over HTTP

Access tokens
→ shorter lifetime reduces theft window

Refresh tokens
→ rotate; revoke on logout/password change/suspicious use
→ ideally store a hash plus device/session metadata, not only one raw value per user

Brute-force protection
→ rate limit login and refresh endpoints
→ login failure audit/lockout policy appropriate to product

Authorization
→ validate both identity and permission; do not trust frontend route guards

Tenancy
→ derive tenant from signed claim/server-side membership, not request input
```

### A thoughtful “what would you redesign?” answer

> “I would preserve the current claim-based tenant flow, but modernize credential handling: secrets in Key Vault, strict HTTPS, short access lifetime, refresh-token family/session tracking with rotation and replay detection, and OpenID Connect if SSO or external identity becomes a core requirement. I would also make every authorization decision policy/permission based and audit security-sensitive failures.”

---

## 10. How web and mobile clients participate

```text
dm-web
→ login obtains JWT/refresh/roles/tenant data
→ attaches Bearer token to API calls
→ uses route/role checks for UX

dm-driver-mobile-app
→ persists session in Keychain/Keystore-backed storage
→ Axios attaches Bearer token
→ refreshes once on 401, then clears session if refresh is invalid

Both clients
→ may display roles/tenant from response
→ never become the authority for API authorization or tenant DB selection
```

---

## 11. 90-second spoken answer

> “ROD’s authentication starts at the Auth controller. The login endpoint receives credentials over HTTPS, passes them to `AuthService`, and validates the password hash against the user record. On success, `IssueAuthToken` creates an HMAC SHA-512 signed JWT with email, user ID, tenant ID, roles, scopes, and optional account context. It also returns a refresh token with a longer expiry.
>
> On every protected request, ASP.NET Core JWT bearer middleware validates the signing key, issuer, audience, and expiry. If that fails, the request gets 401 before the controller executes. If the token is valid, authorization attributes check roles or specific permissions. For example, `CustomAuthorize` asks the role-permission service whether the role can perform a specific action; a valid user without that permission receives 403.
>
> After authentication, `RequestContext` extracts the trusted tenant claim. `ITenantDbContextFactory` then creates the EF Core context for that tenant’s database, which connects authentication to tenant isolation. For expired access tokens, the client calls the refresh endpoint with username and refresh token; the service validates it, issues a new token pair, and updates the stored refresh token.”

---

## Rapid cross-questions

| Question | Answer |
|---|---|
| Why is JWT not encrypted? | It is usually signed for integrity. Sensitive data should not be put in claims; use JWE only when encryption is required. |
| 401 versus 403? | 401 means the API cannot authenticate the caller; 403 means it authenticated them but they lack permission. |
| Why have a refresh token? | Keep access token short-lived while allowing a controlled session renewal without prompting login every time. |
| What if a role changes while a JWT is active? | Token claims may be stale until refresh/expiry. For high-risk actions use short lifetimes, version/revocation checks, or fetch current authorization policy data. |
| Does a valid JWT guarantee tenant access? | It proves identity and carries tenant context, but endpoint permissions and tenant-aware data access still apply. |
| How would you handle SSO? | Use OIDC authorization code flow with PKCE for client login and validate OAuth access tokens/scopes in the API. |
