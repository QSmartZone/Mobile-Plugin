---
trigger: glob
globs: ["**/*.dart", "**/*.tsx", "**/*.jsx"]
paths: ["**/*.dart", "**/*.tsx", "**/*.jsx"]
description: Proactively connect to apps and hot reload
---

Whenever you make edits to any Dart/Flutter or React Native files in this project:

**Dart/Flutter (`*.dart`):**
1. Connect via the `dart` MCP server's `connect_dart_tooling_daemon` tool (URI from the `flutter run` console line "The Dart Tooling Daemon is available at"), or `launch_app` if no app is running yet.
2. Trigger `hot_reload` to push the changes immediately.
3. Fallback: no `dart` MCP tool in this session, or no app running → skip, tell the user in one line, keep editing code. Do not invent a tool name.

**React Native (`*.tsx`, `*.jsx`):**
1. No explicit connect/trigger step needed — Metro bundler auto Fast Refreshes on file save when the dev server is running.
2. If Metro is not running, inform the user but do not let it stop you from completing the code edits.
