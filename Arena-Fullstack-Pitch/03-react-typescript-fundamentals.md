# 3. React and TypeScript Fundamentals

## React mental model

```text
props + state
      ↓
render UI
      ↓
user/event/effect
      ↓
state changes
      ↓
render again
```

> React builds UI from components. A component renders based on props and state. When relevant state changes, React schedules another render and reconciles the result with the DOM.

## Props vs state

- **Props:** inputs received from a parent; the child treats them as read-only.
- **State:** data owned by a component or external store that can change over time.

```tsx
type DriverCardProps = {
    driverName: string;
    onAssign: () => void;
};

export function DriverCard({ driverName, onAssign }: DriverCardProps) {
    const [isExpanded, setIsExpanded] = useState(false);

    return (
        <section>
            <button onClick={() => setIsExpanded(value => !value)}>
                {driverName}
            </button>
            {isExpanded && <button onClick={onAssign}>Assign</button>}
        </section>
    );
}
```

`driverName` is a prop; `isExpanded` is local state.

## Hooks mnemonic: **S-E-M-C-R**

- `useState`: local state.
- `useEffect`: synchronize with an external system.
- `useMemo`: memoize a calculated value.
- `useCallback`: memoize a function reference.
- `useRef`: stable mutable reference or DOM reference without rendering.

## `useEffect`

```tsx
useEffect(() => {
    document.title = `Shipment ${shipmentId}`;

    return () => {
        document.title = 'Roll On Dispatch';
    };
}, [shipmentId]);
```

> Use effects for synchronization such as subscriptions, timers, or imperative browser APIs. Do not use an effect for a value that can be calculated directly during render.

Cross-question: **What does the dependency array do?**

> It declares reactive values used by the effect. The effect reruns when one changes. An empty array means mount/unmount behavior, subject to development Strict Mode checks.

## Controlled form

```tsx
const [reference, setReference] = useState('');

return (
    <input
        value={reference}
        onChange={event => setReference(event.target.value)}
    />
);
```

> A controlled input receives its value from React state and sends changes back through a handler. It makes validation and conditional UI predictable, though large forms may need careful structure or a form library.

## Keys

```tsx
{driverLoads.map(load => (
    <DriverLoadRow key={load.driverLoadId} load={load} />
))}
```

> Keys give list items stable identity across renders. Use a stable business ID, not array index when items can be inserted, removed, or reordered.

## TypeScript essentials

```ts
type ShipmentStatus = 'Ready' | 'Dispatched' | 'Delivered';

interface ShipmentSummary {
    shipmentId: number;
    reference: string;
    status: ShipmentStatus;
    driverName?: string;
}
```

> TypeScript adds compile-time checks and tooling, but types disappear at runtime. Server data still requires defensive handling because the API can return unexpected data.

### `type` vs `interface`

> Both model object shapes. Interfaces support declaration merging and are natural for extensible object contracts. Type aliases also represent unions, intersections, primitives, and tuples. Team consistency matters more than treating one as universally superior.

### `any` vs `unknown`

> `any` disables useful checking. `unknown` requires narrowing before use, making it safer for errors or untrusted data.

```ts
function getErrorMessage(error: unknown): string {
    return error instanceof Error ? error.message : 'Unknown error';
}
```

## React cross-questions

**Component vs hook?** A component returns UI; a custom hook packages reusable stateful logic and follows hook rules.

**Why should state be immutable?** React and Redux rely heavily on reference changes to detect updates; mutation can create stale UI and difficult debugging.

**What is lifting state?** Move shared state to the closest common parent, or to an appropriate external store if it is truly cross-cutting.

**What causes re-render?** State update, parent render, context change, or external-store subscription update. A render does not always mean a DOM change.

**What is an error boundary?** A component boundary that catches rendering lifecycle errors below it and displays fallback UI. The ROD entry point uses `react-error-boundary`.

