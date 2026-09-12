# API integration & error handling — chi tiết

## Pattern gọi API

Gom logic gọi network vào 1 service riêng (`APIClient`/`NetworkService`), không gọi `URLSession` rải rác ở từng ViewModel/screen. Header auth, retry, logging xử lý tập trung 1 chỗ trong service này.

Stack: `URLSession` thô (không cần thêm dependency) đủ cho phần lớn app. Chỉ cần Alamofire khi project đã dùng sẵn hoặc cần tính năng Alamofire cho rẻ hơn tự viết (multipart upload phức tạp, request interceptor chain có sẵn) — không tự thêm mới cho app chưa có.

### Completion-handler (project legacy/còn dùng pattern cũ)

```swift
final class BookingService {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    func getBooking(id: String, completion: @escaping (Result<Booking, APIError>) -> Void) {
        let url = baseURL.appendingPathComponent("bookings/\(id)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.network(error)))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(.http(status: http.statusCode, data: data)))
                return
            }
            guard let data = data else {
                completion(.failure(.emptyBody))
                return
            }
            do {
                let dto = try JSONDecoder().decode(BookingDto.self, from: data)
                completion(.success(dto.toDomain()))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }.resume()
    }
}
```

Project hoàn toàn dùng completion-handler (`@escaping`) ở nhiều nơi thì giữ nguyên pattern đó khi sửa/thêm API mới trong cùng service — không tự ý đổi sang `async/await` giữa chừng một file, gây lẫn 2 style trong cùng codebase. Đổi cả file/module thì làm riêng, có chủ đích, không lồng vào task khác.

### async/await (code mới, project không ràng buộc pattern cũ)

```swift
final class BookingService {
    func getBooking(id: String) async throws -> Booking {
        let url = baseURL.appendingPathComponent("bookings/\(id)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(tokenProvider())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode, data: data)
        }
        do {
            return try JSONDecoder().decode(BookingDto.self, from: data).toDomain()
        } catch {
            throw APIError.decoding(error)
        }
    }
}
```

## Map lỗi → UI state bằng enum, không nuốt exception

```swift
enum APIError: Error {
    case network(Error)
    case invalidResponse
    case http(status: Int, data: Data?)
    case emptyBody
    case decoding(Error)
}

enum LoadState<T> {
    case loading
    case success(T)
    case failure(String) // message đã map sẵn cho UI, không phải raw error
}
```

ViewModel nhận `APIError`, map sang message hiển thị được rồi mới gán vào state — không throw/log rồi bỏ qua, không show thẳng `error.localizedDescription` cho lỗi kỹ thuật.

## Phân biệt loại lỗi

- **Network** (`URLError` với `.notConnectedToInternet`, `.timedOut`): mất kết nối/timeout — message chung "Kiểm tra kết nối mạng", cho phép retry thủ công.
- **HTTP 4xx**: lỗi client (sai input, token hết hạn, không có quyền) — parse message từ response body nếu có, ưu tiên hiển thị message đó.
- **HTTP 5xx**: lỗi server — không hiển thị chi tiết kỹ thuật, dùng message chung ("Hệ thống đang gặp sự cố, thử lại sau").
- **Decoding error** (`DecodingError`): dữ liệu server trả không đúng schema kỳ vọng — log kèm raw response để debug, không show trực tiếp cho user.

Timeout/retry/offline là error path ngang hàng happy path, không phải catch-all phụ:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 15
config.timeoutIntervalForResource = 30
let session = URLSession(configuration: config)
```

Retry có giới hạn số lần + backoff, và **chỉ retry lỗi transient** (timeout, mất kết nối, HTTP 5xx) — không retry lỗi 4xx (sai input/token hết hạn, retry lại vẫn fail y hệt) hay khi bị hủy:

```swift
func withRetry<T>(times: Int = 3, operation: () async throws -> T) async throws -> T {
    precondition(times > 0, "times must be > 0")
    for attempt in 0..<times {
        do { return try await operation() }
        catch let error as CancellationError { throw error } // không retry khi Task bị hủy
        catch {
            let isTransient: Bool
            switch error {
            case let urlError as URLError:
                isTransient = [.timedOut, .notConnectedToInternet, .networkConnectionLost].contains(urlError.code)
            case let apiError as APIError:
                if case .http(let status, _) = apiError {
                    isTransient = status >= 500
                } else {
                    isTransient = false
                }
            default:
                isTransient = false
            }
            guard isTransient, attempt < times - 1 else { throw error }
            try Task.checkCancellation() // dừng ngay nếu bị hủy giữa các lần retry
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
        }
    }
    fatalError("unreachable")
}
```

## Chọn nơi lưu local

- **Core Data**: cần query phức tạp/quan hệ dữ liệu (join, filter, sort nhiều điều kiện).
- **UserDefaults**: key-value đơn giản, không nhạy cảm (setting UI, flag, cache nhỏ) — **không** dùng cho token/password/secret.
- **Keychain**: token, password, bất kỳ credential nào — xem `platform-capabilities.md`.

Không tự thêm Core Data nếu project chưa cần query phức tạp — YAGNI.

## Bẫy cụ thể

- Bắt lỗi chung chung (`catch { }`, completion `.failure(let error)`) rồi show thẳng `error.localizedDescription` cho user — lộ chi tiết kỹ thuật, trải nghiệm kém.
- Retry vô hạn không backoff khi network lỗi → tốn pin/data, có thể spam server.
- Chỉ check `error == nil` trong completion handler mà không check `HTTPURLResponse.statusCode` — `URLSession` không tự throw lỗi cho HTTP 4xx/5xx, `error` vẫn `nil` dù server trả 404/500, dẫn tới code coi như thành công rồi decode data rỗng/sai.
- Không set `timeoutInterval` cho request/session (dùng default quá dài) → request treo lâu khi mạng chập chờn, UI kẹt ở trạng thái loading vô thời hạn.
- Lưu token bằng `UserDefaults` thay vì Keychain — dữ liệu đọc được trực tiếp qua backup/jailbreak (chi tiết ở `platform-capabilities.md`).
- Trộn completion-handler và `async/await` trong cùng 1 file/service không nhất quán — khó đọc, dễ leak callback khi wrap sai (`withCheckedContinuation` gọi completion 2 lần → crash).
