# 7. Performance, Debugging, and Testing

## Full-stack performance map

```text
User-perceived delay
├── bundle/download
├── React render
├── duplicate API requests
├── network/API latency
├── backend computation
├── SQL query/locks
└── external service
```

> Optimize the measured bottleneck, not the layer you happen to prefer.

## React performance: **M-V-L-S**

- **M - Measure:** React Profiler and browser performance tools.
- **V - Virtualize:** render visible rows for large lists.
- **L - Lazy-load:** routes/components and expensive resources.
- **S - Stabilize:** memoization only where reference churn is measured.

### Memoization

```tsx
const filteredLoads = useMemo(
    () => loads.filter(load => load.status === selectedStatus),
    [loads, selectedStatus],
);

const onSelect = useCallback(
    (id: number) => dispatch(selectShipment(id)),
    [dispatch],
);
```

> `useMemo`, `useCallback`, and `React.memo` have complexity and comparison cost. Use them for measured expensive calculation or when stable references prevent meaningful child work—not everywhere.

## Large load-board data

> Use server-side filtering, sorting, and pagination so the browser does not download every shipment. Use stable keys and virtualization for long visible lists. Avoid N+1 API calls from each row, cache shared lookups, debounce search, and keep response DTOs focused.

## List virtualization — React web + React Native

```text
Normal list:       10,000 records -> 10,000 DOM/native row components mounted
Virtualized list:  10,000 records -> only viewport rows + small buffer mounted
```

Virtualization improves **rendering and memory**. It does **not** solve an API that downloads 10,000 records—filter, sort, and paginate/cursor-paginate on the server first.

### React web

```tsx
// Typical concept with a virtual-list library such as react-window.
// Only rows in the viewport are rendered.
<VirtualList
  height={600}
  itemCount={shipments.length}
  itemSize={48}
  itemData={shipments}
>
  {ShipmentRow}
</VirtualList>
```

```text
Use stable key: shipment.shipmentId
Keep row props small and stable
Memoize an expensive row only after profiling proves repeat renders
For a slow filter input: debounce API calls or useDeferredValue for non-critical rendering
```

### React Native

```text
ScrollView = renders every child; avoid it for long data.
FlatList   = virtualized list; use it for driver/shipment/history lists.
```

```tsx
const renderDriver = useCallback(
  ({ item }: { item: Driver }) => <DriverRow driver={item} />,
  []
);

<FlatList
  data={drivers}
  renderItem={renderDriver}
  keyExtractor={(driver) => driver.associateId.toString()}
  initialNumToRender={10}
  windowSize={5}
  getItemLayout={(_, index) => ({
    length: 72,
    offset: 72 * index,
    index
  })}
  onEndReached={loadNextPage}
  onEndReachedThreshold={0.5}
/>
```

```text
initialNumToRender = first batch; enough to fill screen, not much more
windowSize         = viewports kept mounted around current viewport
getItemLayout      = skip measuring when every row has fixed height
onEndReached       = fetch next cursor/page, not entire data set
```

### Interview answer

> “For a large shipment or driver list, I first make the API server-filtered and cursor/page-paginated. On React web I virtualize rows so off-screen DOM nodes do not mount. In React Native I use `FlatList`, stable `keyExtractor`, a memoized row renderer, and `getItemLayout` when row height is fixed. I profile first because virtualization helps render cost, not an oversized API response or slow SQL query.”

## Debugging mnemonic: **R-E-S-C-U-E**

- **R - Reproduce** consistently.
- **E - Evidence** from console/network/logs.
- **S - Scope** affected user, tenant, browser, data.
- **C - Cause** at UI, state, API, service, SQL, integration.
- **U - Update** with smallest safe fix.
- **E - Evaluate** with regression test and monitoring.

## Common UI bugs

### Stale state

> Check missing dependencies, mutation, stale closures, duplicated server data, and wrong cache invalidation.

### Duplicate request

> Check effect execution, event bubbling, double-click, multiple component subscriptions, retry behavior, and React development Strict Mode. Add server idempotency for critical writes.

### Correct API response, wrong screen

> Inspect selector/cache key, data mapping, conditional rendering, memo dependencies, and whether an older local copy overwrites server data.

## Frontend tests

The repository uses Create React App testing dependencies: Jest, React Testing Library, `jest-dom`, and user-event.

```tsx
test('submits a valid driver assignment', async () => {
    const user = userEvent.setup();
    const onAssign = jest.fn();

    render(<DriverCard driverName="Alex" onAssign={onAssign} />);

    await user.click(screen.getByRole('button', { name: 'Alex' }));
    await user.click(screen.getByRole('button', { name: 'Assign' }));

    expect(onAssign).toHaveBeenCalledTimes(1);
});
```

> React Testing Library tests behavior through accessible UI rather than implementation details. Prefer role/name queries and realistic user events.

## Backend tests

ROD uses:

- xUnit: `[Fact]`, `[Theory]`;
- Moq: replace dependencies;
- FluentAssertions: readable assertions;
- EF Core InMemory for selected tests;
- `WebApplicationFactory`: integration pipeline;
- Coverlet: code coverage.

```csharp
[Fact]
public async Task Upload_ShouldUpdateStatus_WhenAttachmentIsValid()
{
    // Arrange
    attachmentService
        .Setup(x => x.UploadFileAsync(It.IsAny<AttachmentRequest>()))
        .ReturnsAsync(expectedAttachment);

    // Act
    var result = await service.UploadAsync(driverLoadId, request);

    // Assert
    result.Should().BeEquivalentTo(expectedAttachment);
    repository.Verify(x => x.Update(It.IsAny<DriverLoad>()), Times.Once);
}
```

## Test pyramid

```text
few end-to-end tests     critical journeys
some integration tests  API/framework/database wiring
many focused tests       business and component behavior
```

> The goal is confidence, not an arbitrary coverage number. Prioritize permissions, transactions, status transitions, calculations, error recovery, and past regressions.

## Performance story structure

> I would start with a measured user symptom, isolate whether time is in render, network, API, or SQL, apply one targeted change, and compare before/after using the same data. For a large grid, that may mean server pagination plus virtualization; for a slow API, projection, `AsNoTracking`, a better index, or fewer round trips.
