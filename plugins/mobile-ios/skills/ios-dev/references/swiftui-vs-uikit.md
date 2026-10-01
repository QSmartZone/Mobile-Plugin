# SwiftUI vs UIKit/Storyboard — details

## Decision table

| Situation | Choose |
| --- | --- |
| Brand-new project, no UI code yet | SwiftUI |
| Legacy 100% UIKit/Storyboard project, adding a new screen | Keep UIKit/Storyboard for flow consistency; use SwiftUI via `UIHostingController` only when explicitly requested |
| Legacy UIKit/Storyboard project that is complex, only a small fix needed | Keep UIKit/Storyboard — do not switch toolkit midway just for convenience |
| Screen already SwiftUI, needs an API only in UIKit (camera/AR/print depending on iOS version) | Reverse-direction interop with `UIViewControllerRepresentable`, do not go back to full UIKit |

General principle: 1 screen uses only 1 main toolkit. Switching toolkit is an architecture decision, not a casual one.

## Identify what the project uses

```
find . -name "*.storyboard" -o -name "*.xib"                 # has Storyboard/XIB
grep -rl "import SwiftUI" --include=*.swift .                # has SwiftUI
grep -rl "UIHostingController\|UIViewControllerRepresentable" --include=*.swift .  # two-way interop in use
```

Both Storyboard and SwiftUI present → the project is mid-migration (hybrid) — check what the specific screen being edited uses before deciding. 100% UIKit/Storyboard project with pure MVC architecture (no ViewModel layer) → keep UIKit/Storyboard/MVC when fixing small bugs, do not force SwiftUI/MVVM.

## When pure SwiftUI

Only when explicitly requested to use SwiftUI, or the project is already SwiftUI-first (no UI code yet / already migrated). Do not choose SwiftUI just because "the new screen is independent, not tied to the old Storyboard" — a legacy UIKit project keeps UIKit for new screens unless requested otherwise.

```swift
struct BookingListView: View {
    @State private var viewModel = BookingListViewModel()

    var body: some View {
        List(viewModel.bookings) { booking in
            BookingRow(booking: booking)
        }
        .task { await viewModel.load() }
    }
}
```

## When to keep UIKit/Storyboard

- The screen being maintained is already Storyboard — edit it in the Storyboard/matching `.swift`, do not rewrite it in SwiftUI on your own (architecture change outside the request scope).
- Needs an API only in UIKit (some camera/AR/print controls depending on iOS version) — wrap it via `UIViewControllerRepresentable`.

## Embedding UIKit in SwiftUI

```swift
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
```

## Embedding SwiftUI in UIKit (old screen, adding a new SwiftUI part)

```swift
let hostingController = UIHostingController(rootView: NewFeatureView())
navigationController?.pushViewController(hostingController, animated: true)
```

## Principle

Do not migrate UIKit→SwiftUI or the reverse "while you're at it" when fixing another bug — changing a screen's architecture is a separate decision that must be explicitly requested.
