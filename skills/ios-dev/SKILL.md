---
name: ios-dev
description: Nguyên tắc và convention viết iOS native (SwiftUI mặc định, UIKit/Storyboard khi maintain code cũ) — kiến trúc MVVM + Swift Concurrency, testing. Dùng khi chạm file .swift, .storyboard, .xib, hoặc câu hỏi về iOS dev.
---

# iOS Dev Specialist

## SwiftUI vs UIKit/Storyboard

SwiftUI mặc định cho màn hình mới. UIKit/Storyboard chỉ khi:
1. Dự án hiện tại còn Storyboard cho màn hình đang sửa — maintain đúng theo cái đang có, không tự ý migrate sang SwiftUI trừ khi được yêu cầu.
2. Cần API/behavior UIKit chưa có bản SwiftUI tương đương — dùng `UIViewRepresentable`/`UIViewControllerRepresentable` để nhúng vào SwiftUI thay vì viết cả màn hình bằng UIKit.

Chi tiết: [references/swiftui-vs-uikit.md](references/swiftui-vs-uikit.md).

## Kiến trúc — MVVM + Swift Concurrency

- `ViewModel` là `@Observable`/`ObservableObject`, expose state cho View, gọi service/repository qua `async/await`.
- Swift Concurrency (`async/await`, `Task`) thay GCD callback lồng nhau (`DispatchQueue.main.async { ... }`) cho code mới. Giữ nguyên GCD khi sửa file cũ đã dùng pattern đó nhất quán.
- `View` (SwiftUI) không chứa business logic — chỉ render từ state ViewModel expose.

Chi tiết: [references/architecture.md](references/architecture.md).

## Testing

XCTest cho logic (ViewModel, service), XCUITest cho end-to-end flow quan trọng. SwiftUI Preview dùng để dev nhanh, không thay thế test tự động. Chi tiết: [references/testing.md](references/testing.md).

## Swift conventions

- Optional: tránh force-unwrap (`!`) trừ khi chắc chắn 100% (ví dụ `@IBOutlet` đã connect); ưu tiên `if let`/`guard let`/`??`.
- `struct` cho model (value type, tránh mutation ngoài ý muốn khi truyền qua nhiều layer), `class` chỉ khi cần reference semantics (ViewModel, service có shared state).
- `enum` với associated value để model kết quả (`Result<Success, Failure>`) hoặc state UI (loading/success/error) thay vì nhiều optional rời rạc.

## Package quản lý

Swift Package Manager (SPM) mặc định cho dependency mới. CocoaPods chỉ khi dự án đã dùng và lib cần thêm chưa có bản SPM.
