# mobile-plugin

Generic plugin for mobile dev (Flutter, Android native, iOS) — no business logic of any specific project.

## Contents

Split into 4 sub-plugins — a project enables only the plugin for its own stack, so skill/agent listings of other platforms do not take up context.

| Plugin | Skill | Agent | Other |
| --- | --- | --- | --- |
| `mobile-flutter` | `flutter-dev`, `flutter-sdk-platform` | `flutter-expert` | Dart MCP (`.mcp.json`), `/mobile-flutter:verify` |
| `mobile-android` | `android-native-dev`, `android-cli` | `android-native-expert` | |
| `mobile-ios` | `ios-dev` | `ios-expert` | |
| `mobile-rn` | `react-native-dev` | `react-native-expert` | |

```
plugins/mobile-<pack>/
├── .claude-plugin/plugin.json
├── rules/<platform>.md     # per-platform: flutter.md, android.md, ...
├── skills/  agents/  commands/
```

Rules are not shared across platforms: touch targets, null-safety, network errors, and verify commands differ per stack (e.g. Flutter `!` + `mounted`, Kotlin `!!`, Swift `as!`/`try!`, RN `res.ok`).

- `/mobile-flutter:verify` — analyze (`analyze_files` or `flutter analyze`) → connect to the app via `dtd` (if not running, `flutter --print-dtd run`) → `hot_reload` → `get_runtime_errors` → `widget_inspector`/`flutter_driver_command`.
- Verify = static check (analyze/lint/tsc/build) + live preview on a device/emulator/simulator (Flutter hot reload via Dart MCP, Android `android run` + `android layout`, iOS `simctl launch` + screenshot, RN Fast Refresh).
- Dart MCP tools: `dtd`, `hot_reload`, `hot_restart`, `get_runtime_errors`, `widget_inspector`, `flutter_driver_command`, `analyze_files`.

### Notes for plugin developers

- Agent frontmatter has `subagent`, `mainAgent`, `commandExecutionPolicy` — keys for Antigravity/dsh. Claude Code ignores them; this is not an error.
- `CLAUDE.md` and `docs/` at the root are not loaded when using the plugin — they are for plugin editors only.
- Measure context cost: `claude --plugin-dir plugins/mobile-flutter plugin details mobile-flutter` (mobile-flutter ~154 tokens always-on; old merged bundle ~622).

## Installation

### Automatic, every host detected on the machine

```sh
./install.sh                          # asks pack + scope + host via menu
./install.sh --pack flutter --scope project --project ~/dev/my-app   # only mobile-flutter into the given project
cd ~/dev/my-app && /path/to/mobile-plugin/install.sh --scope project   # or call it from inside the project
./install.sh --scope project          # inside the plugin repo, the script asks for the project path
./install.sh --scope user             # global install for the user
./install.sh --dry-run                # show what would happen, change nothing on disk
./install.sh --only claude            # install Claude only, skip agy/dsh
```

After editing the repo: Claude updates via marketplace (`claude plugin update mobile-flutter@mobile`); Antigravity/dsh receive one `mobile-dev` plugin merging the selected packs (a copy), so rerun `./install.sh` with the same `--pack` + scope as last time.

Upgrading from the merged `mobile-dev` ≤0.3.x: `claude plugin uninstall mobile-dev@mobile --scope <scope>`, then install the sub-plugins you need.

### Claude Code / Desktop — manual

```sh
# user scope (claude CLI default)
claude plugin marketplace add /Users/ctquyen/Documents/project/self-project/core/mobile-plugin --scope user
claude plugin install mobile-flutter@mobile --scope user   # or mobile-android / mobile-ios / mobile-rn

# project scope — run the 2 commands above inside the project directory that will use the plugin
cd /path/to/your-project
claude plugin marketplace add /Users/ctquyen/Documents/project/self-project/core/mobile-plugin --scope project
claude plugin install mobile-flutter@mobile --scope project
```

### Antigravity IDE (`agy`)

```sh
./install.sh --only agy --pack flutter --scope user   # agy needs the merged bundle, not the repo directly
```

## Multi-platform

Supports 3 hosts: Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh`. See `docs/adr/multi-platform-support.md` for the architecture decision (core + overlay, copy-not-symlink, user/project scope).
