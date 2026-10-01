# ADR — Thin agents, not removed

## Context

The 4 `agents/*-expert.md` files repeat 80-90% of `skills/*/SKILL.md` (reference list + principles). Changing one rule means editing two places. On Claude Code, relative `../skills/...` links inside a subagent cannot be resolved.

## Decision

Keep the 4 agents with a body ≤80 words: 1 line invoking the skill by its plugin-qualified name (`mobile-dev:<skill>`) + 3-4 lines of role-specific scope-stops. Do not list references, do not repeat principles.

## Why

Antigravity/dsh spawn subagents by `agents/<role>.md`; removing an agent loses role-based `invoke_subagent` on those 2 hosts.

## Trade-offs

An agent is not self-sufficient; it must load the skill to get knowledge. Accepted because the skill is the single source of truth.

## Constraints

- Agent body ≤80 words, no "Skill sources" section listing references.
- Frontmatter keeps the 5 existing keys, NO `tools:` (per [multi-platform-support](../multi-platform-support.md)).
- Point to the skill by name `mobile-dev:<skill>`, not by relative path.
