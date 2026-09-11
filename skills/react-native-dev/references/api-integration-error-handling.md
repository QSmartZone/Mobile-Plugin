# API/network integration & error handling

## Lớp service tách UI khỏi HTTP client

Không gọi `fetch`/`axios` trực tiếp trong component — bọc qua 1 module service theo domain, UI chỉ biết gọi hàm trả về data đã parse hoặc throw error đã phân loại.

```ts
// features/user/api/userApi.ts
export async function getUser(id: string): Promise<User> {
  const res = await apiClient.get(`/users/${id}`);
  return userSchema.parse(res.data); // validate shape response, fail sớm nếu backend đổi contract
}
```

## Phân biệt loại lỗi

Không rethrow error gốc của axios/fetch thẳng lên UI (UI phải tự đoán `error.response.status` rải rác nhiều nơi) — chuẩn hóa về 1 kiểu lỗi domain ở lớp service/interceptor.

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
    if (!err.response) throw new ApiError('Không có kết nối mạng', 'network');
    if (err.response.status >= 500) throw new ApiError('Lỗi hệ thống', 'business', err.response.status);
    throw new ApiError(err.response.data?.message ?? 'Yêu cầu không hợp lệ', 'business', err.response.status);
  },
);
```

UI dựa vào `error.kind` để hiển thị đúng thông điệp (banner "mất kết nối" vs toast lỗi nghiệp vụ cụ thể), không hiển thị `error.message` thô của HTTP client cho người dùng cuối.

## React Query xử lý loading/error/retry

```tsx
const { data, error, isLoading } = useQuery({
  queryKey: ['user', id],
  queryFn: () => getUser(id),
  retry: (failureCount, err) => err instanceof ApiError && err.kind === 'network' && failureCount < 2,
});

if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorView kind={(error as ApiError).kind} />;
```

Không tự viết loading/error state bằng `useState` cho mỗi API call — React Query đã cover retry, cache, refetch on reconnect; tự chế lại là công việc thừa và dễ thiếu case (race condition khi param đổi giữa chừng).

## Anti-pattern

- `catch (e) {}` nuốt lỗi im lặng — tối thiểu log hoặc surface lên UI, không để lỗi biến mất không dấu vết.
- Gọi API trực tiếp trong `useEffect` không cleanup — request cũ trả về sau khi component đã đổi param/unmount có thể ghi đè state sai, dùng React Query hoặc AbortController.
- Không check `NetInfo`/kết nối mạng trước khi coi mọi lỗi là lỗi backend — phân biệt offline với lỗi server để thông điệp đúng.
