---
trigger: glob
globs: ["**/*.kt", "**/*.java", "**/*.gradle", "**/*.gradle.kts", "**/AndroidManifest.xml"]
description: General Android native (Kotlin/Java) rules
---

# Android native — general rules

**Inspect the project first:**
- Read `build.gradle(.kts)`, `gradle/libs.versions.toml` (if present), `AndroidManifest.xml` before editing.
- Follow the existing DI (Hilt/Koin), HTTP (Retrofit/Ktor), UI (Compose/View). Do not propose a new lib when an existing one is enough.

**Keep the architecture:**
- Do not migrate Java→Kotlin, View→Compose, or change DI unless explicitly requested.

**Tests — follow project policy:**
- Read the project's `AGENTS.md`/`CLAUDE.md` first. Project forbids tests → do not write them, do not run `./gradlew test*`.
- No policy: logic with a branch, loop, or parser → propose 1 unit test, ask the user before running.

**Network errors:**
- Activity/Fragment/Composable must not call the API directly; go through repository + ViewModel.
- Distinguish network errors (`IOException`), HTTP errors (`HttpException`), parse errors (serialization), business errors.
- Do not swallow exceptions, do not catch `CancellationException` in a coroutine.

**UI baseline:**
- Touch target ≥48dp, contrast meets WCAG AA, `contentDescription` for meaningful icons/images.
- No `!!` unless sure it is non-null; new Java adds `@Nullable`/`@NonNull`.

**Out of scope:**
- New Gradle module, DI framework change, screen architecture migration → stop, report the reason.

**Verify before reporting done:**
- `./gradlew lintDebug` (build with `./gradlew assembleDebug` when changing Gradle/manifest).
- Paste the verify output into the report.
