---
name: android-native-dev
description: "Android native conventions: Kotlin, MVVM, Compose/View, DI, coroutines, lifecycle. Use when editing .kt/.java/build.gradle. Running on a device → android-cli."
---

# Android Native Dev Specialist

Read `rules/android.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/android.md`.

## Android-specific project inspection

| If you see | Conclusion |
|---|---|
| `@HiltAndroidApp` | Hilt |
| `@Component`/`@Module`, no `@HiltAndroidApp` | Classic Dagger 2 |
| `module { }` (Koin DSL) | Koin |
| XML for most screens | Follow View/XML |
| `@Composable` for most screens | Follow Compose |
| `StateFlow` / `LiveData` | Follow whichever is in use |
| Has `Repository`/`UseCase` | Follow that layer |
| ViewModel calls the service directly | Thin-MVVM, do not add layers |

## Default decisions

- Kotlin for new code; Java only when editing existing `.java` files.
- Do not add Repository/UseCase when the project is thin-MVVM.
- Do not mix 2 DI frameworks in the same module.
- Sealed class/interface for UI state, not several loose booleans.
- ViewModel must not hold a `Context`/`View` reference.
- WorkManager for background work that must run even if the app is killed.
- Use a version catalog if the project already does; do not declare version strings inline.

## Details

- Architecture: [references/architecture.md](references/architecture.md)
- Compose vs View: [references/ui-compose-vs-views.md](references/ui-compose-vs-views.md)
- Writing Composables: [references/jetpack-compose.md](references/jetpack-compose.md)
- Kotlin conventions: [references/kotlin-conventions.md](references/kotlin-conventions.md)
- Testing: [references/testing.md](references/testing.md)
- Lifecycle & state: [references/lifecycle-and-state.md](references/lifecycle-and-state.md)
- Navigation: [references/navigation.md](references/navigation.md)
- API & error handling: [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- Background & permissions: [references/background-and-permissions.md](references/background-and-permissions.md)
- Security/performance/accessibility: [references/security-performance-accessibility.md](references/security-performance-accessibility.md)
- Troubleshoot: [references/troubleshoot.md](references/troubleshoot.md)

## Verify

- `./gradlew :app:lintDebug`
- `./gradlew :app:testDebugUnitTest --tests "<Class>"`
- `./gradlew :app:assembleDebug`
- Task touches UI → run on a device/emulator via skill `android-cli`.
