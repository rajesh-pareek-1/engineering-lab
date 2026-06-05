# Block 9: React Navigation + Screen Lifecycle

Goal: understand navigation as mobile state, not web page reloads.

## Core map

```text
React component lifecycle = mount -> render -> effect -> unmount
Navigation lifecycle      = focus -> blur -> sometimes unmount
```

A screen can be mounted but not focused.

## Main rule

```text
Navigating away does not always unmount the previous screen.
```

This is why:

```tsx
useEffect(() => {
  fetchData();
}, []);
```

runs once on mount, but does not automatically run every time the user returns to the screen.

## useEffect vs useFocusEffect

`useEffect` is component lifecycle:

```text
runs after mount/commit and dependency changes
cleanup on dependency change or unmount
```

`useFocusEffect` is navigation lifecycle:

```text
runs when screen is focused
cleanup when screen blurs or dependencies change
```

Example:

```tsx
useFocusEffect(
  React.useCallback(() => {
    fetchLoads();

    return () => {
      // cleanup on blur
    };
  }, [driverId])
);
```

Important:

```text
Wrap callback in useCallback.
Otherwise focus effect can run too often.
```

## When to use what

Use `useEffect` for:

```text
component mount setup
one-time initialization
effect tied to props/state, not screen focus
```

Use `useFocusEffect` for:

```text
refetch when screen comes back
subscribe while screen is visible
pause timer/listener when screen blurs
refresh permissions/session-sensitive data
```

Use `useIsFocused` for:

```text
conditionally render expensive screen content
pause expensive UI when not focused
```

## Navigation actions

```text
navigate = go to screen, reuse existing route when possible
push     = add another instance on stack
replace  = replace current screen
goBack   = pop current screen
reset    = replace navigation state
```

## Common bugs

```text
1. Expecting useEffect([]) to run when returning to a screen
2. Fetching on every render because useFocusEffect callback is not wrapped in useCallback
3. Keeping subscriptions alive after screen blur
4. Putting large objects/functions in route params
5. Assuming screen unmounts in tabs/stacks
6. Losing state due to key/reset/navigation changes
```

## Strong answer

> In React Navigation, component lifecycle and navigation lifecycle are different. A screen can stay mounted when it loses focus, so `useEffect([])` runs once on mount, not every time the user returns. For focus-based work like refetching data or subscribing only while visible, I use `useFocusEffect` with `useCallback`, and cleanup on blur. I use `useEffect` for component lifecycle work and `useFocusEffect` for screen visibility work.
