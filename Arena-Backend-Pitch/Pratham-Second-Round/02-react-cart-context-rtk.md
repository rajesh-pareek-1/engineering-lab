# Pratham Round 2 — React Cart, Context, and Redux Toolkit

> **Whiteboard goal:** show component boundaries, pick state deliberately, then make the server authoritative at checkout.

## 1. “Design a cart” — answer before writing code

```text
ProductList (server product data)
  └─ ProductCard (presentational; onAdd(product))

CartButton (count / opens drawer)
CartDrawer (cart lines)
  └─ CartLine (quantity + remove)
  └─ CartSummary (subtotal / checkout)
Checkout (revalidates price, stock, coupon on server)
```

| State                             | Best home                                            | Why                                                         |
| --------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------- |
| Is cart drawer open               | Component`useState`                                | Local, short-lived UI state.                                |
| Products / current prices / stock | RTK Query or server cache                            | Server data needs fetch, invalidation, loading/error state. |
| Cart items used across pages      | Context for small app; Redux Toolkit for complex app | Shared client state.                                        |
| Final total, tax, price, stock    | Backend at checkout                                  | Browser values are untrusted and stale.                     |

**Speak this line:** “The client cart is an intent list—product/variant and quantity. The backend recalculates prices, checks stock, reserves inventory, and creates the order in a transaction.”

---

## 2. Simplest safe Context cart wrapper

```tsx
import React, { createContext, useContext, useMemo, useState } from "react";

type Product = { id: string; name: string; price: number };
type CartItem = Product & { quantity: number };
type Cart = {
  items: CartItem[];
  add: (product: Product) => void;
  remove: (id: string) => void;
  total: number;
};

const CartContext = createContext<Cart | undefined>(undefined);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);

  const add = (product: Product) => setItems(current => {
    const existing = current.find(item => item.id === product.id);
    return existing
      ? current.map(item => item.id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item)
      : [...current, { ...product, quantity: 1 }];
  });

  const remove = (id: string) =>
    setItems(current => current.filter(item => item.id !== id));

  const total = useMemo(
    () => items.reduce((sum, item) => sum + item.price * item.quantity, 0),
    [items]
  );

  return <CartContext.Provider value={{ items, add, remove, total }}>
    {children}
  </CartContext.Provider>;
}

export function useCart() {
  const cart = useContext(CartContext);
  if (!cart) throw new Error("useCart must be inside CartProvider");
  return cart;
}
```

```tsx
function ProductCard({ product }: { product: Product }) {
  const { add } = useCart();
  return <button onClick={() => add(product)}>Add {product.name}</button>;
}
```

### Explain the code in five bullets

- `createContext` exposes one shared contract.
- `CartProvider` owns changing state; consumers do not mutate it directly.
- `add` uses functional state update: safe when React batches updates.
- `useMemo` avoids re-calculating total unless items change.
- custom `useCart` prevents accidental use outside the provider.

**Context weakness:** every consuming component can re-render when the provider value changes. Split contexts or use Redux selectors if the state becomes broad/hot/complex.

---

## 3. Simplest Redux Toolkit (RTK) cart

```tsx
// cartSlice.ts
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

type Product = { id: string; name: string; price: number };
type CartItem = Product & { quantity: number };

const cartSlice = createSlice({
  name: "cart",
  initialState: { items: [] as CartItem[] },
  reducers: {
    add(state, action: PayloadAction<Product>) {
      const item = state.items.find(x => x.id === action.payload.id);
      if (item) item.quantity += 1; // Immer makes this immutable underneath.
      else state.items.push({ ...action.payload, quantity: 1 });
    },
    remove(state, action: PayloadAction<string>) {
      state.items = state.items.filter(x => x.id !== action.payload);
    }
  }
});

export const { add, remove } = cartSlice.actions;
export default cartSlice.reducer;
```

```tsx
// store.ts + component
import { configureStore } from "@reduxjs/toolkit";
import cart from "./cartSlice";

export const store = configureStore({ reducer: { cart } });
export type RootState = ReturnType<typeof store.getState>;

function CartButton() {
  const count = useSelector((s: RootState) =>
    s.cart.items.reduce((n, item) => n + item.quantity, 0));
  const dispatch = useDispatch();
  return <button onClick={() => dispatch(add(product))}>Cart ({count})</button>;
}
```

`createSlice` = reducer + action creators together.
`configureStore` = store with good defaults.
`useSelector` reads a slice; `dispatch` requests a state transition.

### Context vs RTK vs RTK Query

```text
Theme / simple auth / tiny cart         -> Context
Complex shared client state + devtools  -> Redux Toolkit
API fetching, cache, invalidation       -> RTK Query
```

In ROD web, the existing implementation uses `@reduxjs/toolkit`, `react-redux`, `configureStore`, a `createSlice` auth reducer, and an RTK Query `rootApi`. `rootApi` uses `fetchBaseQuery`, applies the Bearer token in `prepareHeaders`, and registers API middleware.

**Do not say RTK Query replaces backend authorization.** It caches client requests; JWT/API authorization still happens on the server.

---

## 4. React component design questions

### A good component answer

> “I keep a component responsible for one thing. A `ProductCard` receives display data and an `onAdd` callback; it does not know Redux or call checkout APIs. The screen/container owns data loading and passes props. Shared state is lifted only to the nearest common owner, and I use Context/Redux only when many branches truly need it.”

### Common follow-ups

| Question                        | Fast answer                                                                                                                                                                              |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `useEffect` dependency?       | It declares values the effect reads; missing dependencies risks stale data, a changing object/array can create a loop. Fetch products once with`[]` only if it reads nothing changing. |
| Why keys in map?                | Stable identity lets React reconcile correct list items. Use`product.id`, not array index when list can change.                                                                        |
| `useMemo` vs `useCallback`? | `useMemo` caches a calculated value; `useCallback` caches a function identity. Use after measuring/when identity matters, not automatically.                                         |
| Controlled input?               | React state is the source of truth:`value` + `onChange`; good for validation and predictable forms.                                                                                  |
| Context rerender risk?          | Provider value update notifies consumers; split context or use selector-based state for high-churn data.                                                                                 |
| How persist cart?               | Local storage for a guest UX, server cart for logged-in users; revalidate all prices/stock on API checkout.                                                                              |

---

## 5. Full-stack cart request flow

```text
React ProductCard
  -> add productId/variantId/qty to client cart
  -> POST /api/carts or POST /api/orders/checkout
  -> JWT + tenant / user authorization
  -> load authoritative product + stock + current price
  -> SQL transaction: validate -> reserve/decrement safely -> create order/items
  -> response with server-calculated order / conflict if stock changed
```

### Concurrency line that sounds senior

> “I would never reserve an iPhone by trusting a frontend count. At checkout the backend uses a transaction and a concurrency-safe stock update—for example a conditional update where available quantity is still sufficient. The UI handles a conflict by refreshing stock and explaining the change.”

---

## 6. Five-minute whiteboard rehearsal

1. Draw the component tree.
2. State which state is local, shared, and server-owned.
3. Write Context `add` with functional update **or** an RTK `createSlice`.
4. Mention loading/error/empty states for product API.
5. Finish with the backend revalidation/security boundary.

That is a complete design answer—not just “I would use Redux.”
