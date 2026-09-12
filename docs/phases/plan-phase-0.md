## ios-native-dev-improve

state: shipped · adr: không có (không có ≥2 option cần user chốt)

- Requirement:
  - Skill `ios-dev` phải soi SwiftUI/UIKit/hybrid, kiến trúc (MVVM/MVC/Coordinator/Clean/TCA), concurrency (async-await/Combine/RxSwift/completion-handler) thật của project trước khi áp default, không ép "SwiftUI mặc định" vào project UIKit/Storyboard thuần (vd epay-ios: 100% UIKit, MVC, completion-handler, 0 test target).
  - Skill phải có tài liệu đủ cho các mảng còn thiếu: interoperability SwiftUI-UIKit, UIKit/Storyboard chi tiết, navigation, API integration & error handling, platform capabilities (permission/Keychain/background/push/deep link), bảo mật/hiệu năng/accessibility.
- Acceptance criteria:
  - `SKILL.md` có section "Soi project trước" và không còn câu default cứng "SwiftUI mặc định" thiếu điều kiện "theo project đã có".
  - Đủ 6 file `references/*.md` mới + 3 file cập nhật, mỗi file đúng chủ đề đã chốt trong plan.
  - `agents/ios-expert.md` đồng bộ nguyên tắc với `SKILL.md` mới, không có `tools:` trong frontmatter.
- Expectation:
  - Agent áp skill vào project legacy (epay-ios) → đề xuất đúng UIKit/Storyboard/MVC/completion-handler/URLSession thay vì ép SwiftUI/async-await/MVVM.
- Actual result:
  - Lệch tiêu chí tổng từ: 31.3k → 27.8k (giảm 11%, mục tiêu ≥25%) vì references chỉ sửa fact, không cắt, đồng thời thêm troubleshoot ×4, xcode-cli.md, mobile-common.md. Tầng Haiku load mỗi lần (6 SKILL.md) giảm 5.4k → 2.2k từ; agents 1.5k → 0.4k.
  - Đủ: `.mcp.json` dart mcp-server, `rules/hot_reload.md` có `paths:` + fallback, 4 SKILL.md có mục Verify, `ios-dev/references/xcode-cli.md`, `scripts/detect-stack.sh`, `commands/verify.md`, `uikit-storyboard.md` giữ nguyên chủ đề. 6 fact sai đã sửa + bổ sung API 33/34/35, Privacy Manifest, RN 0.73/0.76/0.82.
  - Review gate: FAIL lượt 1 (2 HIGH: path `rules/mobile-common.md` tương đối chết từ skills/<name>/ và agents/; RN testing.md mất section Nguyên tắc; ~10 MEDIUM fact/lệnh: xcodebuild thiếu -scheme, RN `--variant` cũ, `android screenshot` sai tên, APIError switch không compile...) → fix → PASS lượt 2.
  - Đúng Expectation. SKILL.md có section "Soi project trước" đầu tiên + không còn câu "SwiftUI mặc định" thiếu điều kiện; đủ 9 file references/ (3 cập nhật: swiftui-vs-uikit.md, architecture.md, testing.md + 6 mới: interoperability.md, uikit-storyboard.md, navigation.md, api-integration-error-handling.md, platform-capabilities.md, security-performance-accessibility.md); agents/ios-expert.md đồng bộ, không có `tools:` trong frontmatter. Review gate: FAIL lượt 1 (2 MEDIUM: default cứng SwiftUI còn sót trong bảng quyết định swiftui-vs-uikit.md, khẳng định cứng NavigationStack trong architecture.md mâu thuẫn navigation.md; 2 LOW: ví dụ test so sánh enum không Equatable, `fatalError` reachable trong ví dụ retry) → fix hết → PASS lượt 2 (còn 1 LOW nit vô hại — thiếu nhắc case greenfield trong SKILL.md, không chặn).

## react-native-dev-add

state: shipped · adr: không có (không có ≥2 option cần user chốt)

- Requirement:
  - Repo mobile-plugin chưa có skill nào cho React Native (grep 0 match). Cần skill `react-native-dev` cùng chuẩn với `flutter-dev`/`android-native-dev`/`ios-dev`: soi codebase thật trước (Expo vs bare RN, `package.json`, cấu trúc `src/`) trước khi áp default.
  - Đủ tài liệu cho: Expo vs bare workflow, state management, cấu trúc dự án, navigation, API integration & error handling, performance, UI thích ứng & accessibility, testing, native module/platform code.
- Acceptance criteria:
  - `skills/react-native-dev/SKILL.md` có section "soi codebase trước", đủ 8 file `references/*.md` đúng chủ đề đã chốt.
  - `agents/react-native-expert.md` đồng bộ nguyên tắc với SKILL.md, không có `tools:` trong frontmatter (constraint [multi-platform-support](../adr/multi-platform-support.md)).
  - `.agents/AGENTS.md` có dòng routing `*.tsx`/`*.jsx` (RN project) → `react-native-dev`.
  - 3 manifest (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.agents/plugin.json`) nhắc React Native, `plugin.json` bump version + thêm keyword.
- Expectation:
  - Agent áp skill vào project RN thật (Expo hoặc bare) → đề xuất đúng theo lib/kiến trúc project đã có, không ép mặc định cứng.
- Actual result:
  - Lệch số file so với Acceptance criteria: 9 file `references/*.md` thay vì 8 (thêm `expo-vs-bare.md` vì RN có topic Expo vs bare workflow mà Flutter không có, đã chốt giữ 9) — gồm expo-vs-bare, state-management, project-structure, navigation, api-integration-error-handling, performance, ui-adaptive-accessibility, testing, native-modules.
  - `agents/react-native-expert.md` đủ 5 key frontmatter, không có `tools:`, đồng bộ đủ 9 reference.
  - `.agents/AGENTS.md` có dòng routing `*.tsx, *.jsx (React Native project — có metro.config.js/app.json Expo)` → `react-native-dev`.
  - 3 manifest nhắc React Native; `plugin.json` bump version 0.1.0 → 0.2.0 + thêm keyword "react-native".
  - Review gate: FAIL lượt 1 (`skills/react-native-dev/references/native-modules.md`: mốc New Architecture default sai — nói RN 0.68+ đã ổn định, thực tế New Architecture chỉ default từ RN 0.76 (10/2024); liệt `expo-permissions` như lựa chọn hợp lệ dù đã deprecated từ SDK 41) → fix hết → PASS lượt 2.

## android-native-dev-improve

state: shipped · adr: không có (không có ≥2 option cần user chốt)

- Requirement:
  - Skill `android-native-dev` phải soi UI toolkit/DI/kiến trúc thật của project trước khi áp default, không ép Compose/StateFlow/Hilt/Repository vào project legacy (XML/DataBinding/LiveData/Dagger 2/no-Repository).
  - Skill phải có tài liệu đủ cho các mảng còn thiếu: lifecycle/config change, navigation (Compose lẫn XML), API integration & error handling, background work & permissions, bảo mật/hiệu năng/accessibility, và Jetpack Compose hiện đại cho screen/project mới.
- Acceptance criteria:
  - `SKILL.md` có section "Soi project trước" và không còn câu default cứng Compose/StateFlow/Hilt/Repository thiếu điều kiện "theo project đã có".
  - Đủ 7 file `references/*.md` mới + 3 file cập nhật, mỗi file có nội dung đúng chủ đề đã chốt trong plan.
  - `agents/android-native-expert.md` đồng bộ nguyên tắc với `SKILL.md` mới.
- Expectation:
  - Agent áp skill vào project legacy (vd epay-android) → đề xuất đúng XML+DataBinding+LiveData+Dagger2+no-Repository thay vì ép Compose/StateFlow/Hilt/Repository.
- Actual result:
  - Đúng Expectation. SKILL.md có section "Soi project trước" + không còn default cứng Compose/StateFlow/Hilt/Repository thiếu điều kiện; đủ 10 file references/ (3 cập nhật + 7 mới, gồm jetpack-compose.md, ui-compose-vs-views.md, navigation.md, api-integration-error-handling.md, background-and-permissions.md, lifecycle-and-state.md, security-performance-accessibility.md); agents/android-native-expert.md đồng bộ. Review gate: FAIL lượt 1 (2 HIGH: thiếu link jetpack-compose.md, NPE trong ví dụ API error handling; 3 MEDIUM: sai kỹ thuật Dagger 2 vs Hilt, API network deprecated, 3 mục SKILL.md hứa nhưng reference thiếu; 1 LOW: frontmatter description cũ) → fix hết → PASS lượt 2 (còn 1 LOW link label vô hại, đã tự sửa).

## plugin-slim-verify

state: shipped · [adr](../adr/plugin-slim-verify/)

- Requirement:
  - Cắt nội dung lặp/textbook để Haiku load vừa đủ: xoá dump `android help`, agent ≤80 từ, 5 khối lặp ×4 platform gom vào `rules/mobile-common.md`.
  - Sửa fact sai/lỗi thời (runCatching nuốt CancellationException, EncryptedSharedPreferences, Flipper, ClipRRect, @Observable thiếu @MainActor, Cubit) và bổ sung version gotchas.
  - Đóng vòng verify đủ 4 platform: `.mcp.json` dart mcp-server, `xcode-cli.md`, troubleshoot.md/platform, mục Verify trong SKILL.md, `scripts/detect-stack.sh`, `/mobile-dev:verify`.
- Acceptance criteria:
  - Tổng từ `skills/**/*.md` + `agents/*.md` giảm ≥25% so với 31.7k; mỗi SKILL.md ≤300 từ; `uikit-storyboard.md` còn nguyên chủ đề.
  - `dart mcp-server` khai trong `.mcp.json`; `rules/hot_reload.md` có `paths:` + fallback.
  - 4 SKILL.md có mục Verify với lệnh cụ thể; iOS có reference CLI simulator ngang `android-cli`.
- Expectation:
  - Agent Haiku đọc SKILL.md 1 platform + mobile-common là đủ soi project và biết lệnh verify, không cần agent .md.
- Actual result:
