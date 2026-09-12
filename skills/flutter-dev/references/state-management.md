# State management — chi tiết

## setState

Dùng cho state không rời khỏi 1 widget và con cháu trực tiếp không cần đọc nó. Ví dụ: mở/đóng dropdown, giá trị slider đang kéo, trang hiện tại của `PageView`.

```dart
class _CounterState extends State<Counter> {
  int _count = 0;
  void _increment() => setState(() => _count++);
}
```

Sai lầm thường gặp: gọi `setState` trong `build()` hoặc trong callback bất đồng bộ sau khi widget đã dispose — luôn check `mounted` trước khi `setState` sau `await`.

## Provider / InheritedWidget

Dùng khi vài widget con cháu (không quá sâu) cần đọc chung 1 giá trị, không cần business logic phức tạp. `Provider.of<T>(context, listen: false)` cho action, `context.watch<T>()` cho rebuild theo thay đổi.

## Bloc

Dùng khi:
- Business logic có nhiều state rõ ràng (loading/success/error/empty) cần test độc lập UI.
- Luồng async phức tạp (debounce, race condition giữa nhiều event).

State đơn giản, không cần transform/debounce event → dùng `Cubit` (method gọi trực tiếp, không cần event class riêng). Cần event class tách biệt, transform luồng event (debounce, race condition) → dùng `Bloc`. Theo đúng cái project đã dùng, không tự đổi giữa 2 pattern trong cùng feature.

```dart
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState { final User user; AuthSuccess(this.user); }
class AuthError extends AuthState { final String message; AuthError(this.message); }
```

## Riverpod

Thay thế Provider khi cần: compile-time safety (không runtime `ProviderNotFoundException`), dễ test (override provider trong test), hoặc auto-dispose state không dùng nữa.

## Nguyên tắc chọn — tránh trộn lẫn

Không dùng 2 giải pháp state khác nhau cho cùng 1 luồng dữ liệu trong 1 feature (ví dụ vừa Bloc vừa Provider cho cùng 1 màn hình) — tăng chi phí đọc code mà không tăng lợi ích. Dự án đã chọn 1 giải pháp trong `pubspec.yaml` thì theo giải pháp đó, không tự ý thêm lib state management mới nếu chưa có trong dependency.
