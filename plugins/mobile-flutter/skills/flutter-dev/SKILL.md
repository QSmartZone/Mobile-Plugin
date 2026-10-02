---
name: flutter-dev
description: "Flutter/Dart conventions: widgets, state, lib/ structure, routing, error handling, performance. Use when editing .dart/pubspec.yaml."
---

# Flutter Dev Specialist

Read `rules/flutter.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/flutter.md`.

## Inspect the Flutter project first

- Read `pubspec.yaml`: state management lib in use (Provider/Bloc/Riverpod...) → follow that lib.
- Routing lib already chosen (Navigator 1.0/`go_router`/`auto_route`) → do not change the mechanism.
- Existing `lib/` structure (feature-first or layer-first) → follow the repo convention, do not apply a default.

## State management — what to use when

| Need | Choose |
| --- | --- |
| Local state of a single widget (toggle, animation) | `setState` |
| Share state among a few nearby descendant widgets | `InheritedWidget`/`Provider` |
| Large app, many async flows, business logic kept separate from UI | `Bloc` or `Riverpod` |
| Unsure — project already has a lib | Use the existing lib; do not mix 2 state solutions in the same feature |

## Commonly wrong decisions

- `const` constructor wherever possible.
- Split a long `build()` into child widgets, not methods returning `Widget`.
- Do not call `setState` for cross-widget state.
- `ListView.builder`/`GridView.builder` for long lists, not `ListView(children:...)`.
- Do not mix 2 state management libs in the same feature.
- Do not write a `MethodChannel` when an existing package already covers the needed API.

**If** the task is a multi-package/white-label SDK → use skill `flutter-sdk-platform`.

## References

- [references/state-management.md](references/state-management.md)
- [references/project-structure.md](references/project-structure.md)
- [references/navigation.md](references/navigation.md)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/performance.md](references/performance.md)
- [references/ui-adaptive-accessibility.md](references/ui-adaptive-accessibility.md)
- [references/platform-channels.md](references/platform-channels.md)
- [references/troubleshoot.md](references/troubleshoot.md)

`flutter pub get` hangs on a machine behind a proxy/firewall → try `--offline`.

## Verify

- `/verify`: `analyze_files` (Dart MCP) or `flutter analyze` → hot reload → `get_runtime_errors` → `widget_inspector`.
- Hot reload per `${CLAUDE_PLUGIN_ROOT}/rules/hot_reload.md`.
