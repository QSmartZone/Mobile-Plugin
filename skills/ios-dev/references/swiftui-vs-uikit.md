# SwiftUI vs UIKit/Storyboard — chi tiết

## Bảng quyết định

| Tình huống | Chọn |
| --- | --- |
| Project mới hoàn toàn, chưa có UI code | SwiftUI |
| Project legacy 100% UIKit/Storyboard, thêm screen mới | Giữ UIKit/Storyboard để nhất quán flow; chỉ dùng SwiftUI qua `UIHostingController` khi được yêu cầu tường minh |
| Project legacy đang UIKit/Storyboard phức tạp, chỉ cần sửa nhỏ | Giữ nguyên UIKit/Storyboard — không đổi toolkit giữa chừng chỉ vì tiện |
| Screen đã SwiftUI, cần API chỉ có ở UIKit (camera/AR/print tùy phiên bản iOS) | `UIViewControllerRepresentable` interop chiều ngược lại, không quay về full UIKit |

Nguyên tắc chung: 1 screen chỉ dùng 1 toolkit chính. Đổi toolkit là quyết định kiến trúc, không phải tiện tay.

## Nhận diện project đang dùng gì

```
find . -name "*.storyboard" -o -name "*.xib"                 # có Storyboard/XIB
grep -rl "import SwiftUI" --include=*.swift .                # có SwiftUI
grep -rl "UIHostingController\|UIViewControllerRepresentable" --include=*.swift .  # đang interop 2 chiều
```

Có cả Storyboard lẫn SwiftUI → project đang ở giai đoạn migrate dần (hybrid) — kiểm tra screen cụ thể đang sửa dùng gì trước khi quyết định. Project 100% UIKit/Storyboard, kiến trúc MVC thuần (không có ViewModel layer) → giữ nguyên UIKit/Storyboard/MVC khi sửa bug nhỏ, không tự ép sang SwiftUI/MVVM.

## Khi nào SwiftUI thuần

Chỉ khi được yêu cầu tường minh dùng SwiftUI, hoặc project đã SwiftUI-first (chưa có UI code / đã migrate). Không tự chọn SwiftUI chỉ vì "screen mới độc lập, không ràng buộc Storyboard cũ" — project legacy UIKit vẫn giữ UIKit cho screen mới trừ khi có yêu cầu khác.

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
