---
name: react-native-dev
description: Nguyên tắc và convention viết React Native chuẩn — Expo vs bare workflow, state management, cấu trúc dự án, navigation (React Navigation/Expo Router), API integration & error handling, performance (Hermes, FlatList/FlashList, Reanimated), UI thích ứng & accessibility, testing (Jest/RNTL/Detox/Maestro), native module (bridge cũ vs JSI/TurboModules/Fabric). Dùng khi chạm file .tsx/.jsx trong dự án React Native, app.json/app.config.js, hoặc câu hỏi về React Native.
---

# React Native Dev Specialist

## Trước khi áp pattern nào — inspect codebase trước

- Đọc `package.json`: dependency nào đã có sẵn (`expo`, state management, navigation, HTTP client, test runner...) → dùng đúng lib đó, không đề xuất lib khác nếu lib hiện có đã đủ dùng.
- Xác định Expo managed workflow hay bare workflow: có `expo` trong dependencies + `app.json`/`app.config.js` + không có thư mục `ios/`/`android/` commit sẵn → managed; có `ios/`/`android/` native project → bare (hoặc Expo prebuild). Quyết định này chi phối mọi lựa chọn tiếp theo (thêm native module được không, dùng lệnh build nào).
- Đọc cấu trúc `src/` (hoặc `app/` nếu dùng Expo Router) hiện có: convention đặt tên, cách chia thư mục đã dùng trong repo → theo đúng convention đó thay vì convention mặc định bên dưới.
- Tìm tài liệu convention riêng của project (README, `docs/`, `CONTRIBUTING`) — có thì ưu tiên tài liệu đó; các mục dưới đây chỉ là fallback khi project chưa tự quyết định.
- Các nguyên tắc dưới áp dụng khi project chưa có lựa chọn sẵn — không ép đổi lib/kiến trúc đã ổn định trong dự án chỉ để khớp skill này.

## Nguyên tắc cốt lõi

- TypeScript mặc định cho project mới; không dùng `any` để né type lỗi, ưu tiên union type/generic đúng hoặc `unknown` + narrow.
- Component nhỏ, một nhiệm vụ; tách logic ra custom hook (`useXxx`) thay vì nhồi hết vào 1 component lớn.
- Không đọc/ghi trực tiếp native module ở tầng UI — bọc qua 1 lớp service/hook để UI không phụ thuộc trực tiếp API native.
- Không optimize sớm (`useMemo`/`useCallback`/`React.memo`) khi chưa đo được rebuild thừa là vấn đề thật — thêm memoization tùy tiện làm code khó đọc hơn mà chưa chắc nhanh hơn.
- Style bằng StyleSheet.create hoặc lib style đã có sẵn trong project (NativeWind, styled-components...) — không trộn nhiều cách style khác nhau trong cùng 1 feature.
- Fact nhạy version/deprecation (mốc feature default, package còn maintain hay đã deprecated) — verify doc chính thức trước khi khẳng định, ecosystem RN/Expo đổi nhanh hơn Flutter/native.

## Expo vs bare workflow — khi nào dùng gì

Managed Expo cho phần lớn app CRUD/business logic không cần native code custom; bare workflow (hoặc Expo prebuild + config plugin) chỉ khi cần native module không có SDK/Expo config plugin tương đương. Chi tiết: [references/expo-vs-bare.md](references/expo-vs-bare.md).

## State management

| Nhu cầu | Chọn |
| --- | --- |
| State cục bộ 1 component (form field, toggle) | `useState`/`useReducer` |
| Chia sẻ state vài component con cháu gần nhau | Context API |
| App lớn, nhiều luồng async, cần state predictable/testable | Zustand hoặc Redux Toolkit |
| Server state (fetch/cache/refetch dữ liệu API) | React Query (TanStack Query) — không tự chế cache bằng `useState` |
| Chưa chắc — dự án đã có sẵn lib nào | Dùng đúng lib đã có trong `package.json`, không trộn 2 giải pháp state khác nhau trong cùng 1 feature |

Chi tiết: [references/state-management.md](references/state-management.md).

## Cấu trúc dự án

Feature-first: mỗi feature 1 thư mục con (`src/features/<feature>/{screens,components,hooks,api}`), không gom hết component vào 1 thư mục `components/` phẳng toàn app. Chi tiết: [references/project-structure.md](references/project-structure.md).

## Navigation

Theo đúng cơ chế routing project đã chọn (React Navigation stack/tab/drawer, hoặc Expo Router file-based); route/param type định nghĩa tập trung, không rải `navigation.navigate('Screen', {...})` với param không type-check. Chi tiết: [references/navigation.md](references/navigation.md).

## API/network integration & error handling

Luôn có 1 lớp service/API client tách UI khỏi `fetch`/axios trực tiếp; phân biệt lỗi network/parse/business để UI hiển thị đúng thông điệp; không nuốt lỗi (empty catch), không rethrow lỗi gốc của HTTP client thẳng lên UI. Chi tiết: [references/api-integration-error-handling.md](references/api-integration-error-handling.md).

## Performance

Chỉ tối ưu khi đo được bằng Flipper/React DevTools Profiler, không đoán mò. `FlatList`/`FlashList` cho list dài (không `.map()` render hết), `react-native-reanimated` cho animation chạy trên UI thread thay vì `Animated` API JS-driven khi cần 60fps, kiểm tra Hermes đã bật. Chi tiết: [references/performance.md](references/performance.md).

## UI thích ứng & accessibility

`Dimensions`/`useWindowDimensions` cho responsive, `SafeAreaView`/`useSafeAreaInsets` cho notch/home indicator; `accessibilityLabel`, `accessibilityRole`, contrast WCAG AA, touch target ≥44pt là baseline tối thiểu, bắt buộc cho UI hướng người dùng cuối. Chi tiết: [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md).

## Testing

Mỗi bug fix/feature mới cần ít nhất 1 test Jest + React Native Testing Library cho logic/component non-trivial (branch, loop, custom hook). E2E (Detox/Maestro) cho luồng người dùng critical (login, checkout), không bắt buộc cho mọi PR. Chi tiết: [references/testing.md](references/testing.md).

## Native module / platform code

Chỉ viết native module (TurboModule/Fabric hoặc bridge cũ) khi Expo SDK/thư viện community không cover được API native cần dùng. Chi tiết: [references/native-modules.md](references/native-modules.md).

## Checklist hoàn thành

- `tsc --noEmit` (hoặc lint typecheck script của project) sạch.
- `eslint` sạch, không disable rule tùy tiện để né lỗi.
- Test liên quan đến thay đổi pass (`jest` hoặc script test của project).
