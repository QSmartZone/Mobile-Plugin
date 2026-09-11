---
name: android-native-dev
description: Nguyên tắc và convention viết Android native (Kotlin-first, Java khi maintain code cũ) — kiến trúc MVVM + Jetpack, coroutines, testing. Dùng khi chạm file .kt, .java trong module Android, build.gradle, hoặc câu hỏi về Android native dev.
---

# Android Native Dev Specialist

## Ngôn ngữ

Kotlin cho mọi code mới. Java chỉ khi sửa file `.java` sẵn có trong dự án — không tự ý viết lớp Kotlin mới xen giữa 1 class Java cũ nếu chưa được yêu cầu migrate, và không migrate ngược Kotlin→Java.

## Kiến trúc — MVVM + Jetpack mặc định

- UI: Jetpack Compose mặc định cho màn hình mới. XML layout + View chỉ khi maintain code cũ.
- `ViewModel` giữ state UI (thường là `StateFlow`/`LiveData`), không giữ reference `Context`/`View` (leak).
- `Repository` là nguồn dữ liệu duy nhất ViewModel gọi — không để ViewModel gọi thẳng network/DB.
- Dependency injection: dùng lib đã có trong dự án (Hilt hoặc Koin) — không trộn 2 DI framework trong cùng module.

Chi tiết: [references/architecture.md](references/architecture.md).

## Kotlin conventions

- Coroutines + `Flow` cho async, không dùng callback lồng nhau kiểu Java cũ trong code Kotlin mới.
- Null-safety triệt để: tránh `!!`, dùng `?:`/`let`/sealed class để model rõ trạng thái thiếu dữ liệu.
- Sealed class/interface để model UI state (Loading/Success/Error) thay vì nhiều boolean flag rời rạc.

Chi tiết: [references/kotlin-conventions.md](references/kotlin-conventions.md).

## Testing

JUnit cho logic (ViewModel, Repository, UseCase) với coroutine test dispatcher. Espresso cho UI test trên View cũ, Compose UI test (`createComposeRule`) cho màn hình Compose. Mỗi ViewModel mới cần test cover ít nhất luồng thành công + luồng lỗi. Chi tiết: [references/testing.md](references/testing.md).

## Gradle

Thêm dependency mới → kiểm tra `build.gradle`/`libs.versions.toml` đã có lib tương đương chưa trước khi thêm. Dùng version catalog (`libs.versions.toml`) nếu dự án đã dùng, không quay lại khai version string trực tiếp trong từng module.
