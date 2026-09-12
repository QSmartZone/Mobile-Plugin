---
name: react-native-dev
description: Convention React Native — Expo vs bare, state management, navigation, performance, testing, native module. Dùng khi chạm file .tsx/.jsx RN, app.json/app.config.js, hoặc câu hỏi React Native. Không dùng khi: web React thuần, Flutter, native thuần.
---

# React Native Dev Specialist

Đọc `rules/mobile-common.md` ở plugin root trước. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/mobile-common.md`.

## Soi project trước

| Nếu thấy | Kết luận |
| --- | --- |
| `expo` + `app.json`, không `ios/`/`android/` | Managed Expo |
| Có `ios/`/`android/` | Bare workflow (hoặc đã prebuild) |
| Có thư mục `app/` | Expo Router |
| State lib có sẵn trong `package.json` | Dùng đúng lib đó |

## Quyết định hay sai

- TypeScript mặc định; không dùng `any`.
- Tách logic phức tạp ra custom hook.
- List dài dùng `FlatList`/`FlashList`, không `.map()`.
- Không memo hoá khi chưa đo được rebuild thừa.
- Không tự chế cache server state — dùng React Query nếu đã chọn.
- Không viết native module mới khi Expo/community đã cover.
- Fact deprecation RN/Expo đổi nhanh — verify doc chính thức trước khi khẳng định.

## State management

| Nhu cầu | Chọn |
| --- | --- |
| State cục bộ 1 component | `useState`/`useReducer` |
| Chia sẻ vài component gần nhau | Context API |
| App lớn, nhiều luồng async | Zustand hoặc Redux Toolkit |
| Server state (fetch/cache API) | React Query (TanStack Query) |

Chi tiết: [references/state-management.md](references/state-management.md).

## References

[expo-vs-bare](references/expo-vs-bare.md) · [project-structure](references/project-structure.md) · [navigation](references/navigation.md) · [api-integration-error-handling](references/api-integration-error-handling.md) · [performance](references/performance.md) · [ui-adaptive-accessibility](references/ui-adaptive-accessibility.md) · [testing](references/testing.md) · [native-modules](references/native-modules.md) · [troubleshoot](references/troubleshoot.md)

## Verify

- `tsc --noEmit` sạch.
- `eslint` sạch, không disable rule tùy tiện.
- `npx jest <path>` cho file liên quan.
- `npx expo run:ios|android` hoặc `npx react-native run-android` khi chạm native.
