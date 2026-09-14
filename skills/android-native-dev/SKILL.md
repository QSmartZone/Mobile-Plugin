---
name: android-native-dev
description: "Convention Android native (Kotlin, MVVM, Compose/View, DI, coroutines, lifecycle, testing). Dùng khi sửa file .kt/.java, build.gradle trong module Android. Không dùng khi cần chạy trên device/emulator, dùng skill android-cli."
---

# Android Native Dev Specialist

Đọc `rules/mobile-common.md` ở plugin root trước. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/mobile-common.md`.

## Soi project đặc thù Android

| Nếu thấy | Kết luận |
|---|---|
| `@HiltAndroidApp` | Hilt |
| `@Component`/`@Module`, không `@HiltAndroidApp` | Dagger 2 classic |
| `module { }` (Koin DSL) | Koin |
| XML chiếm đa số màn hình | Theo View/XML |
| `@Composable` chiếm đa số | Theo Compose |
| `StateFlow` / `LiveData` | Theo cái đang dùng |
| Có `Repository`/`UseCase` | Theo layer đó |
| ViewModel gọi thẳng service | Thin-MVVM, không thêm layer |

## Quyết định mặc định

- Kotlin cho code mới; Java chỉ khi sửa file `.java` sẵn có.
- Không tự thêm Repository/UseCase khi project đang thin-MVVM.
- Không trộn 2 DI framework trong cùng module.
- Sealed class/interface cho UI state, không dùng nhiều boolean rời rạc.
- ViewModel không giữ reference `Context`/`View`.
- WorkManager cho việc nền cần đảm bảo chạy dù app bị kill.
- Dùng version catalog nếu dự án đã dùng, không khai version string trực tiếp.

## Chi tiết

- Kiến trúc: [references/architecture.md](references/architecture.md)
- Compose vs View: [references/ui-compose-vs-views.md](references/ui-compose-vs-views.md)
- Viết Composable: [references/jetpack-compose.md](references/jetpack-compose.md)
- Kotlin conventions: [references/kotlin-conventions.md](references/kotlin-conventions.md)
- Testing: [references/testing.md](references/testing.md)
- Lifecycle & state: [references/lifecycle-and-state.md](references/lifecycle-and-state.md)
- Navigation: [references/navigation.md](references/navigation.md)
- API & error handling: [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- Background & permissions: [references/background-and-permissions.md](references/background-and-permissions.md)
- Bảo mật/hiệu năng/accessibility: [references/security-performance-accessibility.md](references/security-performance-accessibility.md)
- Troubleshoot: [references/troubleshoot.md](references/troubleshoot.md)

## Verify

- `./gradlew :app:lintDebug`
- `./gradlew :app:testDebugUnitTest --tests "<Class>"`
- `./gradlew :app:assembleDebug`
- Task chạm UI → chạy trên device/emulator qua skill `android-cli`.
