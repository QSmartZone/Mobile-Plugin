# API/network integration & error handling

## Service layer separates UI from the HTTP client

Do not call `fetch`/`axios` directly in components — wrap them in a per-domain service module; the UI only calls functions that return parsed data or throw a classified error.

```ts
// features/user/api/userApi.ts
export async function getUser(id: string): Promise<User> {
  const res = await apiClient.get(`/users/${id}`);
  return userSchema.parse(res.data); // validate response shape, fail early if backend changes contract
}
```

## Distinguish error types

Do not rethrow the raw axios/fetch error straight to the UI (the UI would have to guess `error.response.status` in many places) — normalize to one domain error type in the service layer/interceptor.

```ts
class ApiError extends Error {
  constructor(
    message: string,
    public kind: 'network' | 'parse' | 'business',
    public status?: number,
  ) {
    super(message);
  }
}

apiClient.interceptors.response.use(
  (res) => res,
  (err) => {
    if (!err.response) throw new ApiError('No network connection', 'network');
    if (err.response.status >= 500) throw new ApiError('System error', 'business', err.response.status);
    throw new ApiError(err.response.data?.message ?? 'Invalid request', 'business', err.response.status);
  },
);
```

The UI relies on `error.kind` to show the right message ("connection lost" banner vs a specific business-error toast), and does not show the HTTP client's raw `error.message` to end users.

## React Query handles loading/error/retry

```tsx
const { data, error, isLoading } = useQuery({
  queryKey: ['user', id],
  queryFn: () => getUser(id),
  retry: (failureCount, err) => err instanceof ApiError && err.kind === 'network' && failureCount < 2,
});

if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorView kind={(error as ApiError).kind} />;
```

Do not hand-write loading/error state with `useState` for every API call — React Query already covers retry, cache, refetch on reconnect; reinventing it is wasted work and easily misses cases (race condition when params change mid-request).

## Anti-pattern

- `catch (e) {}` silently swallowing errors — at minimum log or surface it in the UI; do not let errors vanish without a trace.
- Calling the API directly in `useEffect` without cleanup — an old request returning after the component changed params/unmounted can overwrite state incorrectly; use React Query or AbortController.
- Not checking `NetInfo`/network connectivity before treating every error as a backend error — distinguish offline from server errors so the message is correct.
