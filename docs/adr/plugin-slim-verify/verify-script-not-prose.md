# ADR — Verify via script + command, not prose only

## Context

Only Android (via `android-cli`) closes the edit → build → run loop. The Android/iOS SKILL.md have no verify command checklist. Every session the agent greps pubspec/package.json/build.gradle to guess the stack, wasting tokens.

## Decision

Add `scripts/detect-stack.sh` (POSIX, prints ≤6 lines: platform, main lib, test runner, analyze/test/build commands) and `commands/verify.md` (`/mobile-dev:verify`: run detect-stack then analyze + test for the right platform). Each SKILL.md ends with a "Verify" section of 3-5 concrete commands.

## Why

A runnable command is evidence; prose like "remember to run tests" gets skipped by small models. One script replaces repeated greps every session.

## Trade-offs

2 more files to maintain when the stack changes. No hooks, so the agent still has to call it proactively.

## Constraints

- POSIX sh script, no dependencies beyond coreutils/grep; no stack → print `unknown`, exit 0.
- The command only runs read-only/test commands, no release builds, no package installs.
- Verify section in SKILL.md: concrete commands, one command + expected result per line.
