# SwiftUI ↔ UIKit Interoperability — chi tiết

Khi nào chọn hướng nào: [swiftui-vs-uikit.md](swiftui-vs-uikit.md). File này tập trung cơ chế interop 2 chiều.

## UIHostingController — nhúng SwiftUI vào UIKit

Dùng khi màn hình UIKit/Storyboard cũ cần thêm 1 phần mới bằng SwiftUI (không viết lại cả màn hình).

```swift
let hostingController = UIHostingController(rootView: NewFeatureView(viewModel: viewModel))
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.view.frame = containerView.bounds
hostingController.didMove(toParent: self)
```

Nếu chỉ push cả màn hình SwiftUI từ flow UIKit (không nhúng vào 1 phần view), push thẳng `UIHostingController` không cần `addChild` thủ công:

```swift
navigationController?.pushViewController(UIHostingController(rootView: NewFeatureView()), animated: true)
```

## UIViewControllerRepresentable — nhúng UIViewController vào SwiftUI

Dùng khi cần cả 1 `UIViewController` (camera, AR, print, SDK bên thứ 3 chỉ có UIKit API) hiển thị trong cây SwiftUI.

```swift
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let vc = CameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // đồng bộ property khi SwiftUI state đổi, ví dụ bật/tắt flash
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraViewControllerRepresentable
        init(_ parent: CameraViewControllerRepresentable) { self.parent = parent }

        func didCapture(_ image: UIImage) {
            parent.capturedImage = image
        }
    }
}
```

## UIViewRepresentable — nhúng 1 UIView (không phải UIViewController)

Tương tự `UIViewControllerRepresentable` nhưng cho `UIView` đơn lẻ (ví dụ `UITextView` cần API chưa có ở `TextEditor`, banner ad SDK).

```swift
struct RichTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: RichTextView
        init(_ parent: RichTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
```

## Coordinator pattern

`Coordinator` là cầu nối bắt buộc mỗi khi UIKit view/view controller cần báo sự kiện ngược lại SwiftUI (delegate, target-action, closure callback) — SwiftUI struct không giữ được state/identity ổn định qua nhiều lần `update`, nên logic delegate phải đặt trong 1 object riêng (`NSObject` subclass) do `makeCoordinator()` tạo và giữ vòng đời song song với `Representable`.

- Không implement delegate trực tiếp trên struct `Representable` — struct bị tạo lại liên tục, không giữ được identity ổn định cho delegate.
- Coordinator giữ `parent` (thường là `unowned` hoặc struct copy, không retain cycle vì SwiftUI quản lý vòng đời `Coordinator`) để gọi ngược binding/closure lên SwiftUI.

## Đồng bộ state 2 chiều

| Hướng | Cơ chế |
| --- | --- |
| SwiftUI → UIKit | `updateUIView(_:context:)` / `updateUIViewController(_:context:)` — được gọi lại mỗi khi SwiftUI state phụ thuộc đổi |
| UIKit → SwiftUI | `Coordinator` nhận callback (delegate/target-action) rồi gán vào `@Binding` hoặc gọi closure truyền từ SwiftUI |

Tránh vòng lặp vô hạn: khi `Coordinator` set `@Binding` để báo ngược SwiftUI, và `updateUIView` lại set UIKit view dựa trên `@Binding` đó — luôn so sánh giá trị cũ/mới trước khi set (như ví dụ `if uiView.text != text` ở trên) để không gọi lại delegate ngay trong `updateUIView`.

## Migrate dần Storyboard → SwiftUI

Chiến lược an toàn khi migrate 1 app UIKit/Storyboard lớn: đi từng màn hình lá (leaf screen, không có nhiều màn con), không migrate cả flow cùng lúc.

1. Chọn 1 màn hình độc lập, ít phụ thuộc navigation phức tạp.
2. Viết lại bằng SwiftUI thuần, giữ nguyên `ViewModel`/service layer nếu đã tách sẵn.
3. Nhúng qua `UIHostingController`, push/present từ chỗ code UIKit cũ gọi màn hình đó — không đổi entry point navigation.
4. App ở trạng thái hybrid (vừa Storyboard vừa SwiftUI) qua nhiều PR — chấp nhận được, không ép migrate 100% trong 1 lần.
5. Lặp lại cho màn tiếp theo khi có yêu cầu, không tự ý migrate thêm màn ngoài phạm vi task.

## Bẫy cụ thể

- Implement delegate/target-action trực tiếp trên struct `UIViewRepresentable`/`UIViewControllerRepresentable` thay vì qua `Coordinator` → mất event hoặc crash do struct bị tái tạo liên tục.
- `updateUIView`/`updateUIViewController` set giá trị không so sánh trước → vòng lặp update-callback-update vô hạn khi có binding 2 chiều.
- Retain cycle giữa `Coordinator` và `UIViewController` được bọc (`Coordinator` giữ strong reference tới `UIViewController`, `UIViewController` giữ strong reference tới `Coordinator` qua `delegate` không khai `weak`) → leak.
- Tự ý migrate nguyên flow Storyboard sang SwiftUI khi task chỉ yêu cầu sửa 1 bug nhỏ trong flow đó — đổi kiến trúc ngoài phạm vi yêu cầu.
