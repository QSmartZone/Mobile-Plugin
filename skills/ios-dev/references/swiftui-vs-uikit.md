# SwiftUI vs UIKit/Storyboard — chi tiết

## Khi nào SwiftUI thuần

Màn hình mới, không có ràng buộc với Storyboard cũ. SwiftUI cho tốc độ phát triển nhanh hơn, preview trực tiếp, ít boilerplate layout.

```swift
struct BookingListView: View {
    @State private var viewModel = BookingListViewModel()

    var body: some View {
        List(viewModel.bookings) { booking in
            BookingRow(booking: booking)
        }
        .task { await viewModel.load() }
    }
}
```

## Khi nào giữ UIKit/Storyboard

- Màn hình đang maintain đã là Storyboard — sửa đúng trong Storyboard/`.swift` tương ứng, không tự ý viết lại bằng SwiftUI (đổi kiến trúc ngoài phạm vi yêu cầu).
- Cần API chỉ có ở UIKit (một số control camera/AR/print tùy phiên bản iOS) — bọc qua `UIViewControllerRepresentable`.

## Nhúng UIKit vào SwiftUI

```swift
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController()
    }
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
```

## Nhúng SwiftUI vào UIKit (màn hình cũ, thêm 1 phần SwiftUI mới)

```swift
let hostingController = UIHostingController(rootView: NewFeatureView())
navigationController?.pushViewController(hostingController, animated: true)
```

## Nguyên tắc

Không migrate UIKit→SwiftUI hoặc ngược lại "tiện tay" khi đang sửa bug khác — đổi kiến trúc màn hình là quyết định riêng, cần được yêu cầu tường minh.
