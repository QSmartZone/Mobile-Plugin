# ADR — Dart MCP server, not Bash only

## Context

`rules/hot_reload.md` calls the `dtd`/`hot_reload` tools but the plugin declares no MCP server → on Claude Code the rule points at tools that do not exist, and small models easily invent tools.

## Decision

Add `.mcp.json` at the plugin root declaring `dart mcp-server` (stdio, built into Dart SDK ≥3.9, no external package). The hot_reload rule calls the exact MCP tool names and has a fallback "no tool/app → skip, report in 1 line".

## Why

Close the analyze/test/hot_reload/runtime-error loop with tools instead of parsing Bash output. A plugin installed at project scope still loads the plugin-root `.mcp.json`; `install.sh` copies dotfiles so agy/dsh receive the file.

## Trade-offs

A machine without `dart` in PATH → the server fails to start, and Claude reports an MCP error once per session. Accepted: a mobile plugin assumes the Flutter SDK by default.

## Constraints

- `.mcp.json` has exactly 1 server `dart`, command `dart`, args `["mcp-server"]`, no absolute path.
- Do not add hooks (keep the [multi-platform-support](../multi-platform-support.md) constraint).
- hot_reload rule: frontmatter has both `paths:` (Claude) and `globs:` (Antigravity); always has a fallback step when a tool is missing.
