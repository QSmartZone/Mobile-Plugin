---
trigger: glob
globs: ["**/*.swift", "**/*.storyboard", "**/*.xib", "**/Podfile", "**/Package.swift"]
description: General rules for native iOS (Swift)
---

# Native iOS — general rules

**Inspect the project first:**
- Read `Podfile`/`Package.swift`/`*.xcodeproj` and files of the same screen before editing.
- Follow the existing UI (SwiftUI/UIKit/Storyboard), async (Swift Concurrency/Combine/Rx), HTTP (URLSession/Alamofire). Do not suggest a new lib when the existing one suffices.

**Keep the architecture:**
- Do not migrate UIKit↔SwiftUI, Storyboard→code, or change pattern (MVVM/VIPER/TCA) unless explicitly requested.

**Network errors:**
- View/ViewController does not call the API directly; go through a service/repository.
- Distinguish network errors (`URLError`), HTTP status errors, parse errors (`DecodingError`), business errors.
- Do not swallow errors (`try?` silently dropping the error), do not push raw `localizedDescription` to the UI.

**UI baseline:**
- Touch target ≥44×44pt, contrast meets WCAG AA, `accessibilityLabel` for icon-only buttons, support Dynamic Type.
- No `!`, `as!`, `try!` when unsure; update UI on `@MainActor`.

**Out of scope:**
- New target/extension, new capability/entitlement, app-wide navigation architecture change → stop, state the reason.

**Verify before reporting done:**
- `xcodebuild build -scheme <Scheme> -destination 'platform=iOS Simulator,name=<device>' CODE_SIGNING_ALLOWED=NO -derivedDataPath build` (scheme from `xcodebuild -list`).
- Live preview: `xcrun simctl install` + `xcrun simctl launch --console` → open the edited screen → `xcrun simctl io booted screenshot` to confirm the expected UI, read the console for crashes (commands: `references/xcode-cli.md` in skill `ios-dev`).
- No simulator available → say so in 1 line.
- Paste the verify output into the report.
