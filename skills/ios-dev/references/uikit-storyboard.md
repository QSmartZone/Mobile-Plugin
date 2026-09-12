# UIKit/Storyboard — chi tiết

## Bẫy cụ thể

- Tên `@IBOutlet`/`@IBAction` trong code lệch với Storyboard sau khi rename → crash `NSUnknownKeyException` lúc runtime, không phát hiện lúc build.
- `prepare(for:)` không check `segue.identifier` khi có nhiều segue ra từ cùng 1 view controller → gán nhầm data.
- Truyền data giữa 2 màn hình qua singleton/global mutable state thay vì property trên `destination` — 2 instance cùng màn hình đọc/ghi đè state của nhau.
- Quên `dequeueReusableCell` hoặc quên reset state trong `prepareForReuse()` → cell hiện sai data khi scroll.
- Đăng ký observer/notification ở `viewDidLoad()` nhưng không unregister ở `deinit`/`viewWillDisappear()` (khi cần theo từng lần appear) → nhận callback dù màn hình đã đóng, hoặc leak.
- Closure completion handler capture `self` strong trong view controller có vòng đời ngắn (dismiss sớm trong khi request đang chạy) → retain cycle, `self` không deinit đúng lúc.
- Update UIKit view từ background thread không qua `DispatchQueue.main.async` → UI không refresh hoặc crash không tái hiện ổn định.

## UIViewController lifecycle

Thứ tự gọi khi 1 màn hình xuất hiện/biến mất:

```
loadView() → viewDidLoad()
  → viewWillAppear() → viewIsAppearing() (iOS 17+) → viewDidAppear()
  → viewWillDisappear() → viewDidDisappear()
```

`viewDidLoad()` chạy đúng 1 lần (setup outlet/delegate/observer); `viewWillAppear`/`viewDidAppear` chạy lại mỗi lần màn hình xuất hiện (chỗ refresh data, không phải setup); `viewWillDisappear`/`viewDidDisappear` cleanup theo cặp (huỷ timer, unregister observer).

## IBOutlet / IBAction

```swift
@IBOutlet weak var titleLabel: UILabel!
@IBAction func didTapSubmit(_ sender: UIButton) {
    viewModel.submit()
}
```

- `@IBOutlet` luôn khai `weak` (trừ trường hợp đặc biệt cần giữ view sống ngoài view hierarchy) — tránh retain cycle giữa view và view controller; `!` (implicitly unwrapped) chấp nhận được ở đây vì Storyboard đảm bảo outlet đã connect trước khi dùng, không phải chỗ optional tuỳ tiện dùng `!`.
- Đặt tên outlet/action khớp Storyboard — đổi tên property trong code mà không đổi trong Storyboard (hoặc ngược lại) → crash runtime `NSUnknownKeyException`, Xcode không luôn cảnh báo trước khi build.

## Segue và prepare(for:)

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail",
       let detailVC = segue.destination as? DetailViewController,
       let booking = sender as? Booking {
        detailVC.booking = booking
    }
}
```

- Truyền data qua property có kiểu rõ ràng trên `destination` (như `booking: Booking` ở trên), không qua singleton/global state — tránh 2 màn hình đọc nhầm state của nhau khi mở nhiều instance cùng lúc.
- Check `segue.identifier` khi 1 view controller có nhiều segue trỏ ra — quên check → gán nhầm data cho segue khác.

## Auto Layout

- Constraint mâu thuẫn (ambiguous/unsatisfiable) chỉ lộ ra ở runtime qua console log `Unable to simultaneously satisfy constraints`, Interface Builder có thể không báo đỏ nếu constraint hợp lệ về mặt cú pháp nhưng logic sai (ví dụ leading + trailing + width cùng lúc, thừa 1 constraint).
- Ưu tiên `UIStackView` cho layout tuyến tính (danh sách nút, form field xếp dọc) thay vì tự set từng constraint — giảm số constraint phải quản lý tay.
- `translatesAutoresizingMaskIntoConstraints = false` bắt buộc khi thêm view bằng code rồi set constraint bằng tay (không qua Storyboard) — quên dòng này → constraint set không có tác dụng, view giữ nguyên frame mặc định.

## Size class

Dùng `UITraitCollection`/size class (`Compact`/`Regular` theo width, height) để layout khác nhau giữa iPhone portrait, iPhone landscape, iPad — set trong Interface Builder qua "vary for traits" hoặc check `traitCollection.horizontalSizeClass` trong code khi cần logic động.

## UITableView / UICollectionView

```swift
tableView.dataSource = self
tableView.delegate = self
tableView.register(BookingCell.self, forCellReuseIdentifier: BookingCell.reuseID)

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: BookingCell.reuseID, for: indexPath) as! BookingCell
    cell.configure(with: bookings[indexPath.row])
    return cell
}
```

- Luôn `dequeueReusableCell` (không tự `init` cell mới trong `cellForRowAt`) — cell reuse là cơ chế cốt lõi để scroll mượt với list dài.
- Reset state cell trong `configure(with:)` hoặc `prepareForReuse()` cho property có thể "dính" từ lần dùng trước (ảnh async load, background color đổi tạm) — quên reset → cell cũ hiện sai data khi bị tái sử dụng cho item khác.

## Containment (Child View Controller)

```swift
addChild(childVC)
containerView.addSubview(childVC.view)
childVC.view.frame = containerView.bounds
childVC.didMove(toParent: self)
```

Thứ tự bắt buộc: `addChild` → add view vào hierarchy → `didMove(toParent:)`. Khi remove: `willMove(toParent: nil)` → `view.removeFromSuperview()` → `removeFromParent()`. Thiếu `didMove`/`willMove` → lifecycle event (`viewWillAppear` của con) không được forward đúng.

## Custom reusable view / XIB

```swift
final class BookingCardView: UIView {
    static func loadFromNib() -> BookingCardView {
        Bundle.main.loadNibNamed("BookingCardView", owner: nil)?.first as! BookingCardView
    }
}
```

Đặt tên file XIB trùng tên class để dễ maintain. Custom view load từ XIB cần set `File's Owner`/root view đúng trong Interface Builder trước, nếu không `loadNibNamed` trả về `nil` hoặc sai type.

## Retain cycle trong closure

```swift
apiClient.fetchBookings { [weak self] result in
    guard let self else { return }
    self.bookings = result
    self.tableView.reloadData()
}
```

`UIViewController` giữ closure (qua property hoặc completion handler đăng ký dài hạn) mà closure lại capture `self` strong → `self` không bao giờ được deinit khi màn hình đóng (dismiss/pop) vì closure vẫn giữ tham chiếu. Luôn `[weak self]` cho closure có vòng đời dài hơn 1 lần gọi tức thời (network callback, notification observer, timer).

## Update UI trên main thread

```swift
DispatchQueue.main.async {
    self.tableView.reloadData()
}
```

Mọi thao tác UIKit (`reloadData`, set text, animation) phải chạy trên main thread — gọi từ background thread (network callback thô chưa dispatch, `DispatchQueue.global`) gây UI update không hiển thị ngay hoặc crash không nhất quán (`UIKit is only safe to use from the main thread`), không phải lỗi luôn crash ngay lập tức nên dễ bị bỏ sót khi test.
