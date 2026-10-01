# iOS Architecture — details

## Identify the architecture in use from code

```
grep -rl "import ComposableArchitecture" --include=*.swift .   # TCA
find . -type d -iname "Coordinator*"                            # Coordinator pattern
find . -type d \( -iname "Domain" -o -iname "Data" -o -iname "Presentation" \)  # Clean Architecture (by layer folder)
find . -type d -iname "ViewModel*" -o -name "*ViewModel.swift"  # MVVM
find . -name "*Controller.swift" | xargs grep -L "ViewModel" 2>/dev/null  # pure MVC (Controller without an accompanying ViewModel)
```

Read results in the order above: TCA present → stop, it is TCA. Not present but a Coordinator folder/file exists → Coordinator (often combined with MVVM or MVC underneath, check further). Domain/Data/Presentation present → Clean Architecture. `*ViewModel.swift` widespread → MVVM. All `*Controller.swift` with no ViewModel → pure MVC.

Project has ViewModel for only a few features, the rest are Controllers without ViewModel → it is pure MVC (not fully migrated to MVVM) — when editing a specific feature, follow the pattern that feature already uses, do not add a ViewModel to a Controller that works fine.

## When to add a new layer

Do not add Coordinator/Clean Architecture/TCA to a project running MVC or simple MVVM just because it is "the proper architecture". Add only for a concrete need: complex navigation with many branching flows (→ Coordinator), multiple data sources/need to test domain logic independent of UI (→ Clean Architecture layer), complex state needing pure side-effects and easily reproducible tests (→ TCA) — and that is an architecture decision to state clearly, not to fold into a small bug fix.

## Layers (default MVVM for a new project/one with no existing pattern)

```
View (SwiftUI) → ViewModel (@Observable) → Service/Repository → Network/DB
```

## ViewModel with Swift Concurrency

```swift
@Observable
@MainActor
final class BookingListViewModel {
    private(set) var state: BookingUiState = .loading
    private let repo: BookingRepository

    init(repo: BookingRepository = .live) {
        self.repo = repo
    }

    func load() async {
        state = .loading
        do {
            let bookings = try await repo.fetchBookings()
            state = .success(bookings)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum BookingUiState {
    case loading
    case success([Booking])
    case error(String)
}
```

`@Observable` (Swift 5.9+/iOS 17+) replaces `ObservableObject` + `@Published` when the deployment target allows — less boilerplate, re-renders only the property that actually changed instead of the whole object.

`@MainActor` on the class is required when a property is mutated from an `async` function called from a non-main context (background Task, network callback) — without it, Swift 6 strict concurrency reports the compile error "Main actor-isolated property ... cannot be mutated from a non-isolated context" instead of silently crashing at runtime as before.

## Swift Concurrency instead of GCD

```swift
// Old (GCD) — keep only when the file being edited already uses this pattern consistently
DispatchQueue.global().async {
    let result = fetchData()
    DispatchQueue.main.async { self.updateUI(result) }
}

// New (async/await) — use for new code
Task {
    let result = await fetchData()
    self.updateUI(result)
}
```

## Dependency injection

Simple constructor injection (as in the example above: `init(repo:)` with default `.live` for production, overridden in tests) — enough for most iOS apps, no separate DI framework needed unless the app is very large with many teams.

## Navigation

Choose by the navigation mechanism the project uses (segue, manual push, Coordinator, or `NavigationStack`) — see references/navigation.md.
