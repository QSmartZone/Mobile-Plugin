---
name: ios-dev
description: Nguyên tắc và convention viết iOS native (SwiftUI/UIKit/Storyboard theo tiền lệ project, không mặc định SwiftUI) — kiến trúc MVVM/MVC/Coordinator/TCA, Swift Concurrency/Combine/Rx, testing, navigation, API/error handling, platform capabilities (permission, Keychain, background task, push, deep link), security/performance/accessibility, interoperability UIKit-SwiftUI. Dùng khi chạm file .swift, .storyboard, .xib, hoặc câu hỏi về iOS dev.
---

# iOS Dev Specialist

## Soi project trước

Trước khi code, đọc để biết project đang dùng gì — không tự ý đổi công nghệ nếu không được yêu cầu tường minh:

- UI: `grep -r "import SwiftUI"`/`: View` vs `.storyboard`/`.xib`/subclass `UIViewController` — tỷ lệ nào chiếm đa số màn hình hiện có.
- Kiến trúc: MVVM/MVC/Coordinator/Clean Architecture/TCA — theo cái project đã có, không tự thêm layer khi chưa cần.
- Concurrency: async/await hay Combine hay RxSwift/RxCocoa hay completion-handler — theo pattern nhất quán trong file đang sửa.
- Dependency manager: Swift Package Manager (SPM) hay CocoaPods.
- Deployment target (`IPHONEOS_DEPLOYMENT_TARGET`): quyết định API dùng được, ví dụ `@Observable` cần iOS 17+.

Rồi theo đúng cái project đã có.

## SwiftUI vs UIKit/Storyboard vs Hybrid

Không mặc định SwiftUI. Chọn theo tiền lệ project và yêu cầu cụ thể:

- **SwiftUI**: feature đang sửa đã là SwiftUI, hoặc màn hình mới được yêu cầu tường minh dùng SwiftUI.
- **UIKit/Storyboard**: feature đang Storyboard/segue-based, hoặc project có pattern UIKit đã thiết lập cần giữ nguyên — không tự ý migrate sang SwiftUI trừ khi được yêu cầu.
- **Hybrid**: cần tích hợp UIKit cũ với SwiftUI mới, hoặc đang migrate dần từng màn hình — dùng `UIViewRepresentable`/`UIViewControllerRepresentable`/`UIHostingController` thay vì viết lại cả màn hình.

Chi tiết: [references/swiftui-vs-uikit.md](references/swiftui-vs-uikit.md), [references/interoperability.md](references/interoperability.md).

## Kiến trúc

Theo pattern project đã có (MVVM, MVC, Coordinator, Clean Architecture, hoặc TCA) — không tự thêm layer (Repository/UseCase/Coordinator...) khi project chưa có và chưa có nhu cầu cụ thể. `View`/`ViewController` không chứa business logic — chỉ render từ state layer dưới expose.

Chi tiết: [references/architecture.md](references/architecture.md).

## Swift Concurrency & state

- `async/await`/`Task` ưu tiên cho code mới nếu deployment target cho phép và project chưa có Combine/RxSwift established theo hướng khác.
- Giữ nguyên completion-handler/Combine/Rx khi sửa file cũ đã dùng pattern đó nhất quán — không trộn mô hình async trong cùng file.
- Tôn trọng `@MainActor`/actor isolation khi update UI hoặc state từ background.

Chi tiết: [references/architecture.md](references/architecture.md).

## UIKit & Storyboard

Lifecycle (`viewDidLoad`/`viewWillAppear`...), `@IBOutlet`/`@IBAction`, segue, Auto Layout, `UITableView`/`UICollectionView` (datasource/delegate, cell reuse), containment (child view controller), tránh retain cycle trong closure (`[weak self]`).

Chi tiết: [references/uikit-storyboard.md](references/uikit-storyboard.md).

## Testing

XCTest cho logic (ViewModel, service, business logic), XCUITest cho end-to-end flow quan trọng. SwiftUI Preview dùng để dev nhanh, không thay thế test tự động. Project chưa có test target thì đề xuất thêm target trước khi viết test, không âm thầm bỏ qua.

Chi tiết: [references/testing.md](references/testing.md).

## Navigation

Điều hướng theo cơ chế project đã dùng — segue/`pushViewController` thủ công, `NavigationStack`/`NavigationLink` (SwiftUI), hoặc Coordinator pattern — không tự đổi cơ chế nếu không được yêu cầu. Truyền dữ liệu giữa màn hình qua kiểu rõ ràng, tránh singleton/global state để pass data.

Chi tiết: [references/navigation.md](references/navigation.md).

## API integration & xử lý lỗi

Gọi network qua stack đã có trong dự án (`URLSession` thô, Alamofire, hoặc custom network service), map lỗi HTTP/network/decode thành UI state rõ ràng (loading/success/error) — không nuốt exception. Timeout, retry, offline đều là error path xử lý ngang hàng happy path.

Chi tiết: [references/api-integration-error-handling.md](references/api-integration-error-handling.md).

## iOS platform capabilities

Permission (khai báo usage description trong `Info.plist` trước khi request), Keychain cho dữ liệu nhạy cảm (không lưu token/password trong `UserDefaults`), background task (`BGTaskScheduler`), push notification, universal link/deep link — chỉ implement capability project thực sự cần, không thêm sẵn cho tương lai.

Chi tiết: [references/platform-capabilities.md](references/platform-capabilities.md).

## Bảo mật, hiệu năng, accessibility

Tránh force-unwrap (`!`) trừ khi chắc chắn 100% (ví dụ `@IBOutlet` đã connect); validate input ở boundary. Tránh block main thread (I/O, tính toán nặng phải đưa ra background). Accessibility cho UI mới: Dynamic Type, VoiceOver label, touch target size, contrast tối thiểu.

Chi tiết: [references/security-performance-accessibility.md](references/security-performance-accessibility.md).

## Package quản lý

Swift Package Manager (SPM) mặc định cho dependency mới. CocoaPods chỉ khi dự án đã dùng và lib cần thêm chưa có bản SPM.
