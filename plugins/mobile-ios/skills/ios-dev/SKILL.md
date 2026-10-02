---
name: ios-dev
description: "Native iOS conventions: SwiftUI/UIKit by project precedent, Swift Concurrency, error handling, platform capabilities. Use when touching .swift/.storyboard/.xib."
---

# iOS Dev Specialist

Read `rules/ios.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/ios.md`.

## Inspect the project

| If you see | Conclusion |
|---|---|
| `import SwiftUI`/`: View` mostly | SwiftUI-first — [references/swiftui-vs-uikit.md] |
| `.storyboard`/`.xib`/`UIViewController` mostly | UIKit/Storyboard — [references/uikit-storyboard.md] |
| Both exist | Hybrid — `UIHostingController`/`UIViewRepresentable`, see [references/interoperability.md] |
| `ComposableArchitecture` / `Coordinator*` / `*ViewModel.swift` | TCA / Coordinator / MVVM — [references/architecture.md] |
| `Package.swift` vs `Podfile` | Follow what the project uses; SPM by default for new libs |
| `IPHONEOS_DEPLOYMENT_TARGET` < 17 | Do not use `@Observable` |

## Commonly wrong decisions

- Do not default to SwiftUI when the project uses Storyboard; do not migrate UIKit ↔ SwiftUI unless explicitly requested.
- Do not mix async models (completion/Combine/Rx/async-await) in 1 file.
- Updating UI state from background → `@MainActor` on the class/method; do not update off the main thread.
- Token/credential → Keychain, not `UserDefaults`.
- Declare `NSXxxUsageDescription` in `Info.plist` before requesting a permission.
- SPM by default for new dependencies; CocoaPods only if the project already uses it.
- Force-unwrap (`!`) only on `@IBOutlet` connected via Storyboard; validate first elsewhere.

## References

- [references/swiftui-vs-uikit.md](references/swiftui-vs-uikit.md) — choose SwiftUI/UIKit/Hybrid
- [references/architecture.md](references/architecture.md) — MVVM/MVC/Coordinator/TCA, Concurrency
- [references/uikit-storyboard.md](references/uikit-storyboard.md) — Storyboard/IBOutlet pitfalls
- [references/interoperability.md](references/interoperability.md) — UIKit-SwiftUI bridge
- [references/navigation.md](references/navigation.md)
- [references/api-integration-error-handling.md](references/api-integration-error-handling.md)
- [references/platform-capabilities.md](references/platform-capabilities.md) · [references/security-performance-accessibility.md](references/security-performance-accessibility.md)
- [references/xcode-cli.md](references/xcode-cli.md) — simulator/xcodebuild commands
- [references/troubleshoot.md](references/troubleshoot.md) — common errors

## Verify

```
xcodebuild -list
xcodebuild build -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO -derivedDataPath build | tail -20
```

Then live preview on the simulator per [references/xcode-cli.md](references/xcode-cli.md): install → `launch --console` → edited screen → screenshot.
