# API integration & error handling — details

## API call pattern

Gather network-call logic into one dedicated service (`APIClient`/`NetworkService`); do not scatter `URLSession` calls across ViewModels/screens. Handle auth headers, retry, logging centrally in this service.

Stack: plain `URLSession` (no extra dependency) is enough for most apps. Use Alamofire only when the project already has it or needs a feature cheaper than writing it yourself (complex multipart upload, an existing request interceptor chain) — do not add it to an app that lacks it.

### Completion-handler (legacy project/still using the old pattern)

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

Project uses completion-handlers (`@escaping`) throughout → keep that pattern when editing/adding a new API in the same service — do not switch to `async/await` midway through a file, which mixes 2 styles in one codebase. Converting a whole file/module is done separately, deliberately, not folded into another task.

### async/await (new code, project not bound to the old pattern)

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

## Map errors → UI state with an enum, do not swallow exceptions

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
    case failure(String) // message already mapped for the UI, not a raw error
}
```

The ViewModel receives `APIError`, maps it to a displayable message, then assigns it to state — do not throw/log and ignore, do not show `error.localizedDescription` directly for technical errors.

## Distinguish error types

- **Network** (`URLError` with `.notConnectedToInternet`, `.timedOut`): lost connection/timeout — generic message "Check your network connection", allow manual retry.
- **HTTP 4xx**: client error (bad input, expired token, no permission) — parse the message from the response body if present, prefer displaying that message.
- **HTTP 5xx**: server error — do not show technical details, use a generic message ("The system is having problems, try again later").
- **Decoding error** (`DecodingError`): server data does not match the expected schema — log with the raw response for debugging, do not show it directly to the user.

Timeout/retry/offline are error paths equal to the happy path, not a secondary catch-all:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 15
config.timeoutIntervalForResource = 30
let session = URLSession(configuration: config)
```

Retry with a capped count + backoff, and **retry only transient errors** (timeout, lost connection, HTTP 5xx) — do not retry 4xx errors (bad input/expired token, retrying fails identically) or on cancellation:

```swift
func withRetry<T>(times: Int = 3, operation: () async throws -> T) async throws -> T {
    precondition(times > 0, "times must be > 0")
    for attempt in 0..<times {
        do { return try await operation() }
        catch let error as CancellationError { throw error } // do not retry when the Task is cancelled
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
            try Task.checkCancellation() // stop immediately if cancelled between retries
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
        }
    }
    fatalError("unreachable")
}
```

## Choose where to store locally

- **Core Data**: complex queries/data relationships (joins, multi-condition filter, sort).
- **UserDefaults**: simple, non-sensitive key-value (UI settings, flags, small cache) — **not** for token/password/secret.
- **Keychain**: token, password, any credential — see `platform-capabilities.md`.

Do not add Core Data if the project has no need for complex queries — YAGNI.

## Specific pitfalls

- Catching generically (`catch { }`, completion `.failure(let error)`) then showing `error.localizedDescription` directly to the user — leaks technical details, poor experience.
- Infinite retry without backoff on network errors → drains battery/data, may spam the server.
- Checking only `error == nil` in the completion handler without checking `HTTPURLResponse.statusCode` — `URLSession` does not throw for HTTP 4xx/5xx, `error` stays `nil` even if the server returns 404/500, so the code treats it as success and decodes empty/wrong data.
- Not setting `timeoutInterval` for the request/session (default is too long) → requests hang when the network is flaky, UI stuck in loading indefinitely.
- Storing tokens in `UserDefaults` instead of Keychain — data is readable directly via backup/jailbreak (details in `platform-capabilities.md`).
- Mixing completion-handler and `async/await` inconsistently in the same file/service — hard to read, easy to leak callbacks when wrapped wrongly (`withCheckedContinuation` calling completion twice → crash).
