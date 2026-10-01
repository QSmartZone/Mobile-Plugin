# ADR — Split plugin by platform, verify Flutter via live preview

## Context

The merged `mobile-dev` 0.3.x loads a listing of 6 skills + 4 agents + 1 command (~622 always-on tokens) into every session, even for a Flutter-only project. Feedback from a Flutter project (o2o): the Android/iOS/RN skills/agents were used 0 times; `/verify` runs `flutter test` and `flutter-expert` demands "include tests", against the project's "No Flutter tests" rule; `rules/hot_reload.md` uses old tool names (`connect_dart_tooling_daemon`, `launch_app`) that no longer exist in `dart mcp-server` (Dart SDK 3.13).

## Decision

- 4 sub-plugins `plugins/mobile-{flutter,android,ios,rn}/`, marketplace `mobile` lists all 4. Each plugin has its own rule `rules/<platform>.md`; drop the shared `rules/mobile-common.md` because many lines are only right for one stack (touch target dp/pt, `!!`/`as!`, verify commands), and `hot_reload.md` keeps only the Dart part (RN Fast Refresh moves into `react-native.md`).
- `/mobile-flutter:verify` = analyze + live preview via Dart MCP (`dtd` → `hot_reload` → `get_runtime_errors` → `widget_inspector`/`flutter_driver_command`). Does not run `flutter test`. Replaces `scripts/detect-stack.sh` + multi-stack verify (supersedes `plugin-slim-verify/verify-script-not-prose.md`).
- Tests follow the target project's policy (`AGENTS.md`/`CLAUDE.md`), not hard-coded in skill/agent/rule.
- Skill descriptions drop "do not use when" if the distinguished skill lives in another plugin.
- Antigravity/dsh: `install.sh --pack` merges the selected packs into 1 `mobile-dev` plugin.

## Why

Tried on Claude Code (CLI, 2026-10): a marketplace entry `strict: false` with a `skills` array does filter skills, but `agents/`, `commands/`, `.mcp.json` in default directories are still additionally loaded, and `agents` declaring individual files are not loaded. A separate plugin directory uses default discovery so it is reliable. A few shared lines (keep architecture, tests per policy) are duplicated across the 4 rules — accepted, in exchange each rule contains only what is right for that platform.

Measured with `claude plugin details`: flutter ~154, android ~140, rn ~105, ios ~97 always-on tokens.

## Trade-offs

Breaking: an old `mobile-dev@mobile` install must be removed manually. Android/iOS/RN lose `/verify` (0 uses). Changing a shared principle means editing the 4 rule files by hand.
