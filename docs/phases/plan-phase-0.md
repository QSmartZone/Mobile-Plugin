## ios-native-dev-improve

state: shipped · adr: none (no ≥2 options needing a user decision)

- Requirement:
  - Skill `ios-dev` must inspect the project's real SwiftUI/UIKit/hybrid, architecture (MVVM/MVC/Coordinator/Clean/TCA), and concurrency (async-await/Combine/RxSwift/completion-handler) before applying defaults, and must not force "SwiftUI by default" onto a pure UIKit/Storyboard project (e.g. epay-ios: 100% UIKit, MVC, completion-handler, 0 test targets).
  - The skill must have enough documentation for the missing areas: SwiftUI-UIKit interoperability, detailed UIKit/Storyboard, navigation, API integration & error handling, platform capabilities (permission/Keychain/background/push/deep link), security/performance/accessibility.
- Acceptance criteria:
  - `SKILL.md` has an "Inspect the project first" section and no longer has the hard default "SwiftUI by default" lacking the "per the existing project" condition.
  - All 6 new `references/*.md` files + 3 updated files exist, each on the topic fixed in the plan.
  - `agents/ios-expert.md` is aligned with the principles of the new `SKILL.md`, with no `tools:` in the frontmatter.
- Expectation:
  - Applying the skill to a legacy project (epay-ios), the agent proposes UIKit/Storyboard/MVC/completion-handler/URLSession as appropriate instead of forcing SwiftUI/async-await/MVVM.
- Actual result:
  - Deviates from the overall criterion on words: 31.3k → 27.8k (down 11%, target ≥25%) because references only had facts fixed, not cut, while troubleshoot ×4, xcode-cli.md, mobile-common.md were added. The Haiku tier loaded every time (6 SKILL.md) dropped 5.4k → 2.2k words; agents 1.5k → 0.4k.
  - Complete: `.mcp.json` dart mcp-server, `rules/hot_reload.md` has `paths:` + fallback, 4 SKILL.md have a Verify section, `ios-dev/references/xcode-cli.md`, `scripts/detect-stack.sh`, `commands/verify.md`, `uikit-storyboard.md` kept on topic. 6 wrong facts fixed + added API 33/34/35, Privacy Manifest, RN 0.73/0.76/0.82.
  - Review gate: FAIL round 1 (2 HIGH: relative path `rules/mobile-common.md` is dead from skills/<name>/ and agents/; RN testing.md lost the Principles section; ~10 MEDIUM facts/commands: xcodebuild missing -scheme, old RN `--variant`, wrong name `android screenshot`, APIError switch does not compile...) → fixed → PASS round 2.
  - Matches Expectation. SKILL.md has the "Inspect the project first" section first + no longer has the unconditional "SwiftUI by default"; all 9 references/ files present (3 updated: swiftui-vs-uikit.md, architecture.md, testing.md + 6 new: interoperability.md, uikit-storyboard.md, navigation.md, api-integration-error-handling.md, platform-capabilities.md, security-performance-accessibility.md); agents/ios-expert.md aligned, no `tools:` in frontmatter. Review gate: FAIL round 1 (2 MEDIUM: hard SwiftUI default left in the decision table of swiftui-vs-uikit.md, hard NavigationStack claim in architecture.md contradicts navigation.md; 2 LOW: test example compares a non-Equatable enum, reachable `fatalError` in the retry example) → all fixed → PASS round 2 (1 harmless LOW nit left — greenfield case not mentioned in SKILL.md, non-blocking).

## react-native-dev-add

state: shipped · adr: none (no ≥2 options needing a user decision)

- Requirement:
  - The mobile-plugin repo has no React Native skill yet (grep 0 matches). Need a `react-native-dev` skill to the same standard as `flutter-dev`/`android-native-dev`/`ios-dev`: inspect the real codebase first (Expo vs bare RN, `package.json`, `src/` structure) before applying defaults.
  - Enough documentation for: Expo vs bare workflow, state management, project structure, navigation, API integration & error handling, performance, adaptive UI & accessibility, testing, native module/platform code.
- Acceptance criteria:
  - `skills/react-native-dev/SKILL.md` has an "inspect the codebase first" section and all 8 `references/*.md` files on the topics fixed in the plan.
  - `agents/react-native-expert.md` is aligned with the principles of SKILL.md, with no `tools:` in the frontmatter (constraint of [multi-platform-support](../adr/multi-platform-support.md)).
  - `.agents/AGENTS.md` has a routing row `*.tsx`/`*.jsx` (RN project) → `react-native-dev`.
  - The 3 manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.agents/plugin.json`) mention React Native; `plugin.json` bumps the version + adds a keyword.
- Expectation:
  - Applying the skill to a real RN project (Expo or bare), the agent proposes according to the libs/architecture the project already has, without forcing hard defaults.
- Actual result:
  - File count deviates from the Acceptance criteria: 9 `references/*.md` files instead of 8 (added `expo-vs-bare.md` because RN has an Expo vs bare workflow topic that Flutter lacks; decided to keep 9) — expo-vs-bare, state-management, project-structure, navigation, api-integration-error-handling, performance, ui-adaptive-accessibility, testing, native-modules.
  - `agents/react-native-expert.md` has all 5 frontmatter keys, no `tools:`, aligned with all 9 references.
  - `.agents/AGENTS.md` has the routing row `*.tsx, *.jsx (React Native project — has metro.config.js/app.json Expo)` → `react-native-dev`.
  - The 3 manifests mention React Native; `plugin.json` bumped version 0.1.0 → 0.2.0 + added keyword "react-native".
  - Review gate: FAIL round 1 (`skills/react-native-dev/references/native-modules.md`: wrong New Architecture milestone — said RN 0.68+ was stable, in reality New Architecture is default only from RN 0.76 (10/2024); listed `expo-permissions` as a valid choice though deprecated since SDK 41) → all fixed → PASS round 2.

## android-native-dev-improve

state: shipped · adr: none (no ≥2 options needing a user decision)

- Requirement:
  - Skill `android-native-dev` must inspect the project's real UI toolkit/DI/architecture before applying defaults, and must not force Compose/StateFlow/Hilt/Repository onto a legacy project (XML/DataBinding/LiveData/Dagger 2/no-Repository).
  - The skill must have enough documentation for the missing areas: lifecycle/config change, navigation (both Compose and XML), API integration & error handling, background work & permissions, security/performance/accessibility, and modern Jetpack Compose for new screens/projects.
- Acceptance criteria:
  - `SKILL.md` has an "Inspect the project first" section and no longer has the hard default Compose/StateFlow/Hilt/Repository lacking the "per the existing project" condition.
  - All 7 new `references/*.md` files + 3 updated files exist, each with content on the topic fixed in the plan.
  - `agents/android-native-expert.md` is aligned with the principles of the new `SKILL.md`.
- Expectation:
  - Applying the skill to a legacy project (e.g. epay-android), the agent proposes XML+DataBinding+LiveData+Dagger2+no-Repository as appropriate instead of forcing Compose/StateFlow/Hilt/Repository.
- Actual result:
  - Matches Expectation. SKILL.md has the "Inspect the project first" section + no longer has the unconditional hard default Compose/StateFlow/Hilt/Repository; all 10 references/ files present (3 updated + 7 new, including jetpack-compose.md, ui-compose-vs-views.md, navigation.md, api-integration-error-handling.md, background-and-permissions.md, lifecycle-and-state.md, security-performance-accessibility.md); agents/android-native-expert.md aligned. Review gate: FAIL round 1 (2 HIGH: missing jetpack-compose.md link, NPE in the API error handling example; 3 MEDIUM: technical error on Dagger 2 vs Hilt, deprecated network API, 3 SKILL.md items promised but reference missing; 1 LOW: old frontmatter description) → all fixed → PASS round 2 (1 harmless LOW link label left, self-fixed).

## plugin-slim-verify

state: shipped · [adr](../adr/plugin-slim-verify/)

- Requirement:
  - Cut repeated/textbook content so Haiku loads just enough: remove the `android help` dump, agents ≤80 words, merge 5 blocks repeated ×4 platforms into `rules/mobile-common.md`.
  - Fix wrong/outdated facts (runCatching swallowing CancellationException, EncryptedSharedPreferences, Flipper, ClipRRect, @Observable missing @MainActor, Cubit) and add version gotchas.
  - Close the verify loop for all 4 platforms: `.mcp.json` dart mcp-server, `xcode-cli.md`, troubleshoot.md/platform, Verify section in SKILL.md, `scripts/detect-stack.sh`, `/mobile-dev:verify`.
- Acceptance criteria:
  - Total words in `skills/**/*.md` + `agents/*.md` down ≥25% from 31.7k; each SKILL.md ≤300 words; `uikit-storyboard.md` still on topic.
  - `dart mcp-server` declared in `.mcp.json`; `rules/hot_reload.md` has `paths:` + fallback.
  - 4 SKILL.md have a Verify section with concrete commands; iOS has a simulator CLI reference on par with `android-cli`.
- Expectation:
  - A Haiku agent reading one platform's SKILL.md + mobile-common has enough to inspect the project and know the verify commands, without needing the agent .md.
- Actual result:
