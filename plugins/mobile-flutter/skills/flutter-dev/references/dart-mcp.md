# Dart MCP — connect, hot reload, inspect

Server: `dart mcp-server` (declared in the plugin `.mcp.json`).

## Pitfalls

- Skipping the MCP and only using `adb`/`flutter run` output: no hot reload, no structured runtime errors, no widget tree. After every `.dart` edit follow `${CLAUDE_PLUGIN_ROOT}/rules/hot_reload.md`.
- Claude Code does not auto-load plugin `rules/` (they are loaded by Antigravity/dsh only). The skill must point at the rule file, as `SKILL.md` does.
- `dtd` `listDtdUris` shows IDE-owned DTDs (workspace root = SDK or home dir) with no app attached: connecting succeeds with "No apps currently connected". That is not a failure; start the app.
- A plain `flutter run` hides its DTD URI. Use `flutter --print-dtd run -d <device> --dart-define-from-file=<env>` in the background and take the URI from the "Dart Tooling Daemon" line.
- Changes to `main()`, global state init, `initState`, `const`, enums → `hot_restart`, not `hot_reload`.
- Inventing a tool name when the MCP is missing: skip, tell the user in one line, keep editing.

## Tools

| Need | Tool |
| --- | --- |
| Find / attach to a running app | `dtd` (`listDtdUris` → `connect` → `listConnectedApps`) |
| Apply an edit | `hot_reload`, or `hot_restart` for state-init changes |
| Crashes and assertion failures | `get_runtime_errors` (`clearRuntimeErrors: true` before interacting, read again after) |
| Rendered layout | `widget_inspector` `get_widget_tree` (`summaryOnly: true`) |
| Tap / type / screenshot | `flutter_driver_command`; needs `enableFlutterDriverExtension()` in the app, otherwise skip |
| Static analysis | `analyze_files` |

Flow after an edit: `rules/hot_reload.md`. Full verify pass: `/mobile-flutter:verify`.
