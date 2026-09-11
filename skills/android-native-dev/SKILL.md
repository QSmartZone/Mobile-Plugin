---
name: android-native-dev
description: Nguyên tắc và convention viết Android native (Kotlin-first, Java khi maintain code cũ) — kiến trúc MVVM + Jetpack Compose, coroutines, testing, lifecycle & state restoration, navigation, API/error handling, background work & runtime permissions, security/performance/accessibility. Dùng khi chạm file .kt, .java trong module Android, build.gradle, hoặc câu hỏi về Android native dev như "xin runtime permission thế nào", "deep link không mở app".
---

# Android Native Dev Specialist

## Soi project trước

Trước khi code, đọc để biết project đang dùng gì — không tự ý đổi công nghệ nếu không được yêu cầu tường minh:

- `build.gradle`/`libs.versions.toml`: lib nào đã có.
- UI: layout XML hay `@Composable` chiếm đa số màn hình hiện có.
- ViewModel: expose `StateFlow` hay `LiveData`.
- DI thật sự dùng: `grep @HiltAndroidApp` (Hilt); có `@Component`/`@Module` nhưng không có `@HiltAndroidApp` → Dagger 2 classic; `module { }` của Koin → Koin.
- Có layer `Repository`/`UseCase` hay ViewModel gọi thẳng service/API.

Rồi theo đúng cái project đã có.

## Ngôn ngữ

Kotlin cho mọi code mới. Java chỉ khi sửa file `.java` sẵn có trong dự án — không tự ý viết lớp Kotlin mới xen giữa 1 class Java cũ nếu chưa được yêu cầu migrate, và không migrate ngược Kotlin→Java.

## Kiến trúc — MVVM + Jetpack mặc định

- UI: theo toolkit project đã dùng (Compose hay XML+View/DataBinding); Compose chỉ là khuyến nghị mặc định khi project hoàn toàn chưa có tiền lệ (project mới, hoặc thêm 1 screen độc lập không phụ thuộc UI cũ). Chọn Compose hay XML/View: [references/ui-compose-vs-views.md](references/ui-compose-vs-views.md). Viết Composable: [references/jetpack-compose.md](references/jetpack-compose.md).
- `ViewModel` giữ state UI (thường là `StateFlow`/`LiveData`), không giữ reference `Context`/`View` (leak).
- `Repository`: project đã có Repository thì theo đúng convention đó. Project thin-MVVM chưa có Repository/UseCase (ViewModel gọi thẳng service) thì không tự thêm layer mới chỉ vì "đúng chuẩn" — chỉ đề xuất thêm khi có nhu cầu cụ thể (nhiều nguồn dữ liệu, cần cache, test cần fake nguồn).
- Dependency injection: dùng lib đã có trong dự án — Hilt, Koin, hoặc Dagger 2 classic (nhận diện qua `@Component`/`@Module` không có `@HiltAndroidApp`) — không trộn 2 DI framework trong cùng module.

Chi tiết: [references/architecture.md](references/architecture.md).

## Kotlin conventions

- Coroutines + `Flow` cho async, không dùng callback lồng nhau kiểu Java cũ trong code Kotlin mới.
- Null-safety triệt để: tránh `!!`, dùng `?:`/`let`/sealed class để model rõ trạng thái thiếu dữ liệu.
- Sealed class/interface để model UI state (Loading/Success/Error) thay vì nhiều boolean flag rời rạc.

Chi tiết: [references/kotlin-conventions.md](references/kotlin-conventions.md).

## Testing

JUnit cho logic (ViewModel, Repository, UseCase) với coroutine test dispatcher. Espresso cho UI test trên View cũ, Compose UI test (`createComposeRule`) cho màn hình Compose. Mỗi ViewModel mới cần test cover ít nhất luồng thành công + luồng lỗi. Chi tiết: [references/testing.md](references/testing.md).

## Lifecycle & state restoration

Xử lý config change (xoay màn hình), process death, và save/restore state qua `onSaveInstanceState`/`SavedStateHandle` thay vì để ViewModel mất state khi Activity bị hệ thống giết. Không giữ reference `Context`/`View` sống lâu hơn lifecycle của nó.

Chi tiết: [references/lifecycle-and-state.md](references/lifecycle-and-state.md).

## Navigation

Điều hướng theo cơ chế project đã dùng (Navigation Component, Compose Navigation, hoặc điều hướng thủ công bằng Intent/FragmentTransaction) — không tự đổi cơ chế nếu không được yêu cầu. Truyền dữ liệu giữa màn hình qua argument có kiểu, tránh singleton/global state để pass data.

Chi tiết: [references/navigation.md](references/navigation.md).

## API integration & xử lý lỗi

Gọi network qua lib đã có trong dự án (Retrofit, Ktor, Volley...), map lỗi HTTP/network/parse thành state UI rõ ràng (không nuốt exception). Timeout, retry, và offline đều là error path cần xử lý ngang hàng happy path.

Chi tiết: [references/api-integration-error-handling.md](references/api-integration-error-handling.md).

## Background work & permissions

Dùng WorkManager cho tác vụ nền cần đảm bảo chạy, Coroutine scope đúng lifecycle cho tác vụ ngắn hạn. Xin runtime permission đúng thời điểm cần dùng, xử lý cả trường hợp user từ chối/permanently denied.

Chi tiết: [references/background-and-permissions.md](references/background-and-permissions.md).

## Bảo mật, hiệu năng, accessibility

Không hardcode secret trong code, validate input ở boundary. Tránh block main thread, kiểm tra leak (LeakCanary nếu dự án đã dùng). Accessibility: content description, touch target size, contrast tối thiểu cho UI mới.

Chi tiết: [references/security-performance-accessibility.md](references/security-performance-accessibility.md).

## Gradle

Thêm dependency mới → kiểm tra `build.gradle`/`libs.versions.toml` đã có lib tương đương chưa trước khi thêm. Dùng version catalog (`libs.versions.toml`) nếu dự án đã dùng, không quay lại khai version string trực tiếp trong từng module.
