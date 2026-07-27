# 9. Architecture, DevOps, Git, and Collaboration

## Practical architecture

```text
Frontend modules
  → typed API boundary
  → backend use cases
  → domain/persistence
  → external infrastructure
```

> A good full-stack boundary prevents React components from knowing database details and prevents backend domain logic from depending on UI behavior. The API contract is the explicit bridge.

## Modular monolith

> ROD is deployed as a larger application with separated business areas rather than a set of independently deployed microservices. A modular monolith keeps simpler operations while allowing boundaries around shipments, drivers, tenant management, reports, and integrations. Microservices are justified by real scaling, ownership, or deployment needs—not fashion.

## SOLID across the stack

- **Single responsibility:** component renders one concern; service coordinates one use case.
- **Open/closed:** add a provider/strategy without rewriting stable orchestration.
- **Liskov:** implementations preserve their contract.
- **Interface segregation:** focused props and service interfaces.
- **Dependency inversion:** application logic depends on abstractions, infrastructure supplies implementations.

## Azure deployment view

```text
pull request
  → lint / type-check
  → frontend tests
  → .NET build and tests
  → frontend production build
  → backend artifact/container
  → deploy non-production
  → smoke tests
  → approval / production
  → monitoring
```

`dm-web` includes an Azure Static Web App pipeline. `dm-api` includes Docker/deployment configuration and Azure-oriented backend services.

## Frontend build

> A production React build bundles and minifies assets, uses content hashes for caching, and emits static files. Environment-specific API configuration should be supplied through controlled build/deployment configuration. Secrets must not be placed in frontend environment variables because browser code is visible to users.

## Cache and deployment failure

> After a frontend deployment, a user may have an old HTML page referring to removed hashed chunks. The application includes chunk-error handling. Safe deployments retain compatible assets long enough, use correct cache headers, and provide reload/fallback behavior.

## Docker backend

> A multi-stage Dockerfile builds with the SDK image and runs with a smaller ASP.NET runtime image. Do not bake secrets into layers. Run as non-root where possible, expose health checks, log to standard output, and support graceful shutdown.

## Git workflow

```text
sync branch
  → focused implementation
  → local lint/test/build
  → clear commit
  → pull request
  → review and CI
  → address feedback
  → merge/release
```

### Useful commands

```bash
git status
git diff
git log --oneline --decorate -10
git switch -c feature/attachment-reliability
git add path/to/file
git commit -m "fix: handle attachment upload failure"
```

> Keep commits focused and avoid mixing formatting or unrelated changes. Never rewrite shared history casually.

## Code review answer

> I review behavior first: requirement, edge cases, authorization, tenant isolation, and failure paths. Then I review readability, tests, performance, API compatibility, and observability. I keep comments specific and explain the risk or alternative, not only a preference.

## Cross-functional collaboration

Use **C-L-E-A-R**:

- **C - Clarify** business behavior and acceptance criteria.
- **L - Lock** the API contract and ownership.
- **E - Enumerate** success, empty, validation, auth, conflict, failure.
- **A - Align** rollout, feature flags, and compatibility.
- **R - Review** metrics, bugs, and lessons after release.

## Production support answer

> I identify impact and recent changes, use browser evidence plus backend correlation/logs, mitigate safely, and communicate status without guessing. After recovery, I add a regression test or monitoring signal and document the root cause. For data correction, I use reviewed, reversible, tenant-scoped operations.

## Architecture honesty

> I contributed within an existing multi-tenant layered system. I can explain the architecture and trade-offs, but I do not claim sole authorship of the complete frontend, backend, or deployment design.

