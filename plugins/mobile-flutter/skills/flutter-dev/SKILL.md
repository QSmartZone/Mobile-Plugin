---
name: flutter-dev
description: "Flutter/Dart conventions: widgets, state, lib/ structure, routing, error handling, performance. Use when editing .dart/pubspec.yaml."
---

# Flutter Dev Specialist

Read `rules/flutter.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/flutter.md`.

**After every `.dart` edit:** follow `${CLAUDE_PLUGIN_ROOT}/rules/hot_reload.md` (Dart MCP: connect → `hot_reload` → `get_runtime_errors`). Claude Code does not auto-load plugin rules, so this line is the trigger. Details: `references/dart-mcp.md`. Which command when: `references/commands.md`.

## Inspect the Flutter context first (SDK vs App)

1. **SDK package** (`sdk/*`, `packages/*`): headless, no widgets/`Bloc`/router/fakes; return `ResultDart<T, ModuleFailure>`, never throw across the boundary; no sibling-SDK imports, dependencies injected. Designing a multi-package SDK → `mobile-flutter:flutter-sdk-platform`.
2. **App / shell** (`apps/*`): keep the state, routing and HTTP libs already in `pubspec.yaml`; feature folders directly under `lib/`; wire SDK modules in `di.dart`/bootstrap.

## State management — what to use when

Use the lib the project already has; never mix two in one feature. Decision table: `references/state-management.md`.

## Commonly wrong decisions

- `const` constructor wherever possible.
- Split a long `build()` into child widgets, not methods returning `Widget`.
- No `setState` for cross-widget state.
- `ListView.builder`/`GridView.builder` for long lists.
- No `MethodChannel` when an existing package covers the API.
- No UI widgets, Flutter Bloc or routes inside a headless SDK package.

## References

- [references/project-structure.md](references/project-structure.md) (covers app layout vs headless SDK layer-first layout)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/state-management.md](references/state-management.md)
- [references/navigation.md](references/navigation.md)
- [references/performance.md](references/performance.md)
- [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md)
- [references/platform-channels.md](references/platform-channels.md)
- [references/troubleshoot.md](references/troubleshoot.md)
- [references/commands.md](references/commands.md) (when to run format/analyze/run/clean/gen-l10n/build, foreground rules, pub recovery)
- [references/dart-mcp.md](references/dart-mcp.md) (connect, hot reload, runtime errors, widget tree)
