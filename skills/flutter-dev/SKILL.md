---
name: flutter-dev
description: Convention Flutter/Dart — widget, state management, cấu trúc lib/, routing, API/error handling, performance, test. Dùng khi sửa .dart/pubspec.yaml. SDK đa package/white-label → dùng flutter-sdk-platform.
---

# Flutter Dev Specialist

Đọc `rules/mobile-common.md` ở plugin root trước. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/mobile-common.md`.

## Soi project đặc thù Flutter

- Đọc `pubspec.yaml`: state management lib đã dùng (Provider/Bloc/Riverpod...) → theo đúng lib đó.
- Routing lib đã chọn (Navigator 1.0/`go_router`/`auto_route`) → không đổi cơ chế.
- Cấu trúc `lib/` hiện có (feature-first hay layer-first) → theo convention repo, không áp mặc định.

## State management — khi nào dùng gì

| Nhu cầu | Chọn |
| --- | --- |
| State cục bộ 1 widget (toggle, animation) | `setState` |
| Chia sẻ state vài widget con cháu gần nhau | `InheritedWidget`/`Provider` |
| App lớn, nhiều luồng async, cần testable business logic tách khỏi UI | `Bloc` hoặc `Riverpod` |
| Chưa chắc — dự án đã có sẵn lib nào | Dùng đúng lib đã có, không trộn 2 giải pháp state trong cùng 1 feature |

## Quyết định hay sai

- `const` constructor mọi nơi có thể.
- Tách `build()` dài thành widget con, không method trả `Widget`.
- Không gọi `setState` cho state cross-widget.
- `ListView.builder`/`GridView.builder` cho danh sách dài, không `ListView(children:...)`.
- Không trộn 2 lib state management trong cùng 1 feature.
- Không viết `MethodChannel` khi package có sẵn đã cover API cần dùng.

**Nếu** task là SDK đa package/white-label → dùng skill `flutter-sdk-platform`.

## References

- [references/state-management.md](references/state-management.md)
- [references/project-structure.md](references/project-structure.md)
- [references/navigation.md](references/navigation.md)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/performance.md](references/performance.md)
- [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md)
- [references/testing.md](references/testing.md)
- [references/platform-channels.md](references/platform-channels.md)
- [references/troubleshoot.md](references/troubleshoot.md)

`flutter pub get` treo trên máy có proxy/firewall → thử `--offline`.

## Verify

- `flutter analyze` — sạch, không warning mới.
- `flutter test test/<file>_test.dart` — chỉ file liên quan vừa sửa.
- `flutter test` toàn bộ chỉ khi user yêu cầu.
- Hot reload theo `rules/hot_reload.md`.
