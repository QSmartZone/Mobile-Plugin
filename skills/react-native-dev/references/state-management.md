# State management

## useState/useReducer — state cục bộ

Mặc định cho state chỉ 1 component dùng. `useReducer` khi state có nhiều field liên quan cập nhật cùng lúc theo action rõ ràng (form phức tạp, wizard nhiều bước) — tránh chuỗi `useState` rời rạc dễ ra trạng thái không nhất quán.

```tsx
function useToggle(initial = false) {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue((v) => !v), []);
  return [value, toggle] as const;
}
```

## Context API — chia sẻ trong 1 nhánh cây

Dùng cho state ít thay đổi, phạm vi hẹp (theme, auth user, locale). Tránh đặt state thay đổi liên tục (ví dụ giá trị animation, scroll position) vào Context — mọi consumer re-render mỗi lần value đổi, không có selector như Zustand/Redux.

```tsx
const AuthContext = createContext<AuthState | null>(null);
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth phải dùng trong AuthProvider');
  return ctx;
}
```

## Zustand — store nhẹ, ít boilerplate

Phù hợp phần lớn app cỡ vừa: global state (giỏ hàng, filter, UI state cross-screen) mà không cần toàn bộ ceremony của Redux (action type, reducer, dispatch).

```tsx
const useCartStore = create<CartState>((set) => ({
  items: [],
  addItem: (item) => set((s) => ({ items: [...s.items, item] })),
}));

// component chỉ subscribe field cần, tránh re-render khi field khác đổi
const items = useCartStore((s) => s.items);
```

## Redux Toolkit — app lớn, cần devtools/middleware mạnh

Chọn khi team đã quen Redux, cần time-travel debugging, middleware phức tạp (saga/thunk pipeline nhiều bước), hoặc codebase đã có sẵn Redux — không migrate giữa chừng sang Zustand chỉ vì "nhẹ hơn" nếu chưa đo được vấn đề thật.

## React Query (TanStack Query) — server state

Không lưu dữ liệu fetch từ API vào Zustand/Redux/Context bằng tay (tự quản loading/error/cache/refetch) — dùng React Query cho mọi state có nguồn gốc từ server, để cache, refetch, invalidate được xử lý sẵn.

```tsx
const { data, isLoading, error } = useQuery({
  queryKey: ['user', userId],
  queryFn: () => api.getUser(userId),
});
```

## Nguyên tắc chọn

- State cục bộ trước, global state chỉ khi thật sự cần chia sẻ ngoài phạm vi 1 component/1 màn hình.
- Không trộn 2 lib global state (vừa Redux vừa Zustand) trong cùng 1 feature — chọn 1, theo đúng lib project đã có sẵn.
- Server state luôn qua React Query/SWR, không tự chế bằng `useEffect` + `useState` — dễ leak race condition khi request cũ trả về sau request mới.
