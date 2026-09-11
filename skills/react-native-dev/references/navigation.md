# Navigation

## React Navigation — stack/tab/drawer

Param list type hóa tập trung 1 nơi (`navigation/types.ts`), mọi screen dùng `NativeStackScreenProps`/hook có generic từ param list đó — không dùng `navigation.navigate('Screen', {...})` với param bất kỳ không được type-check.

```tsx
// navigation/types.ts
export type RootStackParamList = {
  Home: undefined;
  UserDetail: { userId: string };
};

// screens/UserDetailScreen.tsx
type Props = NativeStackScreenProps<RootStackParamList, 'UserDetail'>;
function UserDetailScreen({ route }: Props) {
  const { userId } = route.params; // type-safe, không cần as/any
}
```

Route definition tập trung ở 1 navigator, không rải `<Stack.Screen>` định nghĩa rời rạc nhiều nơi trong app. Deep link config (`linking`) đặt cùng chỗ với navigator gốc để dễ đối chiếu route ↔ URL scheme.

## Expo Router — file-based

Tên file/thư mục trong `app/` chính là route — `(group)` để nhóm route không xuất hiện trong URL (ví dụ tách `(auth)` và `(tabs)` dùng layout khác nhau), `[param].tsx` cho dynamic route.

```
app/
├── users/
│   ├── index.tsx        # /users
│   └── [id].tsx          # /users/:id
```

```tsx
// app/users/[id].tsx
import { useLocalSearchParams } from 'expo-router';
export default function UserDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
}
```

## Chọn cái nào

Dự án đã có sẵn 1 trong 2 thì theo đúng cái đó — không migrate giữa chừng trừ khi được yêu cầu tường minh (đổi cơ chế routing là thay đổi kiến trúc lớn, ảnh hưởng deep link, analytics screen tracking, animation transition).

Project mới: Expo Router phù hợp khi đã dùng Expo managed và muốn convention route giống Next.js (ít boilerplate định nghĩa navigator tay); React Navigation phù hợp khi cần kiểm soát chi tiết navigator (nested navigator phức tạp, custom transition, không dùng Expo).

## Anti-pattern

- Truyền callback function qua `navigation.navigate('Screen', { onDone: () => {} })` — param phải serializable được (deep link, state persistence sẽ vỡ), dùng state management/event emitter thay vì nhét function vào route param.
- Gọi `navigation.reset` bừa bãi để "chắc chắn" về đúng màn hình — chỉ dùng khi thật sự cần xóa lịch sử stack (sau login/logout), lạm dụng phá mất back button UX tự nhiên.
