# Kiến trúc iOS — chi tiết

## Layer

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

`NavigationStack` (iOS 16+) với `NavigationPath`/type-safe value cho push/pop, thay `NavigationView` cũ đã deprecated.
