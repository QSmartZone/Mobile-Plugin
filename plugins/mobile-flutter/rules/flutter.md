---
trigger: glob
globs: ["**/*.dart", "**/pubspec.yaml"]
description: General Flutter/Dart rules
---

# Flutter — general rules

**Inspect the project first:**
- Read `pubspec.yaml` + `analysis_options.yaml` before editing.
- Follow the existing state/routing/HTTP libs (`flutter_bloc`/`riverpod`/`provider`, `go_router`, `dio`...). Do not propose a new lib when the existing one suffices.

**Preserve the architecture:**
- Do not change state management, `lib/` structure, or migrate without an explicit request.

**Tests — follow project policy:**
- Read the project's `AGENTS.md`/`CLAUDE.md` first. Project forbids tests → do not write them, do not run `flutter test`.
- No policy: logic with branches, loops, or a parser → propose 1 unit/widget test, ask the user before running it.

**Network errors:**
- Widgets do not call the HTTP client directly; go through a repository/service.
- Distinguish network errors (`DioException`/`SocketException`), parse errors (`FormatException`/`TypeError` in `fromJson`), and business errors.
- Do not swallow exceptions, do not push raw error messages to the UI.

**UI baseline:**
- Touch target ≥48×48 logical px (`kMinInteractiveDimension`), contrast meeting WCAG AA, `Semantics`/`tooltip` for icon-only buttons.
- Null-safety: do not use `!` unless sure it is non-null; prefer `?.`, `??`, check `mounted` after `await` before using `context`.

**Out of scope:**
- New `MethodChannel`/platform channel, changing the state lib app-wide → stop, state the reason.

**Verify before reporting done:**
- `/mobile-flutter:verify` (analyze + hot reload + runtime errors + widget tree via Dart MCP).
- Paste the verify output into the report.
