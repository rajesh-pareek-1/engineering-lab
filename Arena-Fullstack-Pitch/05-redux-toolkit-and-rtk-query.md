# 5. Redux Toolkit and RTK Query

## State decision tree

```text
Does only one component need it? → local state
Several nearby components?       → lift state / context
Global client behavior?          → Redux slice
Server-owned fetched data?       → RTK Query cache
URL/search/filter identity?       → route/query parameters
```

> Not all state belongs in Redux. Keep state at the narrowest correct owner and avoid copying server data into several stores.

## Redux flow

```text
component dispatches action
  → reducer calculates next state
  → store notifies subscribers
  → selector returns relevant data
  → component renders
```

Redux Toolkit uses Immer, so reducer code can look mutable while producing immutable updates:

```ts
const shipmentSlice = createSlice({
    name: 'shipment',
    initialState: { selectedId: null as number | null },
    reducers: {
        selectShipment(state, action: PayloadAction<number>) {
            state.selectedId = action.payload;
        },
    },
});
```

## RTK Query in dm-web

The application defines one `rootApi`, adds its reducer and middleware to the store, then injects generated feature endpoints.

```text
rootApi
├── base URL
├── Authorization header
├── shared cache/middleware
└── injected endpoints
    ├── shipments
    ├── loads
    ├── associates
    ├── reports
    └── settings
```

The real root API reads the token and adds:

```ts
headers.set('Authorization', `Bearer ${token}`);
```

## Query example

```ts
const { data, isLoading, isFetching, error, refetch } =
    useGetShipmentQuery(shipmentId);
```

- `isLoading`: first request has no data.
- `isFetching`: a request is in progress, possibly with cached data still visible.
- `error`: request failed.
- `data`: cached response.

## Mutation and cache invalidation

```ts
const api = rootApi.injectEndpoints({
    endpoints: build => ({
        getShipment: build.query<ShipmentDto, number>({
            query: id => `/api/shipments/${id}`,
            providesTags: (_result, _error, id) => [
                { type: 'Shipment', id },
            ],
        }),
        updateShipment: build.mutation<void, UpdateShipmentRequest>({
            query: body => ({
                url: `/api/shipments/${body.id}`,
                method: 'PUT',
                body,
            }),
            invalidatesTags: (_result, _error, body) => [
                { type: 'Shipment', id: body.id },
            ],
        }),
    }),
});
```

> Tags connect mutations to affected cached queries. Invalidation causes active subscribers to refetch instead of manually synchronizing every screen.

## Generated APIs

The repository contains a script that downloads Swagger/OpenAPI and runs RTK Query code generation.

```text
ASP.NET OpenAPI
  → generated TypeScript models/endpoints
  → compile-time request/response help
  → enhanced endpoints for custom cache behavior
```

Benefits:

- reduces repetitive endpoint code;
- keeps contracts discoverable;
- catches many mismatches during compilation;
- still requires review of naming, errors, cache tags, and backend compatibility.

## RTK Query interview answer

> RTK Query handles server-state fetching, caching, deduplication, loading/error state, invalidation, and refetching. Roll On Dispatch creates a shared root API that attaches the JWT and injects generated endpoints from the backend OpenAPI contract. Redux slices remain useful for client workflow state that is not simply server cache.

## Cross-questions

**Redux vs Context?** Context is good for low-frequency shared values such as theme. Redux offers structured updates, selectors, middleware, and dev tooling for complex global state. RTK Query specifically addresses server cache.

**Why not fetch in every `useEffect`?** It duplicates loading/error/cache/cancellation logic and can cause request races. Query tooling centralizes these concerns.

**Optimistic update?** Update UI/cache before server confirmation, then undo on failure. Use when success is likely and rollback is clear; avoid hiding critical business validation.

**Stale data after mutation?** Invalidate the correct tag, manually update the cached entity, or refetch deliberately. First identify which cache key and endpoint produced the stale view.

**What should not be stored in Redux?** DOM nodes, large files, duplicated derived data, highly local form state, and non-serializable values unless the architecture explicitly accepts the trade-off.

