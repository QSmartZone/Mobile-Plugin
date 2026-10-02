# Security, performance, accessibility — basics

## Force-unwrap

Avoid `!` unless 100% sure it is non-nil at that point — valid examples: `@IBOutlet` connected in Storyboard/XIB (guaranteed by the framework lifecycle), or a literal with a known value (`URL(string: "https://...")!` with a correct constant string).

Prefer `if let`/`guard let`/`??`:

```swift
guard let url = URL(string: urlString) else {
    return .failure(.invalidURL)
}
```

Do not force-unwrap results that depend on runtime data (API response, user input, values from a dictionary/JSON) — nil here is normal, not a logic bug.

## Do not hardcode secrets

API keys, client secrets, signing keys must not be hardcoded in source (including string literals hidden in a constants file) — `.swift` files built into the binary can be decompiled/read with `strings`.

- Secrets that must stay absolutely secret (private key signing requests): do not embed in the client app, handle server-side.
- Config that differs per environment (dev/staging/prod base URL, non-sensitive public keys): use `.xcconfig` per scheme or build configuration, do not hardcode and comment/uncomment per environment build.

## Validate input at the boundary

Validate where data enters (input forms, API response before decoding, deep link params) — do not assume data is always well-formed.

```swift
guard let amount = Double(amountText), amount > 0 else {
    showError("Invalid amount")
    return
}
```

Do not re-validate redundantly in multiple internal layers for data that already passed a boundary once (YAGNI) — only where data can actually be wrong (from user, network, deep link) is a check needed.

## Avoid blocking the main thread

Synchronous I/O (reading/writing large files, synchronous network calls, heavy computation) must not run on the main thread — use `Task`/`async` or `DispatchQueue.global()`. Blocking the main thread too long (~5s) makes the watchdog kill the app or the UI freeze, with taps unresponsive.

```swift
Task.detached(priority: .background) {
    let result = heavyComputation()
    await MainActor.run {
        self.state = result
    }
}
```

Always return to the main thread to update UI (`MainActor`/`DispatchQueue.main`) — UIKit/SwiftUI are not thread-safe.

## Retain cycle / leak

A closure holding `self` strongly in a long-lived stored property (completion handler stored in a property, `Timer`, `NotificationCenter` observer, delegate) → retain cycle unless `[weak self]` is used.

```swift
apiService.getBooking(id: id) { [weak self] result in
    guard let self else { return }
    self.state = result
}
```

`delegate` (old pattern, not Combine/closure) is declared `weak var delegate: SomeDelegate?` — delegates must be weak references by default, to avoid 2 objects holding each other.

Use Xcode Instruments (Leaks/Allocations) to check when a leak is suspected, do not guess.

## Dynamic Type & VoiceOver

### SwiftUI

```swift
Text("Account balance")
    .font(.body) // use system text styles (.body, .headline...), do not hardcode fixed sizes
    .dynamicTypeSize(...DynamicTypeSize.accessibility3) // allow scaling up to accessibility sizes if the layout can handle it

Image(systemName: "person.crop.circle")
    .accessibilityLabel("Avatar") // icons with functional meaning need a label
Image("decorative_banner")
    .accessibilityHidden(true) // purely decorative image, VoiceOver skips it
```

### UIKit

```swift
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true // auto-scale with the user's Dynamic Type setting

iconButton.accessibilityLabel = "Scan QR code"
decorativeImageView.isAccessibilityElement = false
```

Quick check: Settings > Accessibility > enable VoiceOver, listen for a sensible reading order and labels; enable Larger Text (large Dynamic Type) to check the layout doesn't break (text cut off, overlapping).

Minimum touch target 44x44pt for every tappable button/icon (Apple HIG) — smaller icons need extra padding, do not enlarge the icon.

## Specific pitfalls

- Force-unwrapping JSON decode results or dictionary values (`json["key"] as! String`) → `Unexpectedly found nil` crash when the server changes/omits a field, usually only discovered in production via crash reports.
- Hardcoding API key/secret in a Swift file even when the variable is named `private` — private only limits compile-time scope, it does not encrypt the value in the binary; decompile/`strings` reads it directly.
- Storing a completion closure in a property (e.g. an observer, a callback registered once) without `[weak self]` → `self` is never released even after the screen is dismissed, accumulating into a leak.
- Running network calls or heavy JSON parsing directly on the main thread in `viewDidLoad`/`onAppear` → UI freezes for a few seconds on opening the screen, the app feels janky.
- Missing `accessibilityLabel` for icon-only buttons → VoiceOver reads a meaningless "Button", visually impaired users don't know the button's function.
- Hardcoding a fixed font size (`.system(size: 14)`) instead of a system text style → layout doesn't scale with Dynamic Type, users needing large text can't read it.
