# React Native Revision

## Must-Say Lines

- React decides the UI tree; React Native commits changes to native iOS/Android views.
- Render calculates the next tree; commit applies required changes.
- State is a snapshot inside the current render.
- Component identity is type + position + key.
- Index keys make identity follow position and can move row state to the wrong item.
- `useEffect` is component lifecycle; `useFocusEffect` is navigation focus lifecycle.
- FlatList performance starts with stable keys, memoized rows, stable callbacks, `extraData`, and measurement/window tuning.

## Render, State, Identity

State change flow:

```text
setState -> React schedules update -> component function runs -> reconcile -> RN renderer commits native view changes
```

Edge cases:

- `setCount(count + 1)` does not mutate `count` immediately.
- Three `setCount(count + 1)` calls can still produce only +1.
- Use functional updates when next state depends on previous state.
- Do not mutate arrays/objects in state; return new references.

Strong answer:

```text
React state is a snapshot for one render. The setter schedules the next render. If I need the latest queued value, I use functional updater form.
```

## Effects And Closures

Use `useEffect` for external synchronization:

- API calls.
- Timers.
- Subscriptions.
- Native listeners.
- AppState/NetInfo.
- Storage.

Cleanup:

- Runs before effect reruns.
- Runs on unmount.

Stale closure:

```text
A callback remembers values from the render where it was created. Fix with correct dependencies, functional updates, or refs when appropriate.
```

Edge cases:

- Empty dependency array means mount/unmount lifecycle, not "always latest state".
- Missing cleanup leaks timers/listeners.
- Too many dependencies can indicate mixed responsibilities.

## Navigation Lifecycle

Core distinction:

```text
Component lifecycle: mount -> render -> effect -> unmount
Navigation lifecycle: focus -> blur -> sometimes unmount
```

Rules:

- A screen can remain mounted while unfocused.
- `useEffect([])` does not rerun just because user returns to a screen.
- Use `useFocusEffect` for refetch/subscription while screen is visible.
- Wrap `useFocusEffect` callback in `useCallback`.
- Use `useIsFocused` to pause expensive rendering.

Navigation actions:

- `navigate`: go to route, may reuse existing route.
- `push`: add another instance.
- `replace`: replace current screen.
- `goBack`: pop.
- `reset`: replace navigation state.

## FlatList And Performance

Checklist:

1. Stable `keyExtractor` from item ID.
2. Avoid index key for dynamic lists.
3. Use `extraData` when row UI depends on external state.
4. Memoize heavy row components with `React.memo`.
5. Stabilize `renderItem` and callbacks when they affect memoized rows.
6. Use `getItemLayout` for fixed-height rows.
7. Tune `initialNumToRender`, `maxToRenderPerBatch`, `windowSize` after measuring.
8. Paginate large data.

Edge cases:

- `ScrollView` renders everything; FlatList virtualizes.
- New inline object/function props can break memo.
- `extraData` is not a replacement for immutable `data` updates.

## Context And Memo

- `React.memo`: skip child render if shallow props are same.
- `useMemo`: cache calculated value/object reference.
- `useCallback`: cache function reference.
- Context is for shared stable app state, not every screen input.

Edge cases:

- Provider value `{ user, login }` is a new object every render unless memoized.
- Splitting context by responsibility reduces broad rerenders.
- Memoization does not fix bad data flow or expensive global state updates.

## API, Auth, Offline, Release

API:

- Centralize client/auth headers/error shape.
- Separate server state from UI state.
- Use query/cache libraries for fetched data when available.

Auth:

- Store tokens in secure storage, not plain AsyncStorage.
- Handle 401 refresh/logout centrally.
- Never place secrets in deep links.

Offline:

- Cache small critical datasets.
- Queue offline mutations and replay when online.
- Make replay idempotent.
- Roll back optimistic updates on failure.

Release/debugging:

- Test performance in release mode.
- Remove noisy console logs.
- Symbolicate minified crash stacks with source maps.
- Monitor crashes with Sentry/Crashlytics-style tooling.

## RN Performance Diagnosis

| Symptom | First suspicion |
| --- | --- |
| Button/input delay | JS thread busy. |
| Scroll jank | Heavy rows, layout/images, UI thread pressure. |
| Search lag | Large filtering per keystroke. |
| Screen startup slow | Heavy imports, mount work, large JSON/data parsing. |

Common questions:

- React Web vs React Native?
- What happens when state changes?
- Why avoid index keys?
- `useEffect` vs `useFocusEffect`?
- How do you optimize a FlatList?
- What is stale closure?
