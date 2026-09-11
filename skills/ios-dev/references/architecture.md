# Kiến trúc iOS — chi tiết

## Nhận diện kiến trúc đang dùng qua code

```
grep -rl "import ComposableArchitecture" --include=*.swift .   # TCA
find . -type d -iname "Coordinator*"                            # Coordinator pattern
find . -type d \( -iname "Domain" -o -iname "Data" -o -iname "Presentation" \)  # Clean Architecture (theo layer folder)
find . -type d -iname "ViewModel*" -o -name "*ViewModel.swift"  # MVVM
find . -name "*Controller.swift" | xargs grep -L "ViewModel" 2>/dev/null  # MVC thuần (Controller không có ViewModel đi kèm)
```

Đọc kết quả theo thứ tự trên: có TCA → dừng, đó là TCA. Không có nhưng có Coordinator folder/file → Coordinator (thường kết hợp MVVM hoặc MVC bên dưới, kiểm tra tiếp). Có Domain/Data/Presentation → Clean Architecture. Có `*ViewModel.swift` phổ biến → MVVM. Toàn `*Controller.swift` không kèm ViewModel → MVC thuần.

Project chỉ có ViewModel cho vài feature, còn lại là Controller không ViewModel → đang ở MVC thuần (chưa migrate hết sang MVVM) — khi sửa 1 feature cụ thể, theo đúng pattern feature đó đang dùng, không tự thêm ViewModel cho Controller đang chạy tốt.

## Khi nào thêm layer mới

Không tự thêm Coordinator/Clean Architecture/TCA vào project đang chạy MVC hay MVVM đơn giản chỉ vì "đúng chuẩn kiến trúc". Chỉ thêm khi có nhu cầu cụ thể: navigation phức tạp nhiều luồng rẽ nhánh (→ Coordinator), nhiều nguồn dữ liệu/cần test domain logic độc lập UI (→ Clean Architecture layer), state phức tạp cần side-effect thuần và test dễ tái hiện (→ TCA) — và đó là quyết định kiến trúc cần nêu rõ, không lồng vào 1 bug fix nhỏ.

## Layer (mặc định MVVM khi project mới/chưa có pattern sẵn)

```
View (SwiftUI) → ViewModel (@Observable) → Service/Repository → Network/DB
```

## ViewModel với Swift Concurrency

```swift
@Observable
final class BookingListViewModel {
    private(set) var state: BookingUiState = .loading
    private let repo: BookingRepository

    init(repo: BookingRepository = .live) {
        self.repo = repo
    }

    func load() async {
        state = .loading
        do {
            let bookings = try await repo.fetchBookings()
            state = .success(bookings)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

enum BookingUiState {
    case loading
    case success([Booking])
    case error(String)
}
```

`@Observable` (Swift 5.9+/iOS 17+) thay `ObservableObject` + `@Published` khi dự án đủ điều kiện deployment target — ít boilerplate hơn, chỉ re-render property thực sự đổi thay vì cả object.

## Swift Concurrency thay GCD

```swift
// Cũ (GCD) — chỉ giữ khi file đang sửa đã dùng pattern này nhất quán
DispatchQueue.global().async {
    let result = fetchData()
    DispatchQueue.main.async { self.updateUI(result) }
}

// Mới (async/await) — dùng cho code mới
Task {
    let result = await fetchData()
    self.updateUI(result)
}
```

## Dependency injection

Constructor injection đơn giản (như ví dụ trên: `init(repo:)` với default `.live` cho production, override trong test) — đủ dùng cho phần lớn app iOS, không cần framework DI riêng trừ khi app rất lớn nhiều team.

## Navigation

Chọn theo cơ chế navigation project đang dùng (segue, push thủ công, Coordinator, hay `NavigationStack`) — xem references/navigation.md.
