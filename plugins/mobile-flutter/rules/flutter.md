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
- In **SDK modules** (`sdk/*` or packages): strictly headless. No UI widgets, no `flutter_bloc`, no routing, no hardcoded fakes. Return `ResultDart<T, ModuleFailure>`. Zero cross-SDK imports; dependencies (`Dio`, callbacks) must be injected via `ModuleConfig`.
- In **Application layer** (`apps/*` or consumer apps): wire SDK modules in `di.dart`/bootstrap. UI, Blocs, router, fakes, and design tokens live here. Do not change state management or `lib/` structure without explicit request.

**Network errors & Boundaries:**
- Widgets do not call the HTTP client directly; go through a repository/service.
- SDK modules: never throw exceptions across the module boundary; map HTTP/runtime errors into module-specific failure types.
- App layer: distinguish network errors (`DioException`/`SocketException`), parse errors (`FormatException`/`TypeError` in `fromJson`), and business errors. Do not swallow exceptions, do not push raw error messages to the UI.

**UI baseline:**
- Touch target ≥48×48 logical px (`kMinInteractiveDimension`), contrast meeting WCAG AA, `Semantics`/`tooltip` for icon-only buttons.
- Null-safety: do not use `!` unless sure it is non-null; prefer `?.`, `??`, check `mounted` after `await` before using `context`.

**Out of scope:**
- New `MethodChannel`/platform channel, changing the state lib app-wide → stop, state the reason.

**Commands by usecase:** see `skills/flutter-dev/references/commands.md` (when to run format/analyze/run/clean/gen-l10n/build) and `skills/flutter-dev/references/dart-mcp.md` (hot reload, runtime errors, widget tree). Never `flutter build apk|appbundle` for verify/dev.
