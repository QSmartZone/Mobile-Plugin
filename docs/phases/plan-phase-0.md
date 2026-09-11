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
  - Đúng Expectation. SKILL.md có section "Soi project trước" đầu tiên + không còn câu "SwiftUI mặc định" thiếu điều kiện; đủ 9 file references/ (3 cập nhật: swiftui-vs-uikit.md, architecture.md, testing.md + 6 mới: interoperability.md, uikit-storyboard.md, navigation.md, api-integration-error-handling.md, platform-capabilities.md, security-performance-accessibility.md); agents/ios-expert.md đồng bộ, không có `tools:` trong frontmatter. Review gate: FAIL lượt 1 (2 MEDIUM: default cứng SwiftUI còn sót trong bảng quyết định swiftui-vs-uikit.md, khẳng định cứng NavigationStack trong architecture.md mâu thuẫn navigation.md; 2 LOW: ví dụ test so sánh enum không Equatable, `fatalError` reachable trong ví dụ retry) → fix hết → PASS lượt 2 (còn 1 LOW nit vô hại — thiếu nhắc case greenfield trong SKILL.md, không chặn).

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
