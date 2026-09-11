## android-native-dev-improve

state: planned · [adr](../adr/android-native-dev-improve/)

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
  -
