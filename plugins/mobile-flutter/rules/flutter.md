---
trigger: glob
globs: ["**/*.dart", "**/pubspec.yaml"]
description: General Flutter/Dart rules
---

# Flutter — general rules

**Inspect the project first:**
- Read `pubspec.yaml` + `analysis_options.yaml` before editing.
- Follow the existing state/routing/HTTP libs (`flutter_bloc`/`riverpod`/`provider`, `go_router`, `dio`...). Do not propose a new lib when the existing one suffices.

**Preserve the architecture (SDK vs App):**
- In **SDK modules** (`sdk/`): strictly headless. No UI widgets, no `flutter_bloc`, no routing, no hardcoded fakes. Return `ResultDart<T, ModuleFailure>`. Zero cross-SDK imports; dependencies (`Dio`, callbacks) must be injected via `ModuleConfig`.
- In **Application layer** (`o2o_platform/*`, consumer apps): wire SDK modules in `di.dart`/bootstrap. UI, Blocs, router, fakes, and design tokens live here. Do not change state management or `lib/` structure without explicit request.

**Network errors & Boundaries:**
- Widgets do not call the HTTP client directly; go through a repository/service.
- SDK modules: never throw exceptions across the module boundary; map HTTP/runtime errors into module-specific failure types.
- App layer: distinguish network errors (`DioException`/`SocketException`), parse errors (`FormatException`/`TypeError` in `fromJson`), and business errors. Do not swallow exceptions, do not push raw error messages to the UI.

**UI baseline:**
- Touch target ≥48×48 logical px (`kMinInteractiveDimension`), contrast meeting WCAG AA, `Semantics`/`tooltip` for icon-only buttons.
- Null-safety: do not use `!` unless sure it is non-null; prefer `?.`, `??`, check `mounted` after `await` before using `context`.

**Out of scope:**
- New `MethodChannel`/platform channel, changing the state lib app-wide → stop, state the reason.

**Commands by usecase:**

| Usecase | Command | Note |
| --- | --- | --- |
| Static analysis / Lint check | `flutter analyze` | Stop at first error |
| Live preview / Debug / Check UI & logic | `flutter run --dart-define-from-file=<env>` | Dev loop, hot reload enabled |
| Hot reload after edit | `hot_reload` (Dart MCP) | Stateful changes require restart |
| Full state / main() reset | `hot_restart` (Dart MCP) | Resets state |
| Inspect widget hierarchy | `widget_inspector` (Dart MCP) | Verify rendered layout |
| Check runtime exceptions | `get_runtime_errors` (Dart MCP) | Check crashes & assertion failures |
| Dependency install / resolve | `flutter pub get` | Use `--offline` if network hangs |
| Clean stale build cache | `flutter clean && flutter pub get` | Run when build is corrupted |
| Localization update | `flutter gen-l10n` | Run after editing `.arb` |
| Build release APK / bundle | `flutter build apk` / `flutter build appbundle` | **Only** for artifact delivery, NEVER for verify/dev |
