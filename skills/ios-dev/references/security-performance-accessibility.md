# Bảo mật, hiệu năng, accessibility — cơ bản

## Force-unwrap

Tránh `!` trừ khi chắc chắn 100% không nil tại thời điểm đó — ví dụ hợp lệ: `@IBOutlet` đã connect trong Storyboard/XIB (đảm bảo bởi framework lifecycle), hoặc literal biết trước giá trị (`URL(string: "https://...")!` với string hằng cố định đúng).

Ưu tiên `if let`/`guard let`/`??`:

```swift
guard let url = URL(string: urlString) else {
    return .failure(.invalidURL)
}
```

Không force-unwrap kết quả phụ thuộc dữ liệu runtime (response API, input user, giá trị từ dictionary/JSON) — nil ở đây là chuyện bình thường, không phải bug logic.

## Không hardcode secret

API key, client secret, signing key không hardcode thẳng trong source (kể cả string literal ẩn trong constant file) — file `.swift` build vào binary có thể decompile/strings được. 

- Secret cần giữ bí mật tuyệt đối (private key ký request): không nên nhúng vào app client, xử lý phía server.
- Config khác nhau theo môi trường (base URL dev/staging/prod, key public không nhạy cảm): dùng `.xcconfig` per-scheme hoặc build configuration, không hardcode rồi comment/uncomment khi build từng môi trường.

## Validate input tại boundary

Validate ở nơi dữ liệu đi vào (form nhập liệu, response API trước khi decode, deep link params) — không giả định dữ liệu luôn đúng format.

```swift
guard let amount = Double(amountText), amount > 0 else {
    showError("Số tiền không hợp lệ")
    return
}
```

Không validate lại nhiều lớp thừa trong nội bộ app cho dữ liệu đã qua boundary 1 lần (YAGNI) — chỉ chỗ dữ liệu thực sự có thể sai (từ user, network, deep link) mới cần check.

## Tránh block main thread

I/O đồng bộ (đọc/ghi file lớn, network call đồng bộ, tính toán nặng) không chạy trên main thread — dùng `Task`/`async` hoặc `DispatchQueue.global()`. Block main thread quá lâu (~5s) khiến watchdog kill app hoặc UI đơ, gõ chạm không phản hồi.

```swift
Task.detached(priority: .background) {
    let result = heavyComputation()
    await MainActor.run {
        self.state = result
    }
}
```

Update UI luôn quay lại main thread (`MainActor`/`DispatchQueue.main`) — UIKit/SwiftUI không thread-safe.

## Retain cycle / leak

Closure giữ `self` mạnh trong property lưu lại lâu dài (completion handler lưu vào property, `Timer`, `NotificationCenter` observer, delegate) → retain cycle nếu không dùng `[weak self]`.

```swift
apiService.getBooking(id: id) { [weak self] result in
    guard let self else { return }
    self.state = result
}
```

`delegate` (pattern cũ, không phải Combine/closure) khai `weak var delegate: SomeDelegate?` — delegate mặc định phải là weak reference, tránh 2 object giữ nhau qua lại.

Dùng Xcode Instruments (Leaks/Allocations) để check khi nghi ngờ leak, không đoán mò.

## Dynamic Type & VoiceOver

### SwiftUI

```swift
Text("Số dư tài khoản")
    .font(.body) // dùng text style hệ thống (.body, .headline...), không hardcode kích thước cố định
    .dynamicTypeSize(...DynamicTypeSize.accessibility3) // cho phép scale tới mức accessibility nếu layout chịu được

Image(systemName: "person.crop.circle")
    .accessibilityLabel("Ảnh đại diện") // icon có ý nghĩa chức năng cần label
Image("decorative_banner")
    .accessibilityHidden(true) // ảnh trang trí thuần, VoiceOver bỏ qua
```

### UIKit

```swift
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true // tự scale theo Dynamic Type setting của user

iconButton.accessibilityLabel = "Quét mã QR"
decorativeImageView.isAccessibilityElement = false
```

Test nhanh: Settings > Accessibility > bật VoiceOver, nghe thứ tự đọc và label có hợp lý; bật Larger Text (Dynamic Type mức lớn) để kiểm tra layout không vỡ (text bị cắt, chồng lên nhau).

Touch target tối thiểu 44x44pt cho mọi button/icon bấm được (Apple HIG) — icon nhỏ hơn cần thêm padding, không phóng to icon.

## Bẫy cụ thể

- Force-unwrap kết quả decode JSON hoặc giá trị từ dictionary (`json["key"] as! String`) → crash `Unexpectedly found nil` khi server đổi field/thiếu field, thường chỉ phát hiện ở production qua crash report.
- Hardcode API key/secret trong file Swift kể cả khi đặt tên biến `private` — private chỉ giới hạn ở compile-time scope, không mã hoá giá trị trong binary, decompile/`strings` đọc được thẳng.
- Đóng closure completion lưu vào property (ví dụ observer, callback đăng ký 1 lần) mà không `[weak self]` → `self` không bao giờ được giải phóng dù screen đã dismiss, tích luỹ dần thành leak.
- Chạy network call hoặc parse JSON nặng trực tiếp trên main thread trong `viewDidLoad`/`onAppear` → UI đơ vài giây lúc mở màn hình, cảm giác app giật.
- Thiếu `accessibilityLabel` cho icon-only button → VoiceOver đọc "Button" vô nghĩa, user khiếm thị không biết chức năng nút.
- Hardcode font size cố định (`.system(size: 14)`) thay vì text style hệ thống → layout không scale theo Dynamic Type, user cần chữ lớn không đọc được.
