---
trigger: glob
globs: ["**/*.dart"]
paths: ["**/*.dart"]
description: Proactively connect to Flutter apps and hot reload
---

Whenever you make edits to any Dart/Flutter file (`*.dart`) in this project:

1. Connect: `dtd` with `listDtdUris`, then `connect` to the URI of the project's app. A DTD whose working dir is the home directory belongs to an IDE; apps launched from the IDE are there.
2. No DTD found → start the app in the background: `flutter --print-dtd run -d <device>`, take the URI from the "Dart Tooling Daemon" line, then `connect`.
3. Trigger `hot_reload`. Changes to `main()`, global state init or `initState` → `hot_restart`.
4. After the reload, call `get_runtime_errors` and report new errors.
5. Fallback: no `dart` MCP tool in this session, or no device available → skip, tell the user in one line, keep editing code. Do not invent a tool name.
