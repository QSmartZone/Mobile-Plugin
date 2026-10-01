# mobile-plugin — rules for editing this plugin

Applies to agents editing this repo. Does not apply to projects that install the plugin (target projects read `.agents/AGENTS.md` + `rules/`).

- Layout: one sub-plugin per platform, `plugins/mobile-<pack>/` (flutter/android/ios/rn). Each plugin has its own rule: `plugins/mobile-<pack>/rules/<platform>.md` (distinct file names so `install.sh` can merge them for Antigravity/dsh without overwriting). No shared rule — a line that is not true for every platform must not be written as shared. Do not add `rules/`/`skills/`/`agents/`/`commands/` at the root.
- Cross-folder paths (`skills/` ↔ `rules/`, `agents/` ↔ `skills/`): always `${CLAUDE_PLUGIN_ROOT}/<path>`, never `../`. Calling a skill from another plugin: `mobile-<pack>:<skill>` plus "if installed".
- Adding a markdown section = keep the old sections. Verify: `grep -c "## <old heading>" <file>` = 1.
- CLI commands written into a skill/script: run `<tool> --help` or `-list` first, never write from memory.
- Version-dependent facts (API level, RN/Flutter/iOS/Dart): state the version.
- `SKILL.md` ≤300 words; `description` ≤25 words, pattern "what it does / use when"; "do not use when" only to disambiguate skills in the same plugin; references start with a "Pitfalls" section. Measure: `claude --plugin-dir plugins/<name> plugin details <name>`.
- Changing a skill/agent/command → bump `version` in that plugin's `plugins/<name>/.claude-plugin/plugin.json`.
- Test/verify: do not hard-code test-running commands in skills/agents/commands; testing follows the target project's policy (`AGENTS.md`/`CLAUDE.md`).
- All content in English; code, commands and tool names unchanged.
