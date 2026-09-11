# Navigation iOS — chi tiết

Chọn theo cơ chế project đang dùng, không tự đổi giữa chừng trong cùng app hoặc cùng flow.

## Segue + prepare(for:)

Cho màn hình Storyboard. Kéo segue trong Interface Builder, truyền data qua `prepare(for:sender:)`. Chi tiết cơ chế + bẫy cụ thể: [uikit-storyboard.md](uikit-storyboard.md#segue-và-preparefor).

```swift
performSegue(withIdentifier: "showDetail", sender: booking)
```

## pushViewController thủ công

Cho flow UIKit không dùng Storyboard cho màn đích, hoặc cần điều kiện push động (không cố định bằng segue tĩnh).

```swift
let detailVC = DetailViewController(booking: booking)
navigationController?.pushViewController(detailVC, animated: true)
```

Truyền data qua initializer có kiểu (`DetailViewController(booking: booking)`) hoặc property gán ngay sau khởi tạo, không qua singleton/global state — tránh 2 instance cùng màn hình đọc nhầm state của nhau.

## NavigationStack (SwiftUI)

Cho app SwiftUI-first. Dùng `NavigationStack` + `NavigationPath` hoặc route enum có kiểu, không ghép string thủ công.

```swift
enum Route: Hashable {
    case detail(bookingID: String)
}

NavigationStack(path: $path) {
    List(bookings) { booking in
        NavigationLink(value: Route.detail(bookingID: booking.id)) {
            BookingRow(booking: booking)
        }
    }
    .navigationDestination(for: Route.self) { route in
        switch route {
        case .detail(let bookingID):
            DetailView(bookingID: bookingID)
        }
    }
}
```

## Coordinator pattern

Cho app cần tách navigation logic ra khỏi view controller/view (thường ở codebase đã áp dụng pattern này từ đầu) — 1 `Coordinator` object sở hữu `UINavigationController`, quyết định push/present màn nào, view controller chỉ báo "tôi cần điều hướng" qua closure/delegate chứ không tự gọi `navigationController?.pushViewController`.

```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

final class BookingCoordinator: Coordinator {
    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    func start() {
        let vc = BookingListViewController()
        vc.onSelectBooking = { [weak self] booking in
            self?.showDetail(for: booking)
        }
        navigationController.pushViewController(vc, animated: false)
    }
    private func showDetail(for booking: Booking) {
        navigationController.pushViewController(DetailViewController(booking: booking), animated: true)
    }
}
```

## Rule chọn theo cơ chế project đã dùng

| Project đang dùng | Làm gì |
| --- | --- |
| Toàn Storyboard, điều hướng qua segue | Thêm segue mới cùng cách, không tự chuyển sang `pushViewController` thủ công cho màn mới nếu các màn liên quan khác đều dùng segue |
| Toàn UIKit, điều hướng qua `pushViewController` thủ công (không Storyboard cho navigation) | Tiếp tục `pushViewController` thủ công, không tự thêm Storyboard/segue |
| Có `Coordinator` layer sẵn | Thêm navigation logic vào `Coordinator` tương ứng, không gọi thẳng `pushViewController` trong view controller |
| SwiftUI-first | `NavigationStack` + route enum có kiểu |

Ví dụ thực tế: 1 codebase 100% UIKit/Storyboard (4 storyboard + 6 xib), điều hướng qua segue ở 7 chỗ và `pushViewController` thủ công ở 6 chỗ, không có `Coordinator`. Khi thêm 1 màn hình mới vào đây: xem màn hình gọi tới nó đang dùng segue hay `pushViewController` thủ công, giữ đúng cách đó cho nhất quán trong cùng flow — không tự ý gom hết về `Coordinator` hoặc đổi hết segue thành `pushViewController` vì "gọn hơn". Đổi cơ chế điều hướng toàn app là quyết định kiến trúc riêng, cần yêu cầu tường minh.

## Truyền data qua argument có kiểu

Áp dụng cho mọi cơ chế ở trên — truyền qua initializer/property có kiểu rõ ràng (`DetailViewController(booking: booking)`, associated value trong route enum) hoặc segue's `prepare(for:)` với type check, không qua singleton/global mutable state (`AppState.shared.currentBooking = booking` rồi màn đích tự đọc lại). Singleton/global state khiến 2 instance cùng màn hình (mở 2 tab, back rồi mở lại) ghi đè state của nhau, và không compile-time check được kiểu dữ liệu truyền đi có đúng không.

## Bẫy cụ thể

- Mix segue và `pushViewController` thủ công cho cùng 1 flow chuyển màn — khó trace navigation logic nằm ở đâu (Storyboard hay code), review khó theo dõi.
- Truyền data qua singleton/global state thay vì argument có kiểu → 2 instance cùng màn hình đọc nhầm state của nhau, không phát hiện được lúc compile.
- `Coordinator` giữ strong reference tới view controller và view controller giữ strong reference ngược lại qua closure không khai `[weak self]` → retain cycle.
- Route enum SwiftUI dùng String thô ghép tay thay vì enum có kiểu/associated value → đổi tham số ở 1 nơi quên sửa chỗ khác, lỗi chỉ lộ khi chạy thử màn đó.
- Gọi `performSegue`/`pushViewController` nhiều lần liên tiếp do thiếu debounce khi double-tap → push trùng nhiều bản của cùng màn hình vào navigation stack.
