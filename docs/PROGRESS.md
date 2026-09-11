# Progress — android-native-dev-improve

state: planned
skill: team:fix-code
efficiency: high
parallel: medium
adr: [android-native-dev-improve](adr/android-native-dev-improve/) · phase: [Phase 0](phases/plan-phase-0.md#android-native-dev-improve)

## Task

| # | Task | State | Deps | Files | Verify |
| --- | --- | --- | --- | --- | --- |
| 1 | SKILL.md + agent sync | todo | - | skills/android-native-dev/SKILL.md, agents/android-native-expert.md | Đọc lại 2 file: có section "Soi project trước"; không còn default cứng Compose/StateFlow/Hilt/Repository thiếu điều kiện; đủ link tới 9 reference (3 cũ + 6 mới, kể cả jetpack-compose.md qua ui-compose-vs-views.md) |
| 2 | Update 3 reference hiện có | todo | - | skills/android-native-dev/references/architecture.md, skills/android-native-dev/references/kotlin-conventions.md, skills/android-native-dev/references/testing.md | Đọc lại: architecture.md có Dagger 2 classic + mục "khi nào KHÔNG cần Repository", bỏ Compose Navigation làm mặc định; kotlin-conventions.md có đoạn Java interop; testing.md có ghi chú test theo risk + bootstrap khi chưa có convention |
| 3 | Reference Compose cho UI mới | todo | - | skills/android-native-dev/references/ui-compose-vs-views.md, skills/android-native-dev/references/jetpack-compose.md | Đọc lại: ui-compose-vs-views.md có bảng quyết định Compose vs XML+ViewBinding/DataBinding + đường ComposeView interop; jetpack-compose.md đủ mục state hoisting, remember/rememberSaveable, side-effect API, performance, tích hợp ViewModel, testing, Bẫy cụ thể |
| 4 | Reference Navigation + API + Background | todo | - | skills/android-native-dev/references/navigation.md, skills/android-native-dev/references/api-integration-error-handling.md, skills/android-native-dev/references/background-and-permissions.md | Đọc lại đủ nội dung: navigation.md (3 lựa chọn + deep link); api-integration-error-handling.md (Retrofit/OkHttp, sealed Resource, Room vs DataStore vs SharedPreferences); background-and-permissions.md (WorkManager vs Service vs BroadcastReceiver, runtime permission flow) |
| 5 | Reference Lifecycle + Security/Perf/A11y | todo | - | skills/android-native-dev/references/lifecycle-and-state.md, skills/android-native-dev/references/security-performance-accessibility.md | Đọc lại đủ nội dung: lifecycle-and-state.md (lifecycle callbacks, config change, process death, SavedStateHandle, leak pitfalls); security-performance-accessibility.md (không log dữ liệu nhạy cảm, EncryptedSharedPreferences/Keystore, main-thread blocking, RecyclerView/LazyColumn reuse, accessibility cơ bản) |

## Blocker

không

## Next

wave 1: task 1, 2, 3, 4, 5 (song song, tất cả Files rời nhau)
