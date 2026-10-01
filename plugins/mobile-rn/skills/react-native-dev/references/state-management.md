# State management

## useState/useReducer — local state

Default for state used by only 1 component. Use `useReducer` when state has several related fields updated together by clear actions (complex form, multi-step wizard) — avoid a string of separate `useState` calls that easily produce inconsistent state.

```tsx
function useToggle(initial = false) {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue((v) => !v), []);
  return [value, toggle] as const;
}
```

## Context API — share within one subtree

Use for rarely changing, narrow-scope state (theme, auth user, locale). Avoid putting continuously changing state (for example animation values, scroll position) into Context — every consumer re-renders on each value change, with no selector like Zustand/Redux.

```tsx
const AuthContext = createContext<AuthState | null>(null);
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
```

## Zustand — lightweight store, little boilerplate

Fits most mid-size apps: global state (cart, filter, cross-screen UI state) without the full ceremony of Redux (action types, reducers, dispatch).

```tsx
const useCartStore = create<CartState>((set) => ({
  items: [],
  addItem: (item) => set((s) => ({ items: [...s.items, item] })),
}));

// component subscribes only to the field it needs, avoiding re-render when other fields change
const items = useCartStore((s) => s.items);
```

## Redux Toolkit — large apps needing strong devtools/middleware

Choose when the team already knows Redux, needs time-travel debugging, complex middleware (multi-step saga/thunk pipelines), or the codebase already has Redux — do not migrate midway to Zustand just because it is "lighter" if no real problem has been measured.

## React Query (TanStack Query) — server state

Do not store data fetched from an API in Zustand/Redux/Context by hand (managing loading/error/cache/refetch yourself) — use React Query for all server-originated state, so caching, refetching, and invalidation are handled for you.

```tsx
const { data, isLoading, error } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => api.getUser(userId),
});
```

## Selection principles

- Local state first; global state only when it truly must be shared beyond 1 component/1 screen.
- Do not mix 2 global state libs (both Redux and Zustand) in the same feature — pick 1, the one the project already has.
- Server state always goes through React Query/SWR, not hand-rolled with `useEffect` + `useState` — it easily leaks race conditions when an old request returns after a newer one.
