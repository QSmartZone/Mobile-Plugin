---
name: flutter-dev
description: Nguyên tắc và convention viết Flutter/Dart chuẩn — null-safety, widget composition, state management, cấu trúc package, navigation/routing, API integration & error handling, performance, responsive & accessibility, testing. Dùng khi chạm file .dart, pubspec.yaml, hoặc câu hỏi về Flutter. Load kèm rules/hot_reload.md khi sửa code.
---

# Flutter Dev Specialist

## Trước khi áp bất kỳ pattern nào — inspect codebase trước

- Đọc `pubspec.yaml`: lib nào đã có sẵn (HTTP client, state management, routing...) → dùng đúng lib đó, không đề xuất lib khác nếu lib hiện có đã đủ dùng.
- Đọc cấu trúc `lib/` hiện có: convention đặt tên, cách chia thư mục đã dùng trong repo → theo đúng convention đó thay vì convention mặc định bên dưới.
- Tìm tài liệu convention riêng của project (README, `docs/`, `CONTRIBUTING`, thư mục instruction riêng) — có thì ưu tiên tài liệu đó; các mục dưới đây chỉ là fallback khi project chưa tự quyết định.
- Các nguyên tắc dưới áp dụng khi project chưa có lựa chọn sẵn — không ép đổi lib/kiến trúc đã ổn định trong dự án chỉ để khớp skill này.

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
| App lớn, nhiều luồng async, cần testable business logic tách khỏi UI | `Bloc` hoặc `Riverpod` |
| Chưa chắc — dự án đã có sẵn lib nào | Dùng đúng lib đã có trong `pubspec.yaml`, không trộn 2 giải pháp state khác nhau trong cùng 1 feature |

Chi tiết: [references/state-management.md](references/state-management.md).

## Cấu trúc dự án

Feature-first: mỗi feature 1 thư mục con (`lib/src/features/<feature>/{screens,widgets,blocs,models}`), không gom hết widget vào 1 thư mục `widgets/` phẳng toàn app. Chi tiết: [references/project-structure.md](references/project-structure.md).

Task là **thiết kế/tái cấu trúc SDK đa package** (nhiều pub package path-dependency, white-label nhiều tenant) chứ không phải sửa 1 feature trong 1 app đơn — đó là phạm vi skill `flutter-sdk-platform`, không phải skill này.

## Navigation/routing

Theo đúng cơ chế routing project đã chọn (Navigator 1.0 named routes / `go_router` / `auto_route`); route definition tập trung 1 nơi, không rải `Navigator.push(MaterialPageRoute(...))` hardcode khắp nơi. Chi tiết: [references/navigation.md](references/navigation.md).

## API/network integration & error handling

Luôn có 1 lớp repository tách UI khỏi HTTP client trực tiếp; phân biệt lỗi network/parse/business để UI hiển thị đúng thông điệp; không bắt exception ở tầng UI, không rethrow exception gốc của HTTP client lên UI. Chi tiết: [references/api-integration-error-handling.md](references/api-integration-error-handling.md).

## Performance

Chỉ tối ưu khi đo được bằng DevTools, không đoán mò. `ListView.builder` cho list dài, `compute()`/`Isolate.run()` cho tác vụ CPU nặng, `Selector`/`BlocSelector` khi rebuild thừa đã đo là vấn đề thật. Chi tiết: [references/performance.md](references/performance.md).

## UI thích ứng & accessibility

`MediaQuery`/`LayoutBuilder` cho responsive; `Semantics`, contrast WCAG AA, touch target ≥48dp là baseline tối thiểu, bắt buộc cho UI hướng người dùng cuối. Chi tiết: [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md).

## Testing

Mỗi bug fix/feature mới cần ít nhất 1 widget test hoặc unit test cho logic non-trivial (branch, loop, parser). Golden test cho UI có risk visual regression cao. Chi tiết: [references/testing.md](references/testing.md).

## Platform channel (native code)

Chỉ viết `MethodChannel`/`EventChannel` khi Flutter/package có sẵn không cover được API native cần dùng. Chi tiết: [references/platform-channels.md](references/platform-channels.md).

## Tooling — lưu ý tuỳ máy

`flutter pub get` online có thể treo vô hạn trên một số máy (proxy/firewall/DNS công ty) — nếu gặp, thử `--offline` khi cache đã có sẵn package cần, hoặc kiểm tra mạng trước khi báo lỗi ngược lên user. Đây là ghi chú tuỳ môi trường, không phải bất biến của Flutter.

Trước khi báo hoàn thành: `flutter analyze` sạch, test liên quan pass.
