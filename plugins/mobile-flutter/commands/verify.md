---
description: Verify Flutter — analyze, run the app live, read runtime errors + widget tree via Dart MCP
allowed-tools: Bash(flutter:*), Bash(git diff:*)
---

Verify the current Flutter app, optional dir: `$ARGUMENTS` (default `.`).

1. Analyze: `dart` MCP tool `analyze_files` for files in `git diff --name-only`. No MCP → `flutter analyze`.
2. Connect to the app: `dtd` `listDtdUris` → `connect`. No app running → `flutter --print-dtd run -d <device>` in the background, take the URI from the "Dart Tooling Daemon" line, then `connect`.
3. `hot_reload` (changed `main`/state init → `hot_restart`).
4. `get_runtime_errors` with `clearRuntimeErrors: true` before interacting, read again afterward.
5. The screen just edited: `widget_inspector` `get_widget_tree` (`summaryOnly: true`). Need interaction → `flutter_driver_command` (`tap`/`enter_text`/`screenshot`) with finders taken exactly from the widget tree. Driver needs the app to enable `enableFlutterDriverExtension()`; if absent → skip the interaction step, report in 1 line.
6. Report: first analyze error (if any), new runtime errors, whether the widget tree has the expected widgets.
7. No release build, no installing new packages. On failure → report and stop; do not fix on your own unless asked.
