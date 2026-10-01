# iOS Testing — details

## XCTest for ViewModel/Service

```swift
final class BookingListViewModelTests: XCTestCase {
    func test_load_success_updatesState() async {
        let repo = FakeBookingRepository(bookings: [.sample])
        let vm = BookingListViewModel(repo: repo)
        await vm.load()
        guard case .success(let bookings) = vm.state else { return XCTFail("expected success state") }
        XCTAssertEqual(bookings, [.sample])
    }

    func test_load_failure_emitsErrorState() async {
        let repo = FakeBookingRepository(shouldFail: true)
        let vm = BookingListViewModel(repo: repo)
        await vm.load()
        guard case .error = vm.state else { return XCTFail("expected error state") }
    }
}
```

Use a fake struct/class re-implementing the Repository/Service protocol instead of a mock framework for simple cases — Swift protocol-oriented design makes fakes very cheap.

## XCUITest for important flows

Cover only the end-to-end golden path (login → booking → payment) — XCUITest is expensive to run (build + launch simulator), do not use it to cover every small UI state.

```swift
func test_login_navigatesToHome() {
    let app = XCUIApplication()
    app.launch()
    app.textFields["email"].tap()
    app.textFields["email"].typeText("test@example.com")
    app.buttons["Login"].tap()
    XCTAssertTrue(app.staticTexts["Home"].waitForExistence(timeout: 5))
}
```

## SwiftUI Preview — not an automated test

Preview speeds up development and shows the UI as you code, but it does not run in CI and asserts nothing — it does not replace XCTest/XCUITest.

## Project without a test target

Check before writing tests: `xcodebuild -list` or open `.xcodeproj`/`.xcworkspace` to see whether there is a Unit Testing Bundle target. None → do not skip the test request on your own; propose adding a test target (File → New → Target → Unit Testing Bundle, or declare it in Package.swift if SPM) before writing the first XCTest — this is a project configuration change, state it clearly to the requester instead of adding it silently.

## Running tests properly

- Run the exact target/class/method being edited first: `xcodebuild test -only-testing:<Target>/<Class>/<testMethod>` — do not run the full suite when only 1 ViewModel changed.
- Read the first `error:`/`failed` line in the output first, do not read the whole log — Xcode prints very long output even when tests pass.
- Add `-resultBundlePath result.xcresult` when you need failing assertion/screenshot details, open with `open result.xcresult`.
- Run XCUITest only when the task touches a real end-to-end flow (not with every small unit change) — launching the simulator is expensive.
- Unit tests (XCTest) must pass before running XCUITest — do not run the full UI suite while basic logic still fails.

## Principle

Bug fix with a faulty branch/loop in a ViewModel/Service → write an XCTest reproducing the bug before fixing. New ViewModel → minimum tests for the success path + the error path.
