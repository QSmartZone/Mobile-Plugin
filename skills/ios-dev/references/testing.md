# Testing iOS — chi tiết

## XCTest cho ViewModel/Service

```swift
final class BookingListViewModelTests: XCTestCase {
    func test_load_success_updatesState() async {
        let repo = FakeBookingRepository(bookings: [.sample])
        let vm = BookingListViewModel(repo: repo)
        await vm.load()
        XCTAssertEqual(vm.state, .success([.sample]))
    }

    func test_load_failure_emitsErrorState() async {
        let repo = FakeBookingRepository(shouldFail: true)
        let vm = BookingListViewModel(repo: repo)
        await vm.load()
        guard case .error = vm.state else { return XCTFail("expected error state") }
    }
}
```

Dùng fake struct/class implement lại protocol Repository/Service thay vì mock framework cho case đơn giản — Swift protocol-oriented design làm fake rất rẻ.

## XCUITest cho flow quan trọng

Chỉ cover golden path end-to-end (login → đặt chỗ → thanh toán) — chi phí chạy XCUITest cao (build + launch simulator), không dùng để cover mọi UI state nhỏ lẻ.

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

## SwiftUI Preview — không phải test tự động

Preview giúp dev nhanh, thấy UI ngay khi code, nhưng không chạy trong CI và không assert gì — không thay thế cho XCTest/XCUITest.

## Nguyên tắc

Bug fix có branch/loop lỗi trong ViewModel/Service → viết XCTest tái hiện bug trước khi fix. ViewModel mới → test tối thiểu luồng thành công + luồng lỗi.
