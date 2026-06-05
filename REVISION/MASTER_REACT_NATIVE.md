# Fundamentals

- React decides what the UI should be; React Native commits it to native iOS/Android views.
- Render calculates the next tree. Commit applies changes.
- State is a snapshot inside the current render.
- Component identity = type + position + key.
- `useEffect` is component lifecycle. `useFocusEffect` is navigation focus lifecycle.
- FlatList is virtualized. ScrollView renders everything.
- RN performance has JS thread and UI thread symptoms.

# Frequently Asked Questions

## What happens when state changes?

React schedules an update, reruns the component, reconciles old/new trees, and RN renderer commits native view changes.

## Why does `setCount(count + 1)` three times give +1?

`count` is the same snapshot in that render. Use `setCount(c => c + 1)` when next state depends on previous state.

## Why avoid index keys?

Index keys make identity follow position. Insert/delete/reorder can move TextInput state, selected row, expanded row, or animation state to the wrong item.

## useEffect vs useFocusEffect

- `useEffect`: mount/dependency/unmount lifecycle.
- `useFocusEffect`: screen focus/blur lifecycle.
- Use focus effect for refetch/subscription when returning to screen.

## React.memo vs useMemo vs useCallback

- React.memo: memoize component render by shallow props.
- useMemo: cache calculated value/reference.
- useCallback: cache function reference.
- Do not memoize blindly. Identify the rerender source.

# Production Scenarios

## Screen refetch on return

Use `useFocusEffect` with `useCallback`, cleanup on blur, and avoid large route params. Pass ID and fetch inside screen.

## Slow FlatList

Check stable keys, heavy rows, image sizes, memoized row, stable `renderItem`, stable callbacks, `extraData`, `getItemLayout`, pagination, and batching/window props.

## Offline form submission

Store local draft, queue mutation when offline, replay when online, make server operation idempotent, show sync status, and roll back optimistic UI on failure.

## Auth flow

Login -> receive token -> store securely -> attach auth header centrally -> refresh on expiry/401 -> logout/clear secure storage if refresh fails.

## Release crash

Reproduce in release mode, capture crash logs, use source maps/symbolication, inspect native module permissions/config, and compare device/OS-specific behavior.

# Performance Concepts

- JS thread busy: delayed press/input, late state update, JS animation freeze.
- UI thread busy: scroll jank, layout/image/rendering stutter.
- FlatList tuning only helps after row identity/render cost is sane.
- Context changes rerender consumers; split contexts and memoize provider value.
- Large JSON parsing and heavy filtering block JS thread.
- Debounce search, use server-side search, or memoize derived lists.
- New architecture/Fabric/JSI helps communication, not bad JS or huge rerender storms.
- Test performance in release mode; dev mode lies.

# Edge Cases

- `useEffect([])` does not rerun when returning to an already mounted screen.
- Missing cleanup leaks timers/listeners/subscriptions.
- Inline functions/objects can break memoized rows.
- `extraData` is needed when row UI depends on external state outside `data`.
- AsyncStorage is not encrypted; tokens need secure storage.
- Deep links should not contain tokens/secrets.
- Offline retries can duplicate writes unless idempotent.
- Native permissions differ across iOS/Android and OS versions.
- `new` beats `bind` for constructor `this` in JavaScript.
- Arrow functions ignore bind/call/apply for `this`.

# Tricky Questions

## Is React Native same as React Web?

Same React mental model, different renderer. Web commits to DOM. RN commits to native views.

## Does useCallback make code faster?

It stabilizes function identity. It does not make the function body faster.

## Is Context a global store?

No. It avoids prop drilling but consumers rerender when provider value changes. Keep fast-changing screen state local.

## Can Fabric fix app lag?

Not if the bottleneck is heavy JS, bad list rows, huge parsing, too many rerenders, or images/layout cost.

## Why not store everything in Redux?

Server state, UI state, auth state, offline cache, and form state have different lifecycles. Use the right owner.

# Syntax Refreshers

```tsx
setCount(current => current + 1);
```

```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount(c => c + 1);
  }, 1000);

  return () => clearInterval(id);
}, []);
```

```tsx
useFocusEffect(
  React.useCallback(() => {
    fetchLoads();
    return () => cleanup();
  }, [driverId])
);
```

```tsx
const renderItem = useCallback(
  ({ item }) => (
    <DriverRow
      driver={item}
      isSelected={item.id === selectedDriverId}
      onSelect={handleSelect}
    />
  ),
  [selectedDriverId, handleSelect]
);
```

```tsx
<FlatList
  data={drivers}
  keyExtractor={item => item.id}
  renderItem={renderItem}
  extraData={selectedDriverId}
/>
```

# Real Project Examples

- Driver/load screens: refetch on focus, not only mount.
- Shipment lists: stable keys, pagination, memoized row, and API-side filtering.
- Auth/session: JWT stored in secure storage, attached centrally, 401 handled with refresh/logout.
- Offline driver workflow: cache last useful data, queue mutations, replay safely when online.
- Mobile debugging: reproduce on real device/release build, inspect logs/network/native permission state.

# 30-Minute Rapid Revision

1. Render vs commit.
2. State snapshot and functional update.
3. Keys and identity bugs.
4. useEffect vs useFocusEffect.
5. FlatList optimization checklist.
6. React.memo/useMemo/useCallback.
7. JS thread vs UI thread symptoms.
8. Secure token storage.
9. Offline mutation replay and idempotency.
10. Release symbolication and real-device testing.

# Questions To Ask Interviewer

- What are the biggest mobile performance issues users report?
- How do you handle offline workflows and retry conflicts?
- What state/server-cache libraries are used?
- How do you test release builds and native integrations?
- What crash/analytics tooling is in place?
