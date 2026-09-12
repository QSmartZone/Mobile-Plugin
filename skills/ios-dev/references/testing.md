# Testing iOS — chi tiết

## XCTest cho ViewModel/Service

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

## Project chưa có test target

Kiểm tra trước khi viết test: `xcodebuild -list` hoặc mở `.xcodeproj`/`.xcworkspace` xem có target kiểu Unit Testing Bundle không. Không có → không tự bỏ qua yêu cầu test, đề xuất thêm 1 test target (File → New → Target → Unit Testing Bundle, hoặc khai trong Package.swift nếu SPM) trước khi viết XCTest đầu tiên — đây là thay đổi cấu hình project, nêu rõ với người yêu cầu thay vì âm thầm thêm.

## Chạy test đúng cách

- Chạy đúng target/class/method đang sửa trước: `xcodebuild test -only-testing:<Target>/<Class>/<testMethod>` — không chạy full suite khi chỉ sửa 1 ViewModel.
- Đọc dòng `error:`/`failed` đầu tiên trong output trước, đừng đọc hết log — Xcode in rất dài kể cả khi test pass.
- Thêm `-resultBundlePath result.xcresult` khi cần xem chi tiết assertion/screenshot thất bại, mở bằng `open result.xcresult`.
- XCUITest chỉ chạy khi task chạm flow end-to-end thật (không chạy kèm mỗi lần sửa unit nhỏ) — chi phí launch simulator cao.
- Unit test (XCTest) phải pass trước khi chạy XCUITest — không chạy full UI suite khi logic cơ bản còn fail.

## Nguyên tắc

Bug fix có branch/loop lỗi trong ViewModel/Service → viết XCTest tái hiện bug trước khi fix. ViewModel mới → test tối thiểu luồng thành công + luồng lỗi.
