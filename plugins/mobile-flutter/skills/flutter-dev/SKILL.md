---
name: flutter-dev
description: "Flutter/Dart conventions: widgets, state, lib/ structure, routing, error handling, performance. Use when editing .dart/pubspec.yaml."
---

# Flutter Dev Specialist

Read `rules/flutter.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/flutter.md`.

## Inspect the Flutter context first (SDK vs App)

Identify which target context the current task belongs to:
1. **SDK Package Development** (e.g. `sdk/o2o_*` or standalone pub package):
   - **Headless & pure domain**: No UI widgets, no Flutter `Bloc`/`Cubit`, no routers, no hardcoded fakes.
   - **Boundary & errors**: Return typed results (e.g., `ResultDart<Success, Failure>`) with module-scoped failures. Never throw uncaught exceptions across module boundaries.
   - **Self-contained**: No SDK package imports another sibling SDK package. Dependency injection (e.g. HTTP client, session tokens, config) is injected from the host/consumer.
   - **Architecture & Layering**: For designing or restructuring multi-package SDKs, refer to `mobile-flutter:flutter-sdk-platform`.
2. **Application & App Shell Development** (e.g. `o2o_platform/*`, consumer apps):
   - **Follow existing lib**: State management (`flutter_bloc`, `riverpod`, `provider`), routing (`go_router`, named routes), and HTTP setup already in `pubspec.yaml`.
   - **Feature layout**: Feature-first folders directly under `lib/` (or `lib/src/`) without unnecessary extra nestings unless repo convention dictates.
   - **Composition**: The app or shared app shell wires SDK modules together in `di.dart` / bootstrap.

## State management — what to use when

| Need | Choose |
| --- | --- |
| Local state of a single widget (toggle, animation) | `setState` |
| Share state among a few nearby descendant widgets | `InheritedWidget`/`Provider` |
| Large app, many async flows, business logic kept separate from UI | `Bloc` or `Riverpod` |
| Unsure — project already has a lib | Use the existing lib; do not mix 2 state solutions in the same feature |
| Headless SDK package | Do NOT use UI state management; use pure Dart streams, callbacks, or result objects |

## Commonly wrong decisions

- `const` constructor wherever possible.
- Split a long `build()` into child widgets, not methods returning `Widget`.
- Do not call `setState` for cross-widget state.
- `ListView.builder`/`GridView.builder` for long lists, not `ListView(children:...)`.
- Do not mix 2 state management libs in the same feature.
- Do not write a `MethodChannel` when an existing package already covers the needed API.
- Do not add UI widgets, Flutter Bloc, or route handlers inside a headless SDK package.

**If** the task is designing or structuring a multi-package SDK, path-dependency linking, or white-label theming → use skill `flutter-sdk-platform`.

## References

- [references/project-structure.md](references/project-structure.md) (covers app layout vs headless SDK layer-first layout)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/state-management.md](references/state-management.md)
- [references/navigation.md](references/navigation.md)
- [references/performance.md](references/performance.md)
- [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md)
- [references/platform-channels.md](references/platform-channels.md)
- [references/troubleshoot.md](references/troubleshoot.md)

`flutter pub get` hangs on a machine behind a proxy/firewall → try `--offline`.

## Commands by usecase
 
| Usecase | Command / Action | Note |
| --- | --- | --- |
| Static analysis & types | `flutter analyze` (or `analyze_files` Dart MCP) | First step in verification |
| Dev loop: Live preview & check UI/logic | `flutter run --dart-define-from-file=<env>` | Never use `flutter build` for checking |
| Hot reload after widget changes | `hot_reload` (Dart MCP) | Per `rules/hot_reload.md` |
| Hot restart after main()/state init changes | `hot_restart` (Dart MCP) | Full app restart without recompile |
| Inspect widget tree & layout | `widget_inspector` (Dart MCP) | Verify rendered tree structure |
| Catch runtime errors / crashes | `get_runtime_errors` (Dart MCP) | Check exceptions on interaction |
| End-to-end verification workflow | `/mobile-flutter:verify` | Orchestrated verify flow |
| Dependency sync | `flutter pub get` (or `--offline`) | Resolves packages |
| Packaging final release APK/bundle | `flutter build apk` / `flutter build appbundle` | **Only** for release artifacts, not dev |
