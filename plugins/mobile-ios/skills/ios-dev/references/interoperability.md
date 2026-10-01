# SwiftUI ↔ UIKit Interoperability — details

When to choose which direction: [swiftui-vs-uikit.md](swiftui-vs-uikit.md). This file focuses on the two-way interop mechanisms.

## UIHostingController — embed SwiftUI in UIKit

Use when an old UIKit/Storyboard screen needs a new part built in SwiftUI (without rewriting the whole screen).

```swift
let hostingController = UIHostingController(rootView: NewFeatureView(viewModel: viewModel))
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.view.frame = containerView.bounds
hostingController.didMove(toParent: self)
```

If you only push a whole SwiftUI screen from a UIKit flow (not embedding into part of a view), push `UIHostingController` directly without a manual `addChild`:

```swift
navigationController?.pushViewController(UIHostingController(rootView: NewFeatureView()), animated: true)
```

## UIViewControllerRepresentable — embed a UIViewController in SwiftUI

Use when a whole `UIViewController` (camera, AR, print, a third-party SDK with only a UIKit API) must be displayed in the SwiftUI tree.

```swift
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // sync properties when SwiftUI state changes, e.g. toggling flash
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraViewControllerRepresentable
        init(_ parent: CameraViewControllerRepresentable) { self.parent = parent }

        func didCapture(_ image: UIImage) {
            parent.capturedImage = image
        }
    }
}
```

## UIViewRepresentable — embed a UIView (not a UIViewController)

Similar to `UIViewControllerRepresentable` but for a single `UIView` (e.g. a `UITextView` needing an API not yet in `TextEditor`, an ad SDK banner).

```swift
struct RichTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: RichTextView
        init(_ parent: RichTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
```

## Coordinator pattern

`Coordinator` is the required bridge whenever a UIKit view/view controller must report events back to SwiftUI (delegate, target-action, closure callback) — a SwiftUI struct cannot hold stable state/identity across multiple `update`s, so delegate logic must live in a separate object (`NSObject` subclass) created by `makeCoordinator()` and living in parallel with the `Representable`.

- Do not implement the delegate directly on the `Representable` struct — the struct is recreated constantly and cannot hold a stable identity for the delegate.
- The Coordinator holds `parent` (usually `unowned` or a struct copy, no retain cycle since SwiftUI manages the `Coordinator` lifecycle) to call bindings/closures back up to SwiftUI.

## Two-way state sync

| Direction | Mechanism |
| --- | --- |
| SwiftUI → UIKit | `updateUIView(_:context:)` / `updateUIViewController(_:context:)` — called again whenever dependent SwiftUI state changes |
| UIKit → SwiftUI | `Coordinator` receives the callback (delegate/target-action) then assigns to `@Binding` or calls a closure passed from SwiftUI |

Avoid infinite loops: when the `Coordinator` sets a `@Binding` to report back to SwiftUI, and `updateUIView` then sets the UIKit view based on that `@Binding` — always compare old/new values before setting (like `if uiView.text != text` above) so the delegate is not re-triggered inside `updateUIView`.

## Gradual Storyboard → SwiftUI migration

Safe strategy when migrating a large UIKit/Storyboard app: go one leaf screen at a time (a leaf screen has few child screens), do not migrate a whole flow at once.

1. Pick 1 standalone screen with few complex navigation dependencies.
2. Rewrite it in pure SwiftUI, keeping the `ViewModel`/service layer if already separated.
3. Embed via `UIHostingController`, push/present from where the old UIKit code calls that screen — do not change the navigation entry point.
4. The app stays hybrid (both Storyboard and SwiftUI) across several PRs — acceptable, do not force 100% migration at once.
5. Repeat for the next screen when requested, do not migrate extra screens outside the task scope.

## Specific pitfalls

- Implementing delegate/target-action directly on the `UIViewRepresentable`/`UIViewControllerRepresentable` struct instead of via `Coordinator` → lost events or crash because the struct is recreated constantly.
- `updateUIView`/`updateUIViewController` setting values without comparing first → infinite update-callback-update loop with two-way bindings.
- Retain cycle between `Coordinator` and the wrapped `UIViewController` (`Coordinator` holds a strong reference to the `UIViewController`, and the `UIViewController` holds a strong reference to the `Coordinator` via a `delegate` not declared `weak`) → leak.
- Migrating a whole Storyboard flow to SwiftUI on your own when the task only asks to fix one small bug in that flow — architecture change outside the request scope.
