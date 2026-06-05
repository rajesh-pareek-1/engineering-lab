# React Native Internals Cheat Sheet

Goal: become strong at React internals **as they matter in React Native**.

Core map:

```text
React core     = components, props, state, hooks, reconciliation
React DOM      = renderer for browser DOM
React Native   = renderer for native iOS/Android views
```

Brain map:

```text
React decides what UI should be.
Renderer applies it somewhere.

Web target = DOM
RN target  = native views
```

---

## 1. Render vs Commit

Definition:

```text
Render = React calls component functions to calculate next UI tree.
Commit = renderer applies required changes to the real UI target.
```

RN flow:

```text
state/props/context change
   -> component function runs
   -> new React tree created
   -> React compares old tree vs new tree
   -> RN renderer commits native UI changes
```

Example:

```tsx
const [count, setCount] = useState(0);

<Pressable onPress={() => setCount(count + 1)}>
  <Text>Count: {count}</Text>
</Pressable>
```

What happens:

```text
press -> setCount -> render again -> reconcile -> commit native Text update
```

Strong answer:

> `setCount` does not directly change the screen. It schedules a state update. React renders, reconciles, and commits only required UI changes.

---

## 2. Component Identity

Definition:

```text
Component identity = how React decides whether a component is same as before or new.
```

React uses:

```text
component type + position + key
```

Brain map:

```text
same identity -> state preserved
new identity  -> state reset
```

Example:

```tsx
<Counter />
```

If same type and same position:

```text
count state preserved
```

Force reset:

```tsx
<Counter key={userId} />
```

When `userId` changes:

```text
old Counter unmounts
new Counter mounts
state resets
```

---

## 3. Keys and Identity Bugs

Rule:

```text
key = stable identity of list item
```

Good:

```tsx
keyExtractor={(item) => item.id}
```

Bad for dynamic lists:

```tsx
keyExtractor={(_, index) => index.toString()}
```

Why index key is dangerous:

```text
Before:
index 0 -> Amit
index 1 -> Rahul
index 2 -> Neha

After inserting John at top:
index 0 -> John
index 1 -> Amit
index 2 -> Rahul
index 3 -> Neha
```

React thinks:

```text
key 0 is same row
key 1 is same row
key 2 is same row
```

But the data shifted.

Result:

```text
Rahul's TextInput state may move to Amit
selected row may move
expanded card may move
focus may appear on wrong row
animation may attach to wrong item
```

Correct:

```tsx
<FlatList
  data={drivers}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <DriverRow driver={item} />}
/>
```

Strong answer:

> Index keys make identity follow position. Stable IDs make identity follow actual data. In RN lists, wrong keys can cause wrong `TextInput`, selected row, expanded row, or animation state.

---

## 4. FlatList `extraData`

Definition:

```text
extraData = external value that should make FlatList re-check rows
```

Use when row UI depends on state outside `data`.

Example:

```tsx
const [selectedDriverId, setSelectedDriverId] = useState<string | null>(null);

<FlatList
  data={drivers}
  keyExtractor={(item) => item.id}
  extraData={selectedDriverId}
  renderItem={({ item }) => (
    <DriverRow
      driver={item}
      isSelected={item.id === selectedDriverId}
      onPress={() => setSelectedDriverId(item.id)}
    />
  )}
/>
```

Brain map:

```text
data         = list items
keyExtractor = row identity
extraData    = external re-render signal
```

---

## 5. State Snapshot

Definition:

```text
State value inside one render is fixed.
```

Example:

```tsx
function handlePress() {
  setCount(count + 1);
  console.log(count); // old value
}
```

Why:

```text
count = snapshot from current render
setCount = request next render
```

Brain map:

```text
state variable = current render snapshot
setState       = schedule next render
```

Strong answer:

> React state is a snapshot for the current render. Calling the setter does not mutate the variable immediately. The new value is available in the next render.

---

## 6. Batching

Definition:

```text
Batching = React groups multiple state updates and does one render.
```

Example:

```tsx
function handlePress() {
  setCount(count + 1);
  setName("Amit");
  setSelected(true);
}
```

React does:

```text
collect updates -> one render
```

---

## 7. Functional Updates

Problem:

```tsx
setCount(count + 1);
setCount(count + 1);
setCount(count + 1);
```

If current render has:

```text
count = 0
```

All three updates become:

```tsx
setCount(1);
setCount(1);
setCount(1);
```

Final:

```text
count = 1
```

Correct:

```tsx
setCount((current) => current + 1);
setCount((current) => current + 1);
setCount((current) => current + 1);
```

Final:

```text
count = 3
```

Use functional update when next state depends on previous state:

```tsx
setDrivers((currentDrivers) => [newDriver, ...currentDrivers]);
```

Strong answer:

> If next state depends on previous state, I use functional updater form because it receives the latest queued state, not the stale snapshot from the current render.

---

## 8. Object and Array State

Rule:

```text
Do not mutate state directly.
Create new object/array.
```

Bad:

```tsx
drivers.push(newDriver);
setDrivers(drivers);
```

Bad because:

```text
same array reference
React/FlatList may not detect change
```

Good:

```tsx
setDrivers((current) => [newDriver, ...current]);
```

Update item:

```tsx
setDrivers((current) =>
  current.map((driver) =>
    driver.id === "d1" ? { ...driver, status: "Offline" } : driver
  )
);
```

Nested update:

```tsx
setDrivers((current) =>
  current.map((driver) =>
    driver.id === "d1"
      ? {
          ...driver,
          location: {
            ...driver.location,
            city: "Mumbai",
          },
        }
      : driver
  )
);
```

Brain map:

```text
copy every level you change
reuse unchanged objects
```

---

## 9. `map()` and Copying

```tsx
const arr2 = arr1.map((item) => item);
```

This creates:

```text
new array
same object references
```

This:

```tsx
const arr2 = arr1.map((item) => ({ ...item }));
```

creates:

```text
new array
new top-level objects
same nested objects
```

So:

```text
map alone != deep copy
spread != deep copy
nested spread = copy changed path
structuredClone = deep clone for supported data
```

Production rule:

```text
For React/RN state, do not deep clone everything.
Copy only changed path.
```

---

## 10. `useEffect`

Definition:

```text
useEffect = synchronize component with external systems.
```

External systems:

```text
API
timer
subscription
event listener
storage
native listener
WebSocket
permissions
AppState
NetInfo
```

Flow:

```text
render -> commit UI -> effect runs
```

Dependency rule:

```tsx
useEffect(() => {
  // logic
}, [value]);
```

Means:

```text
run after mount
run again when value changes
```

Cleanup:

```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount((current) => current + 1);
  }, 1000);

  return () => clearInterval(id);
}, []);
```

Strong answer:

> `useEffect` runs after commit. It is used for external synchronization like API calls, timers, subscriptions, or native listeners. Cleanup runs before the effect re-runs and when the component unmounts.

---

## 11. Stale Closure

Definition:

```text
Stale closure = function remembers old state/props from the render where it was created.
```

Bad:

```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount(count + 1);
  }, 1000);

  return () => clearInterval(id);
}, []);
```

Problem:

```text
interval remembers initial count
```

Correct:

```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount((current) => current + 1);
  }, 1000);

  return () => clearInterval(id);
}, []);
```

Strong answer:

> Stale closure happens when a callback or effect uses old state from a previous render. I fix it with correct dependencies or functional updates.

---

## 12. `React.memo`

Definition:

```text
React.memo = skip child re-render if props are same.
```

Example:

```tsx
const DriverRow = React.memo(function DriverRow({ driver, isSelected }) {
  return (
    <View>
      <Text>{driver.name}</Text>
      <Text>{isSelected ? "Selected" : "Not selected"}</Text>
    </View>
  );
});
```

Brain map:

```text
same props -> skip possible
changed props -> render
```

Important:

```text
React.memo checks props shallowly
```

This breaks memo:

```tsx
<DriverRow onPress={() => selectDriver(driver.id)} />
```

because:

```text
new function every render
```

---

## 13. `useMemo`

Definition:

```text
useMemo = cache calculated value.
```

Good:

```tsx
const filteredDrivers = useMemo(() => {
  return drivers.filter((driver) =>
    driver.name.toLowerCase().includes(search.toLowerCase())
  );
}, [drivers, search]);
```

Use for:

```text
large filtering
sorting
expensive calculation
stable array/object props
```

Do not waste it on cheap calculations.

---

## 14. `useCallback`

Definition:

```text
useCallback = cache function reference.
```

Good:

```tsx
const handleSelect = useCallback((driverId: string) => {
  setSelectedDriverId(driverId);
}, []);
```

Use when:

```text
passing callback to memoized child
passing callback to FlatList row
callback is dependency of effect
```

Important:

```text
useCallback does not make function logic faster
it only stabilizes function identity
```

---

## 15. Context

Definition:

```text
Context = shared value for a component tree without prop drilling.
```

Good for:

```text
auth user
theme
permissions
language
feature flags
app config
```

Bad for:

```text
TextInput value
screen search query
selected FlatList row
temporary form state
one-button loading state
```

Brain map:

```text
Provider   = supplies value
useContext = subscribes
value changes = consumers can re-render
```

Bad:

```tsx
<AuthContext.Provider value={{ user, login, logout }}>
  {children}
</AuthContext.Provider>
```

Why bad:

```text
new object every render
context consumers may re-render
```

Better:

```tsx
const value = useMemo(() => {
  return { user, login, logout };
}, [user, login, logout]);

<AuthContext.Provider value={value}>{children}</AuthContext.Provider>
```

Strong answer:

> Context solves prop drilling, but it is not a free global store. Components that read context can re-render when provider value changes. In RN, I keep fast-changing screen state local, memoize provider values, and split contexts by responsibility.

---

## 16. FlatList Performance

Core:

```text
ScrollView = renders all items
FlatList  = virtualized window
```

Important props:

```tsx
<FlatList
  data={drivers}
  keyExtractor={(item) => item.id}
  renderItem={renderItem}
  extraData={selectedDriverId}
  initialNumToRender={10}
  maxToRenderPerBatch={10}
  updateCellsBatchingPeriod={50}
  windowSize={7}
  getItemLayout={getItemLayout}
/>
```

Brain map:

```text
keyExtractor             = row identity
extraData                = external row state signal
initialNumToRender       = first render count
maxToRenderPerBatch      = rows per batch
windowSize               = mounted viewport area
getItemLayout            = skip measurement for fixed-height rows
```

Strong answer:

> For `FlatList`, I focus on stable keys, memoized rows, stable `renderItem`, stable callbacks, `extraData` for external row state, and `getItemLayout` for fixed-height rows. Then I tune batching/window props based on actual symptoms.

---

## 17. RN Performance Model

Main threads:

```text
JS thread = React logic, state updates, effects, renderItem, business logic, API handling
UI thread = native drawing, native view updates, scrolling, native animations
```

Symptoms:

```text
JS thread busy:
button delay
input delay
JS animation freeze
late state updates
FlatList lag from heavy renderItem

UI thread busy:
scroll jank
animation stutter
heavy layout/image rendering
native view update lag
```

Brain map:

```text
JS blocked != always UI blocked
native scrolling may continue while JS is busy
but JS callbacks/state updates wait
```

---

## 18. Bridge / JSI / Fabric / Hermes

Keep it simple:

```text
Old model:
JS communicates with native through bridge-style messages.

New architecture:
Fabric + JSI + TurboModules improve JS/native interaction.
```

Terms:

```text
Fabric       = new renderer
JSI          = more direct JS/native interface
TurboModules = modern native modules
Hermes       = JS engine optimized for RN
```

Strong answer:

> I do not treat New Architecture as magic. If the bottleneck is bad JS, heavy list rows, huge JSON parsing, or too many re-renders, Fabric/JSI will not automatically fix it. I still identify whether the issue is JS thread, UI thread, list virtualization, images, layout, or JS-native communication.

---

## 19. Performance Debugging Decision Tree

Button press delayed:

```text
likely JS thread busy
check heavy onPress logic, large state update, context re-render storm, console logs, expensive render
```

FlatList lag:

```text
likely heavy rows, bad keys, too many row re-renders, missing getItemLayout, bad images, too much data
```

Search input lag:

```text
likely filtering large array on every keystroke
fix with debounce, useMemo, server-side search, reducing render scope
```

Screen startup slow:

```text
likely large JS bundle, heavy imports, too much mount work, large initial data parsing
```

---

## 20. Arena Q&A

Q: What happens when state changes in RN?

> React schedules an update, calls the component again to calculate the next UI tree, reconciles old and new trees, and the RN renderer commits required changes to native views.

Q: Why should we not use index as key?

> Index makes identity follow position, not actual data. If items insert, delete, or reorder, React may preserve row state for the wrong item. In RN this can show as wrong `TextInput`, wrong selected row, wrong expanded card, or wrong animation.

Q: Why does `setCount(count + 1)` three times give only +1?

> Because `count` is a snapshot from the current render. All three updates use the same old value. Functional updates use the latest queued state, so `setCount(c => c + 1)` three times gives +3.

Q: What is stale closure?

> A function remembers variables from the render where it was created. If an interval, callback, or effect uses old state, it can behave incorrectly. Fix with correct dependencies or functional updates.

Q: When do you use `useMemo`?

> For expensive derived values like filtering or sorting large lists, or when I need stable object/array references for memoized children. I do not use it for cheap calculations.

Q: When do you use `useCallback`?

> When passing a function to a memoized child, FlatList row, or effect dependency where function identity matters. It stabilizes the function reference; it does not make the function logic faster.

Q: What is `extraData` in `FlatList`?

> It tells `FlatList` that row UI depends on some external state outside `data`. For example, if rows depend on `selectedDriverId`, I pass `extraData={selectedDriverId}` so the list re-checks rows when selection changes.

Q: How do you optimize a slow RN list?

> I check stable keys, row complexity, unnecessary row re-renders, `React.memo`, stable `renderItem`, stable callbacks, `extraData`, `getItemLayout` for fixed height, pagination, and batching/window props.

Q: What is the difference between React Web and RN?

> The React mental model is same: components, state, hooks, render, reconciliation. The renderer is different. Web commits to browser DOM. RN commits to native platform views.

Q: What causes RN app lag?

> Usually JS thread work, UI thread work, list rendering, image/layout cost, or JS-native communication. I first identify which bottleneck it is instead of blindly memoizing everything.

---

## 21. Minimum Code Patterns

Counter with functional update:

```tsx
const [count, setCount] = useState(0);

<Pressable onPress={() => setCount((current) => current + 1)}>
  <Text>{count}</Text>
</Pressable>
```

Safe array update:

```tsx
setDrivers((current) => [newDriver, ...current]);
```

Safe item update:

```tsx
setDrivers((current) =>
  current.map((driver) =>
    driver.id === targetId ? { ...driver, status: "Offline" } : driver
  )
);
```

Safe nested update:

```tsx
setDrivers((current) =>
  current.map((driver) =>
    driver.id === targetId
      ? {
          ...driver,
          location: {
            ...driver.location,
            city: "Mumbai",
          },
        }
      : driver
  )
);
```

Effect cleanup:

```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount((current) => current + 1);
  }, 1000);

  return () => clearInterval(id);
}, []);
```

Memoized FlatList row:

```tsx
const DriverRow = React.memo(function DriverRow({
  driver,
  isSelected,
  onSelect,
}: DriverRowProps) {
  return (
    <Pressable onPress={() => onSelect(driver.id)}>
      <Text>{driver.name}</Text>
      <Text>{isSelected ? "Selected" : "Not selected"}</Text>
    </Pressable>
  );
});
```

Stable FlatList renderItem:

```tsx
const handleSelect = useCallback((id: string) => {
  setSelectedDriverId(id);
}, []);

const renderItem = useCallback(
  ({ item }: { item: Driver }) => (
    <DriverRow
      driver={item}
      isSelected={item.id === selectedDriverId}
      onSelect={handleSelect}
    />
  ),
  [selectedDriverId, handleSelect]
);
```

FlatList skeleton:

```tsx
<FlatList
  data={drivers}
  keyExtractor={(item) => item.id}
  renderItem={renderItem}
  extraData={selectedDriverId}
/>
```

---

## 22. Final Brain Map

```text
React core:
component -> state/props/context -> render -> reconcile -> commit

React Native:
commit target = native views

State:
snapshot in current render
setter schedules next render
functional update uses latest queued state

Identity:
same type + same position + same key = preserve state
different key/type/position = reset state

Keys:
stable ID = correct identity
index = position identity bug

Effect:
runs after commit
cleanup before rerun/unmount
external sync only

Closure:
function remembers render values
wrong deps = stale values

Memo:
React.memo = component
useMemo = value
useCallback = function

Context:
useContext subscribes
provider value identity matters
split by responsibility

FlatList:
virtualized list
keyExtractor = identity
extraData = external signal
getItemLayout = fixed-height optimization

RN performance:
JS thread = React/business logic
UI thread = native drawing/views
debug bottleneck before optimizing
```
