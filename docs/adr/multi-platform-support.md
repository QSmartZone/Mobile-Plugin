# ADR — Multi-platform: reuse the team-plugin pattern, add user/project scope

## Context

`mobile-plugin` needs to run on multiple hosts like `team-plugin` (sibling repo in `self-project/core`), not just Claude Code. We do not want to rethink a pattern that is already proven.

## Decision

Reuse team-plugin's **core + overlay** pattern as is: 3 hosts — Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh`. Core (`agents/ skills/ rules/`) contains no host manifest; host-specific parts live in `.claude-plugin/` (Claude) and `.agents/` (Antigravity + dsh). Install by **copy**, not symlink.

Differences from team-plugin:
1. **No hooks** — drop `hooks.json`, `overlay_agy_hooks`, and the node prereq check in `install.sh`.
2. **Add user/project scope choice** — team-plugin only installs at user scope (global: `~/.claude`, `~/.gemini/config/plugins`, `~/.agents`). `mobile-plugin/install.sh` additionally asks for scope before installing:
   - `user` — same as team-plugin, installs into the host's global directory.
   - `project` — installs into the project you are standing in (`$PWD` when `./install.sh` is called). For Claude: `claude plugin marketplace add <path> --scope project` then `claude plugin install mobile-dev@mobile --scope project` (the `claude` CLI already supports `-s/--scope user|project|local`). For agy/dsh: neither host loads plugins from `<project>/.agents/<plugin>/` or `<project>/.dsh/AGENTS.md`, so project scope writes the layout both hosts read, in one shared run: skill → `.agents/skills/<name>/` (Antigravity + dsh), rule → `.agents/rules/*.md` (Antigravity, needs frontmatter `trigger:`; the repo's `.agents/AGENTS.md` becomes `mobile-dev.md` with `trigger: always_on`), `commands/verify.md` → `.agents/workflows/verify.md` (Antigravity), 1 pointer block in `<project>/AGENTS.md` (dsh + Antigravity). Subagent `agents/*.md` → `.agents/agents/<name>.md` (Antigravity ≥2.0, 2026-08; dsh has no subagents). Sources: antigravity.google/docs/skills, dsh skill roots `.dsh/skills` + `.agents/skills`, instructions from `AGENTS.md`/`CLAUDE.md` at the repo root.

## Why

Separate mobile projects (different teams/customers) do not always want this skill installed globally — project scope lets it be toggled per repo without affecting the user-level config used by other projects.

## Trade-offs

After editing `mobile-plugin`, copies installed at project scope in other projects must rerun `./install.sh --scope project` in each place separately — they do not sync automatically like user scope (a single place).

## Constraints

- No hooks in this plugin.
- `agents/*.md` must NOT declare `tools:` in the frontmatter (Antigravity is strict about unknown tool names).
- Do not add a 4th host beyond Claude/agy/dsh.
- `install.sh` is POSIX shell, no dependencies beyond coreutils/git; for project scope, `claude plugin marketplace add` must run with `source` as the absolute path to the `mobile-plugin` directory (not a symlink) to avoid resolve errors when the command's cwd differs from the original plugin's cwd.
