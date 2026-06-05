# React Native API, Auth, Offline, And Release Notes

Merged from the non-navigation parts of the legacy extra React Native blocks. The duplicate navigation lifecycle section was removed from the active copy because `react-navigation-screen-lifecycle.md` is now the canonical source.

## API Client And Errors

- Centralize API access in one client for base URL, auth headers, and error handling.
- Use server-state tooling such as TanStack Query when available for caching, background refetch, and stale-while-revalidate.
- Model loading, success, empty, and error states explicitly.
- Use retries/backoff carefully and avoid retrying unsafe mutations without idempotency.

## Authentication And Secure Storage

- Do not embed secrets in app code.
- Store tokens in Keychain/Encrypted Shared Preferences through secure storage libraries.
- AsyncStorage is not encrypted.
- Attach access tokens centrally through request interceptors/client wrapper.
- Handle 401 by refresh or logout flow.
- Do not put secrets in deep links.

## Offline Data

- Separate server state, UI state, and offline persistence.
- Cache small useful datasets, not huge paginated lists by default.
- Use NetInfo/connectivity checks to decide offline behavior.
- Queue offline mutations and replay when online.
- Use optimistic updates only with rollback behavior.
- Mark cache freshness with max age/stale-while-revalidate rules.

## Debugging And Release

- Dev Menu gives reload, debugging, and performance monitor access.
- LogBox surfaces fatal errors and warnings.
- Perf Monitor helps separate JS and UI frame symptoms.
- Test performance in release builds because dev mode adds overhead.
- Remove noisy `console.log` calls for production.
- Enable source maps and symbolicate minified crash stacks.
- Monitor release crashes with Sentry/Crashlytics-style tooling.

## Interview Edge Cases

- Secure storage protects tokens better than AsyncStorage, but backend token design still matters.
- Offline replay must be idempotent to avoid duplicate writes.
- Background refetch can show stale data temporarily; the UI should make loading/error states clear.
- Native permissions, deep links, and push notifications must be tested on real devices.
