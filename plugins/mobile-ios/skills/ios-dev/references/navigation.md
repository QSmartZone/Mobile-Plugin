# iOS Navigation — details

Choose by the mechanism the project uses; do not switch midway within the same app or flow.

## Segue + prepare(for:)

For Storyboard screens. Drag the segue in Interface Builder, pass data via `prepare(for:sender:)`. Mechanism details + specific pitfalls: [uikit-storyboard.md](uikit-storyboard.md#segue-and-preparefor).

```swift
performSegue(withIdentifier: "showDetail", sender: booking)
```

## Manual pushViewController

For UIKit flows where the destination screen isn't in a Storyboard, or when a dynamic push condition is needed (not fixed by a static segue).

```swift
let detailVC = DetailViewController(booking: booking)
navigationController?.pushViewController(detailVC, animated: true)
```

Pass data via a typed initializer (`DetailViewController(booking: booking)`) or a property assigned right after initialization, not via singleton/global state — avoids 2 instances of the same screen reading each other's state.

## NavigationStack (SwiftUI)

For SwiftUI-first apps. Use `NavigationStack` + `NavigationPath` or a typed route enum, do not hand-assemble strings.

```swift
enum Route: Hashable {
    case detail(bookingID: String)
}

NavigationStack(path: $path) {
    List(bookings) { booking in
        NavigationLink(value: Route.detail(bookingID: booking.id)) {
            BookingRow(booking: booking)
        }
    }
    .navigationDestination(for: Route.self) { route in
        switch route {
        case .detail(let bookingID):
            DetailView(bookingID: bookingID)
        }
    }
}
```

## Coordinator pattern

For apps that need navigation logic separated from view controllers/views (usually codebases that adopted this pattern from the start) — 1 `Coordinator` object owns the `UINavigationController` and decides which screen to push/present; the view controller only signals "I need to navigate" via closure/delegate and never calls `navigationController?.pushViewController` itself.

```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

final class BookingCoordinator: Coordinator {
    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    func start() {
        let vc = BookingListViewController()
        vc.onSelectBooking = { [weak self] booking in
            self?.showDetail(for: booking)
        }
        navigationController.pushViewController(vc, animated: false)
    }
    private func showDetail(for booking: Booking) {
        navigationController.pushViewController(DetailViewController(booking: booking), animated: true)
    }
}
```

## Rule: choose by the mechanism the project already uses

| Project uses | Do |
| --- | --- |
| All Storyboard, navigation via segue | Add new segues the same way; do not switch to manual `pushViewController` for a new screen if the other related screens all use segues |
| All UIKit, navigation via manual `pushViewController` (no Storyboard for navigation) | Keep using manual `pushViewController`, do not add Storyboard/segue |
| Existing `Coordinator` layer | Add navigation logic to the matching `Coordinator`, do not call `pushViewController` directly in the view controller |
| SwiftUI-first | `NavigationStack` + typed route enum |

Real example: a 100% UIKit/Storyboard codebase (4 storyboards + 6 xibs), navigating via segue in 7 places and manual `pushViewController` in 6 places, no `Coordinator`. When adding a new screen here: check whether the screen that calls it uses a segue or manual `pushViewController`, and keep that way for consistency in the same flow — do not gather everything into a `Coordinator` or convert all segues to `pushViewController` because it is "cleaner". Changing the app-wide navigation mechanism is a separate architecture decision that must be explicitly requested.

## Pass data via typed arguments

Applies to every mechanism above — pass via a typed initializer/property (`DetailViewController(booking: booking)`, an associated value in a route enum) or the segue's `prepare(for:)` with a type check, not via singleton/global mutable state (`AppState.shared.currentBooking = booking` then the destination screen reads it back). Singleton/global state makes 2 instances of the same screen (opening 2 tabs, going back then reopening) overwrite each other's state, and the compiler cannot check that the passed data type is correct.

## Specific pitfalls

- Mixing segue and manual `pushViewController` in the same screen-transition flow — hard to trace where the navigation logic lives (Storyboard or code), hard to follow in review.
- Passing data via singleton/global state instead of typed arguments → 2 instances of the same screen read each other's state, undetectable at compile time.
- `Coordinator` holds a strong reference to the view controller and the view controller holds one back through a closure without `[weak self]` → retain cycle.
- SwiftUI route enum using raw hand-assembled Strings instead of a typed enum/associated value → change a parameter in one place and forget another, the bug only shows when running that screen.
- Calling `performSegue`/`pushViewController` several times in a row due to missing debounce on double-tap → multiple duplicate copies of the same screen pushed onto the navigation stack.
