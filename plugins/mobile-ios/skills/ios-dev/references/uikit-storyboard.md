# UIKit/Storyboard — details

## Specific pitfalls

- `@IBOutlet`/`@IBAction` names in code drift from the Storyboard after a rename → `NSUnknownKeyException` crash at runtime, not detected at build time.
- `prepare(for:)` does not check `segue.identifier` when multiple segues leave the same view controller → data assigned to the wrong destination.
- Passing data between 2 screens via singleton/global mutable state instead of a property on `destination` — 2 instances of the same screen read/overwrite each other's state.
- Forgetting `dequeueReusableCell` or forgetting to reset state in `prepareForReuse()` → cell shows wrong data when scrolling.
- Registering an observer/notification in `viewDidLoad()` but not unregistering in `deinit`/`viewWillDisappear()` (when per-appearance is needed) → receives callbacks after the screen is closed, or leaks.
- A completion handler closure capturing `self` strongly in a short-lived view controller (dismissed early while a request is running) → retain cycle, `self` does not deinit on time.
- Updating a UIKit view from a background thread without `DispatchQueue.main.async` → UI doesn't refresh or crashes non-reproducibly.

## UIViewController lifecycle

Call order when a screen appears/disappears:

```
loadView() → viewDidLoad()
  → viewWillAppear() → viewIsAppearing() (iOS 17+) → viewDidAppear()
  → viewWillDisappear() → viewDidDisappear()
```

`viewDidLoad()` runs exactly once (set up outlets/delegates/observers); `viewWillAppear`/`viewDidAppear` run each time the screen appears (the place to refresh data, not set up); `viewWillDisappear`/`viewDidDisappear` clean up in pairs (cancel timers, unregister observers).

## IBOutlet / IBAction

```swift
@IBOutlet weak var titleLabel: UILabel!
@IBAction func didTapSubmit(_ sender: UIButton) {
    viewModel.submit()
}
```

- Always declare `@IBOutlet` as `weak` (except special cases needing to keep a view alive outside the view hierarchy) — avoids a retain cycle between view and view controller; `!` (implicitly unwrapped) is acceptable here because the Storyboard guarantees the outlet is connected before use, this is not a place for arbitrary `!` on optionals.
- Name outlets/actions to match the Storyboard — renaming a property in code without renaming it in the Storyboard (or vice versa) → `NSUnknownKeyException` runtime crash, Xcode does not always warn before build.

## Segue and prepare(for:)

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail",
       let detailVC = segue.destination as? DetailViewController,
       let booking = sender as? Booking {
        detailVC.booking = booking
    }
}
```

- Pass data via a clearly typed property on `destination` (like `booking: Booking` above), not via singleton/global state — avoids 2 screens reading each other's state when multiple instances are open at once.
- Check `segue.identifier` when a view controller has multiple outgoing segues — forgetting to check → data assigned to the wrong segue.

## Auto Layout

- Conflicting constraints (ambiguous/unsatisfiable) only surface at runtime via the console log `Unable to simultaneously satisfy constraints`; Interface Builder may not flag red if constraints are syntactically valid but logically wrong (e.g. leading + trailing + width at once, 1 constraint too many).
- Prefer `UIStackView` for linear layouts (list of buttons, vertically stacked form fields) instead of setting every constraint yourself — fewer constraints to manage by hand.
- `translatesAutoresizingMaskIntoConstraints = false` is required when adding a view in code and then setting constraints by hand (not via Storyboard) — forget this line → constraints have no effect, the view keeps its default frame.

## Size class

Use `UITraitCollection`/size class (`Compact`/`Regular` by width, height) for different layouts between iPhone portrait, iPhone landscape, iPad — set in Interface Builder via "vary for traits" or check `traitCollection.horizontalSizeClass` in code when dynamic logic is needed.

## UITableView / UICollectionView

```swift
tableView.dataSource = self
tableView.delegate = self
tableView.register(BookingCell.self, forCellReuseIdentifier: BookingCell.reuseID)

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: BookingCell.reuseID, for: indexPath) as! BookingCell
    cell.configure(with: bookings[indexPath.row])
    return cell
}
```

- Always `dequeueReusableCell` (do not `init` a new cell in `cellForRowAt`) — cell reuse is the core mechanism for smooth scrolling in long lists.
- Reset cell state in `configure(with:)` or `prepareForReuse()` for properties that can "stick" from a previous use (asynchronously loaded image, temporarily changed background color) — forget to reset → the old cell shows wrong data when reused for another item.

## Containment (Child View Controller)

```swift
addChild(childVC)
containerView.addSubview(childVC.view)
childVC.view.frame = containerView.bounds
childVC.didMove(toParent: self)
```

Required order: `addChild` → add the view to the hierarchy → `didMove(toParent:)`. When removing: `willMove(toParent: nil)` → `view.removeFromSuperview()` → `removeFromParent()`. Missing `didMove`/`willMove` → lifecycle events (the child's `viewWillAppear`) are not forwarded correctly.

## Custom reusable view / XIB

```swift
final class BookingCardView: UIView {
    static func loadFromNib() -> BookingCardView {
        Bundle.main.loadNibNamed("BookingCardView", owner: nil)?.first as! BookingCardView
    }
}
```

Name the XIB file the same as the class for easier maintenance. A custom view loaded from XIB needs `File's Owner`/root view set correctly in Interface Builder first, otherwise `loadNibNamed` returns `nil` or the wrong type.

## Retain cycle in closures

```swift
apiClient.fetchBookings { [weak self] result in
    guard let self else { return }
    self.bookings = result
    self.tableView.reloadData()
}
```

A `UIViewController` holds a closure (via a property or a long-lived registered completion handler) and the closure captures `self` strongly → `self` is never deinit'd when the screen closes (dismiss/pop) because the closure still holds the reference. Always use `[weak self]` for closures whose lifetime exceeds a single immediate call (network callback, notification observer, timer).

## Update UI on the main thread

```swift
DispatchQueue.main.async {
    self.tableView.reloadData()
}
```

Every UIKit operation (`reloadData`, setting text, animation) must run on the main thread — calling from a background thread (a raw network callback not yet dispatched, `DispatchQueue.global`) makes UI updates not show immediately or crash inconsistently (`UIKit is only safe to use from the main thread`); it doesn't always crash immediately, so it is easy to miss during a quick run.
