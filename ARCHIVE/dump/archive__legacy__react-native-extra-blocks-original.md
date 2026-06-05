## **Block 9 – Navigation & Screen Lifecycle**

- **Different lifecycles:** A screen can remain mounted but not focused. React components mount/update/unmount; navigation focus adds another layer. When navigating away, the component may not unmount—`useEffect(() => {…}, [])` does not re‑run when you return.
- **`useEffect`\*\*** vs \*\* **`useFocusEffect`** **:**
  - `useEffect` runs after the component mounts and when dependencies change; it is tied to component existence.
  - `useFocusEffect` (from React Navigation) runs when the screen gains focus and stops when it blurs. Wrap the callback in `React.useCallback` with dependencies; the effect runs on initial focus and whenever those dependencies change .
  - Use `useFocusEffect` for tasks that need to run every time the user returns to a screen (refetching data, subscribing/unsubscribing). Use `useEffect` for one‑time setup tied to mounting.
- **Useful hooks:**
  - `useIsFocused` returns a boolean indicating whether the screen is focused—handy for conditionally rendering expensive components (maps, cameras).
- **Navigation actions:**
  - `navigate('Route', params)`: navigate to a route (reuses an existing route if present).
  - `push('Route', params)`: always pushes a new instance of the screen onto the stack.
  - `replace('Route', params)`: swaps the current screen.
  - `goBack()`: pops the current screen.
  - `reset(state)`: replaces the entire navigation state—useful for logout or multi‑step wizards.
- **Pitfalls:**
  - Expecting `useEffect([])` to refetch when returning to a screen—use `useFocusEffect` or `useIsFocused` instead.
  - Forgetting to wrap `useFocusEffect` in `React.useCallback`—otherwise it runs on every render .
  - Leaving subscriptions or timers active when a screen blurs—return a cleanup function in `useFocusEffect`.
  - Passing large objects in route params—pass an ID and fetch data inside the screen instead.

---

## **Block 10 – API Integration, Authentication & Offline Patterns**

### **API client & error handling**

- **Centralize your API:** Create a single client (e.g., Axios wrapper) for base URL, auth headers and unified error handling instead of scattering fetch logic across components.
- **Use server‑state libraries:** TanStack Query manages fetching, caching, background refetching and stale‑while‑revalidate. Persist its cache to disk with `@tanstack/query-async-storage-persister` so the last data is available offline .
- **Error boundaries:** Wrap your app in an error boundary to catch unexpected JS errors and show a fallback UI instead of crashing.
- **Graceful errors:** Model API requests with loading, success, error and empty states; use retry/backoff; show user‑friendly messages.

### **Authentication & secure storage**

- **Don’t embed secrets in code:** Store API keys/secrets on a backend or via environment variables .
- **Use secure storage for tokens:** AsyncStorage is not encrypted; store tokens in Keychain (iOS) or Encrypted Shared Preferences (Android). Libraries like `expo-secure-store` and `react-native-keychain` provide unified access .
- **Auth flow:** On login, obtain JWT tokens; store them securely; refresh tokens when needed; attach the access token via interceptors; handle 401 responses by refreshing or logging out.
- **Avoid secrets in deep links:** Never put tokens or secrets in deep links because custom URL schemes can be hijacked .

### **Offline caching & data persistence**

- **Multi‑layer caching:** Implement memory cache, persistent storage and network fetch. A `CacheClient` fetches from memory first, then AsyncStorage/MMKV, then network. Use NetInfo to detect connectivity; if offline, return cached data; if online, use stale‑while‑revalidate .
- **React Query persistence:** Persist only small datasets (user profiles, settings) and not large paginated lists .
- **Offline queue for mutations:** When offline, enqueue mutations (POST/PUT/DELETE) in AsyncStorage and replay them when connectivity is restored .
- **Optimistic updates:** Update the UI immediately as if the server accepted the change; roll back if it fails. TanStack Query’s `onMutate` and `onError` callbacks support this.
- **Sync flags:** Mark cache entries with `maxAge` or `staleWhileRevalidate` to decide when to fetch fresh data or rely on cached data.

### **State separation**

- Separate server‑fetched data (queries) from UI state (inputs, modals) and offline caches. Don’t store everything in Redux or context; use TanStack Query for API data and a simple state library (e.g., Zustand, Redux Toolkit) for UI state .

---

## **Block 11 – Debugging, Builds & Release Practices**

### **Developer menu & DevTools**

- **Dev Menu:** Shake the device or press `Cmd+M` on Android / `Ctrl+Cmd+Z` on iOS to open the developer menu . From there you can reload the app, toggle hot reload or the performance monitor, and open debugging tools.
- **React Native DevTools:** Open via “Debug with Chrome” or a separate tab. It provides console logs, network inspector, and component tree inspection . It complements but doesn’t replace native debuggers .
- **LogBox:** Shows fatal errors (red boxes) and warnings (yellow boxes). You can suppress noisy logs globally or by pattern (`LogBox.ignoreAllLogs()` or `LogBox.ignoreLogs([...])`) .

### **Performance monitor**

- Toggle **Perf Monitor** in the Dev Menu to overlay JS and UI frame rates . Dropped JS frames mean heavy JavaScript work; dropped UI frames mean heavy native rendering. Native stack transitions run on the main thread and aren’t limited by JS frame rate .
- Always test performance in release mode; development mode adds overhead. Remove `console.log` calls with a Babel plugin for production .

### **Debugging release builds & symbolication**

- Release builds minify JS; stack traces are unreadable.
  1. **Enable source maps** during the build (Hermes flags for Android; `SOURCEMAP_FILE` for iOS) .
  2. **Capture the crash log** from a crash reporting service.
  3. **Run \*\***`metro-symbolicate`\*\* with the crash log and the source map to translate stack traces .
- Use the decoded stack trace to find the offending JS line.

### **Release checklist**

- Remove dev features: disable debugging and hot reload; remove console logs using `transform-remove-console` .
- Test on real devices (especially older hardware and poor connectivity).
- Ensure tokens and sensitive data are stored securely (Keychain/Encrypted Shared Preferences) .
- Monitor crashes with tools like Sentry or Crashlytics and symbolicate stack traces.
- Verify third‑party modules in release builds (push notifications, deep links, purchases).

### **Quick reference**

| **Aspect**          | **Guidance**                                                                                   |
| ------------------- | ---------------------------------------------------------------------------------------------- |
| Screen lifecycle    | `useEffect`for mount,`useFocusEffect`for navigation focus .                                    |
| Secure tokens       | Never store tokens in AsyncStorage; use secure storage .                                       |
| Offline data        | Multi‑layer caching, offline queues and selective persistence .                                |
| Dev menu            | Shake device or use keyboard shortcuts to open; access hot reload, Perf Monitor and DevTools . |
| LogBox              | Displays errors/warnings; can ignore specific logs .                                           |
| Performance testing | Measure in release builds; remove console logs .                                               |
| Symbolication       | Enable source maps and run `metro-symbolicate`.                                                |
| React Query         | Use for API caching and stale‑while‑revalidate .                                               |
