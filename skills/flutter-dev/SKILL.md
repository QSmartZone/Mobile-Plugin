---
name: flutter-dev
description: Nguyên tắc và convention viết Flutter/Dart chuẩn — null-safety, widget composition, state management, cấu trúc package, testing. Dùng khi chạm file .dart, pubspec.yaml, hoặc câu hỏi về Flutter. Load kèm rules/hot_reload.md khi sửa code.
---

# Flutter Dev Specialist

## Nguyên tắc cốt lõi

- Null-safety triệt để: không `!` bừa bãi, ưu tiên `late`/default value/early return thay vì force-unwrap khi không chắc giá trị tồn tại.
- Widget nhỏ, một nhiệm vụ. Tách `build()` dài thành widget con thay vì method trả `Widget` (method không được Flutter DevTools tree hoá, khó rebuild riêng lẻ).
- `const` constructor mọi nơi có thể — cắt rebuild thừa mà không cần đo trước.
- StatelessWidget mặc định. Chỉ StatefulWidget khi thật sự cần local mutable state (animation controller, text controller, focus).
- Không gọi `setState` cho state cross-widget — leak sang bản đồ state phức tạp không kiểm soát được.

## State management — khi nào dùng gì

| Nhu cầu | Chọn |
| --- | --- |
| State cục bộ 1 widget (toggle, animation) | `setState` |
| Chia sẻ state vài widget con cháu gần nhau | `InheritedWidget`/`Provider` |
| App lớn, nhiều luồng async, cần testable business logic tách khỏi UI | `Bloc`/`Cubit` hoặc `Riverpod` |
| Chưa chắc — dự án đã có sẵn lib nào | Dùng đúng lib đã có trong `pubspec.yaml`, không trộn 2 giải pháp state khác nhau trong cùng 1 feature |

Chi tiết: [references/state-management.md](references/state-management.md).

## Cấu trúc dự án

Feature-first: mỗi feature 1 thư mục con (`lib/src/features/<feature>/{screens,widgets,blocs,models}`), không gom hết widget vào 1 thư mục `widgets/` phẳng toàn app. Chi tiết: [references/project-structure.md](references/project-structure.md).

Task là **thiết kế/tái cấu trúc SDK đa package** (nhiều pub package path-dependency, white-label nhiều tenant) chứ không phải sửa 1 feature trong 1 app đơn — đó là phạm vi skill `flutter-sdk-platform`, không phải skill này.

## Testing

Mỗi bug fix/feature mới cần ít nhất 1 widget test hoặc unit test cho logic non-trivial (branch, loop, parser). Golden test cho UI có risk visual regression cao. Chi tiết: [references/testing.md](references/testing.md).

## Platform channel (native code)

Chỉ viết `MethodChannel`/`EventChannel` khi Flutter/package có sẵn không cover được API native cần dùng. Chi tiết: [references/platform-channels.md](references/platform-channels.md).

## Tooling — lưu ý tuỳ máy

`flutter pub get` online có thể treo vô hạn trên một số máy (proxy/firewall/DNS công ty) — nếu gặp, thử `--offline` khi cache đã có sẵn package cần, hoặc kiểm tra mạng trước khi báo lỗi ngược lên user. Đây là ghi chú tuỳ môi trường, không phải bất biến của Flutter.

Trước khi báo hoàn thành: `flutter analyze` sạch, test liên quan pass.
