# Compose vs View/XML — chọn khi nào

## Bảng quyết định

| Tình huống | Chọn |
| --- | --- |
| Project mới hoàn toàn, chưa có UI code | Compose |
| Project legacy 100% XML, thêm 1 screen mới độc lập | Compose qua `ComposeView` interop (không bắt migrate toàn app) |
| Project legacy đang Activity/Fragment phức tạp, chỉ cần sửa nhỏ | Giữ nguyên XML/View — không đổi toolkit giữa chừng chỉ vì tiện |
| Screen đã Compose, cần thêm 1 phần nhỏ tương tác View-only (ví dụ AdMob SDK view) | `AndroidView` interop chiều ngược lại, không quay về full XML |

Nguyên tắc chung: 1 screen chỉ dùng 1 toolkit chính. Đổi toolkit là quyết định kiến trúc, không phải tiện tay.

## Nhận diện project đang dùng gì

```
grep -rl "@Composable\|setContent(" app/src/main/java   # có Compose
grep -rl "findViewById\|ViewBinding\|DataBinding" app/src/main/java
find app/src/main/res/layout -name "*.xml"               # dùng View truyền thống
```

Có cả hai dấu hiệu → project đang ở giai đoạn migrate dần (hybrid), kiểm tra screen cụ thể đang sửa dùng gì trước khi quyết định.

## Thêm màn Compose vào app legacy XML

Đặt `ComposeView` trong layout XML của Fragment/Activity cũ, gọi `setContent` trong `onViewCreated`/`onCreate`:

```xml
<androidx.compose.ui.platform.ComposeView
    android:id="@+id/composeView"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    binding.composeView.apply {
        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
        setContent {
            BookingScreen(onBook = { viewModel.book() })
        }
    }
}
```

Đây là interop 1 chiều (Compose nhúng trong View) — không cần rewrite navigation hay kiến trúc hiện có. Chi tiết viết Composable: [jetpack-compose.md](jetpack-compose.md).

## Bẫy cụ thể

- Quên set `ViewCompositionStrategy` phù hợp khi nhúng `ComposeView` trong Fragment (mặc định `DisposeOnDetachedFromWindowOrReleasedFromPool` không dispose đúng lúc trong nested Fragment/ViewPager) → Composable leak, không dispose khi Fragment bị destroy.
- `findViewById` gọi sau khi View đã destroy (ví dụ trong callback bất đồng bộ chạy sau `onDestroyView`) → `NullPointerException` hoặc crash.
- Trộn state quản lý ở cả XML View lẫn Compose cho cùng 1 màn hình (vd loading state vừa set qua `ProgressBar.visibility` vừa qua `mutableStateOf`) → khó debug, nên chọn 1 toolkit cho 1 màn hình.
