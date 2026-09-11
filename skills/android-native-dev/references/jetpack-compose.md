# Jetpack Compose — chi tiết

So sánh khi nào chọn Compose vs XML/View: [ui-compose-vs-views.md](ui-compose-vs-views.md).

## State hoisting

Composable nên stateless — nhận state + callback từ caller, không tự giữ state nghiệp vụ bên trong bằng biến thường. Giúp Composable preview được, test độc lập được, và reuse ở nhiều nơi.

```kotlin
@Composable
fun Counter(count: Int, onIncrement: () -> Unit) {
    Button(onClick = onIncrement) { Text("Count: $count") }
}
```

Caller (thường là màn hình cha hoặc ViewModel) giữ `count`, Composable con chỉ hiển thị và phát event lên.

## remember vs rememberSaveable vs ViewModel

- `remember`: sống trong composition, mất khi rotate (config change) — dùng cho state UI thuần tuý không cần giữ (ví dụ trạng thái animation tạm).
- `rememberSaveable`: sống qua config change, dùng cho state UI đơn giản, serializable (ví dụ text field đang gõ, tab đang chọn).
- `ViewModel`: state cần sống qua việc Composable bị dispose hoàn toàn (navigate away rồi back), hoặc state nghiệp vụ cần chia sẻ/test độc lập với UI.

## Side-effect API

- `LaunchedEffect(key)`: chạy coroutine khi `key` thay đổi (hoặc lần đầu vào composition) — dùng khi cần gọi API lúc màn hình mở.
- `DisposableEffect(key)`: cần cleanup khi rời composition — đăng ký/huỷ đăng ký listener.
- `SideEffect`: đồng bộ Compose state ra hệ thống non-Compose (analytics, logging) sau mỗi recomposition thành công.

```kotlin
@Composable
fun BookingScreen(viewModel: BookingViewModel) {
    LaunchedEffect(Unit) {
        viewModel.load()
    }
    // ...
}
```

Không gọi trực tiếp suspend function hoặc side-effect ngay trong body Composable — chạy lại mỗi lần recomposition, không có lifecycle kiểm soát.

## Performance

- Ưu tiên data class/immutable cho state truyền vào Composable (List → `ImmutableList` từ `kotlinx.collections.immutable` nếu có, hoặc đảm bảo state stable) để Compose compiler biết bỏ qua recomposition không cần thiết.
- Dùng `key(item.id)` trong `LazyColumn`/`LazyRow` khi list có thể đổi thứ tự/thêm xoá, tránh Compose match sai item.
- Tránh tạo lambda mới mỗi recomposition truyền xuống Composable con nặng — nếu đo thấy vấn đề, bọc bằng `remember { }` hoặc dùng method reference ổn định.

```kotlin
LazyColumn {
    items(bookings, key = { it.id }) { booking ->
        BookingRow(booking)
    }
}
```

## Tích hợp ViewModel

Dùng `collectAsStateWithLifecycle()` (từ `androidx.lifecycle:lifecycle-runtime-compose`) thay vì `collectAsState()` trần, để tự dừng collect Flow khi màn hình vào background — tránh update UI thừa/leak.

```kotlin
val state by viewModel.state.collectAsStateWithLifecycle()
```

## Testing

Dùng `createComposeRule()`, tìm node qua semantics (`onNodeWithText(...)`, `onNodeWithTag(...)` — đặt `Modifier.testTag(...)` khi cần) thay vì tìm theo id XML (không tồn tại trong Compose). Chi tiết ví dụ đầy đủ: [testing.md](testing.md).

## Bẫy cụ thể

- Quên `key()` trong `LazyColumn` → re-render nhầm item khi list đổi thứ tự.
- Đặt side-effect logic (gọi API, ghi log) thẳng trong body Composable thay vì trong `LaunchedEffect` → chạy lại mỗi lần recomposition, gây gọi API lặp.
- State chưa hoisted (Composable tự giữ state nội bộ bằng property ngoài `remember`) → không preview được, không test độc lập được.
- Thứ tự `Modifier` sai làm hành vi khác ý muốn: `Modifier.padding(8.dp).clickable { }` (padding rồi mới clickable — vùng bấm nhỏ hơn) khác `Modifier.clickable { }.padding(8.dp)` (clickable rồi mới padding — vùng bấm lớn hơn, bao gồm cả padding).
