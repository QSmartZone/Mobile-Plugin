---
name: ios-dev
description: "Convention iOS native (SwiftUI/UIKit/Storyboard theo tiền lệ project) — kiến trúc, Swift Concurrency, API/error handling, platform capability, testing. Dùng khi chạm file .swift/.storyboard/.xib. Không dùng khi: viết Flutter/React Native (skill tương ứng)."
---

# iOS Dev Specialist

Đọc `rules/mobile-common.md` ở plugin root trước. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/mobile-common.md`.

## Soi project

| Nếu thấy | Kết luận |
|---|---|
| `import SwiftUI`/`: View` đa số | SwiftUI-first — [references/swiftui-vs-uikit.md] |
| `.storyboard`/`.xib`/`UIViewController` đa số | UIKit/Storyboard — [references/uikit-storyboard.md] |
| Cả hai cùng tồn tại | Hybrid — `UIHostingController`/`UIViewRepresentable`, xem [references/interoperability.md] |
| `ComposableArchitecture` / `Coordinator*` / `*ViewModel.swift` | TCA / Coordinator / MVVM — [references/architecture.md] |
| `Package.swift` vs `Podfile` | Theo cái project dùng; SPM mặc định cho lib mới |
| `IPHONEOS_DEPLOYMENT_TARGET` < 17 | Không dùng `@Observable` |

## Quyết định hay sai

- Không mặc định SwiftUI khi project đang Storyboard, không tự migrate UIKit ↔ SwiftUI khi chưa yêu cầu tường minh.
- Không trộn async model (completion/Combine/Rx/async-await) trong 1 file.
- Update UI state từ background → `@MainActor` trên class/method, không update ngoài main thread.
- Token/credential → Keychain, không `UserDefaults`.
- Khai `NSXxxUsageDescription` trong `Info.plist` trước khi request permission.
- SPM mặc định cho dependency mới; CocoaPods chỉ khi project đã dùng.
- Force-unwrap (`!`) chỉ ở `@IBOutlet` đã connect qua Storyboard, chỗ khác validate trước.

## Tham khảo

- [references/swiftui-vs-uikit.md](references/swiftui-vs-uikit.md) — chọn SwiftUI/UIKit/Hybrid
- [references/architecture.md](references/architecture.md) — MVVM/MVC/Coordinator/TCA, Concurrency
- [references/uikit-storyboard.md](references/uikit-storyboard.md) — bẫy Storyboard/IBOutlet
- [references/interoperability.md](references/interoperability.md) — cầu nối UIKit-SwiftUI
- [references/navigation.md](references/navigation.md) · [references/testing.md](references/testing.md)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/platform-capabilities.md](references/platform-capabilities.md) · [references/security-performance-accessibility.md](references/security-performance-accessibility.md)
- [references/xcode-cli.md](references/xcode-cli.md) — lệnh simulator/xcodebuild
- [references/troubleshoot.md](references/troubleshoot.md) — lỗi thường gặp

## Verify

```
xcodebuild -list
xcodebuild build -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO | tail -20
xcodebuild test -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:<Target>/<Class>
```

Task chạm UI → chạy thêm trên simulator theo [references/xcode-cli.md](references/xcode-cli.md).
