# 12. Actual .NET + React First-Round Additions

> This is the **frontend/full-stack complement** to Backend Pitch page 12. It closes the questions that were not covered deeply enough: Apollo, multiple GraphQL clients, large data UI, and Azure frontend deployment.

## 1. What is React? Which version have you used?

> React is a JavaScript library for building user interfaces from reusable components. Components receive props, own state, and re-render declaratively when state changes. In `dm-web`, the project uses **React 18.2**, TypeScript, Redux Toolkit/RTK Query, and React Router. I understand React 19’s direction, but I do not claim that our existing app was built on it.

## 2. What is GraphQL?

> GraphQL is a typed API query language and execution model. The server exposes a schema; clients ask for exactly the fields they need through queries, change data through mutations, and can receive live updates through subscriptions.

### Example query

```graphql
query GetShipment($id: Int!) {
  shipment(id: $id) {
    shipmentId
    reference
    status
    driverLoads {
      driverLoadId
      driver { name }
    }
  }
}
```

> This is one logical API request, not automatically one database query. The .NET server must batch resolver loading with DataLoader and authorize data at resolver/use-case level.

## 3. How would the React frontend use GraphQL?

> I would use a typed GraphQL client such as **Apollo Client** when the product benefits from normalized cache, query/mutation hooks, cache updates, and subscriptions. I have used REST/RTK Query in the project, not Apollo in production, so I state that boundary clearly.

```tsx
const GET_SHIPMENT = gql`
  query GetShipment($id: Int!) {
    shipment(id: $id) { shipmentId reference status }
  }
`;

function ShipmentPage({ id }: { id: number }) {
  const { data, loading, error } = useQuery(GET_SHIPMENT, {
    variables: { id }
  });

  if (loading) return <Spinner />;
  if (error) return <ErrorState />;
  return <ShipmentCard shipment={data.shipment} />;
}
```

## 4. How would you set up Apollo Client safely?

```tsx
const httpLink = new HttpLink({ uri: "/graphql" });

const authLink = setContext((_, { headers }) => ({
  headers: {
    ...headers,
    Authorization: `Bearer ${getAccessToken()}`
  }
}));

const client = new ApolloClient({
  link: authLink.concat(httpLink),
  cache: new InMemoryCache()
});

root.render(
  <ApolloProvider client={client}><App /></ApolloProvider>
);
```

> In a real application, I avoid blindly reading tokens from insecure storage, handle refresh once rather than per failed request, do not cache sensitive data carelessly, and clear/reset the cache on logout or tenant change.

## 5. How would you use multiple Apollo clients?

> First ask why there are multiple GraphQL endpoints. A gateway/supergraph or BFF is often cleaner because the browser has one secure API boundary. If endpoints are truly independent, create separate clients with separate URI/auth/cache policies and choose the intended client explicitly per feature or subtree. Do not mix tenant or authorization cache data between them.

```tsx
const reportingClient = new ApolloClient({
  uri: "/reporting/graphql",
  cache: new InMemoryCache()
});

const { data } = useQuery(GET_REPORT, {
  client: reportingClient,
  variables: { reportId }
});
```

```text
Preferred: one gateway / BFF → one client, one auth boundary
Multiple clients: only for truly separate APIs → isolated cache + auth + error policy
```

## 6. REST HTTP methods—frontend view

| Action | React/RTK Query request | Meaning |
|---|---|---|
| Load shipment | `GET /api/shipments/42` | read |
| Create shipment | `POST /api/shipments` | create/command |
| Replace shipment | `PUT /api/shipments/42` | full known representation |
| Change status | `PATCH /api/shipments/42` | partial update |
| Delete attachment | `DELETE /api/attachments/9` | remove/deactivate |

> The frontend interprets status/error shape, but the API remains authoritative for validation, authorization, tenant isolation, and state transitions.

## 7. Large data in a React screen—how do you avoid lag?

```text
Backend first: filter + stable sort + server pagination + small DTO
Frontend next: loading/error/empty states + virtualized list/grid + stable row keys
Then: debounce search, cancel stale requests, cache data, profile render/network time
```

> I never fetch every row just to paginate in the browser. For thousands of visible rows, use virtualization such as `react-window`/a grid’s virtual mode so only viewport rows mount.

## 8. Offset versus keyset pagination—what would you use?

> Offset/page pagination is simple and supports “go to page 20,” but concurrent inserts/deletes can shift offsets and cause duplicates/misses. For a high-volume, sequential activity feed or shipment list, I prefer keyset/cursor pagination using a stable composite sort key such as `(CreatedAt, ShipmentId)`.

```text
First request → GET /shipments?limit=50
Response      → data + nextCursor=(lastCreatedAt,lastShipmentId)
Next request  → GET /shipments?limit=50&cursor=...
```

> The backend validates/decodes the cursor and applies the keyset predicate. The client treats cursor as opaque—never creates SQL logic itself.

## 9. How would you deploy a React SPA to Azure?

```text
Git push / PR
 → Azure DevOps or GitHub Actions
 → npm ci → test/lint → npm run build
 → deploy static build output (`dist`/`build`)
 → staging preview / smoke test
 → production with custom domain + HTTPS + monitoring
```

> For a client-rendered React SPA, **Azure Static Web Apps** is a strong managed choice: it integrates with GitHub/Azure DevOps, globally serves static assets, provides SSL and preview environments, and can connect to an existing API. I configure SPA navigation fallback, environment-specific API base URL, restricted CORS if the API is separate, and never ship secrets in the browser bundle.

## 10. Third-party tools and limitations

> I have direct project exposure to integrations such as Azure Blob Storage, push-notification infrastructure, and QuickBooks-style boundaries; I do not claim Power Automate production work if I did not build it. For any third-party tool, I isolate it behind an adapter/service, define timeout/retry/idempotency behavior, handle rate/payload/pagination limits, log safe diagnostic context, and keep a reconciliation/manual fallback for important workflows.

## 11. Million-record import—what does the frontend do?

> The frontend uploads the file once and gets `202 Accepted` plus an `importJobId`; it does not wait for one million rows in a browser request. It shows progress through polling or SignalR, displays a downloadable error report, prevents duplicate submission, and clearly distinguishes accepted, processing, partial-success, and failed states. The backend flow is on Backend Pitch page 12.

## 12. Full-stack rapid answers

| Question | Answer |
|---|---|
| Valid JWT but `403`? | Backend authenticated the user but policy/role/tenant/resource authorization failed. Inspect claims, permission, tenant ownership, and trace ID. |
| Access token expires? | Perform one coordinated refresh, rotate safely, retry the original request once, otherwise clear session. |
| EF query is fast in SQL but slow in API? | Inspect N+1, tracking/materialization, mapping, JSON size, downstream calls, blocking async code, CPU/GC/pool waits, and network—not only SQL. |
| Why global exception handling? | Consistent safe errors and logging across all API routes; implement early middleware, not 100 controller `try/catch` blocks. |
| Why `Task.WhenAll`? | Independent I/O can run concurrently, reducing latency to approximately the slowest call; respect dependencies and downstream limits. |
| How test a frontend feature? | Unit-test pure logic/components, integration-test important UI behavior with mocked network, and use end-to-end tests for critical user flows. |

## Sources for current tool choices

- [Hot Chocolate GraphQL server for ASP.NET Core](https://chillicream.com/docs/hotchocolate/server)
- [Azure Static Web Apps overview](https://learn.microsoft.com/en-us/azure/static-web-apps/overview)
- [Azure deployment guide for React/static web apps](https://learn.microsoft.com/en-us/azure/static-web-apps/deploy-web-framework)
