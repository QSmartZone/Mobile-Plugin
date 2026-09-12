# API integration & error handling — chi tiết

## Pattern gọi API

Retrofit interface + `suspend fun`, OkHttp interceptor xử lý auth header/logging/retry 1 chỗ duy nhất (`OkHttpClient.Builder().addInterceptor(...)`) — không lặp lại logic này ở từng call site.

```kotlin
interface BookingApi {
    @GET("bookings/{id}")
    suspend fun getBooking(@Path("id") id: String): Response<BookingDto>
}

class AuthInterceptor(private val tokenProvider: () -> String) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): okhttp3.Response {
        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer ${tokenProvider()}")
            .build()
        return chain.proceed(request)
    }
}
```

## Map lỗi → UI state bằng sealed class

Dùng `Resource`/`Result` (Loading/Success/Error) thay vì try-catch rải rác ở từng nơi gọi API.

`runCatching` quanh suspend function nuốt luôn `CancellationException` (coroutine bị cancel bị coi như lỗi bình thường, phá cơ chế cancel của structured concurrency) — dùng try/catch, rethrow `CancellationException` trước khi catch chung, hoặc viết 1 helper `runSuspendCatching` làm việc này ở 1 chỗ thay vì lặp lại mỗi call site.

```kotlin
import kotlinx.coroutines.CancellationException

suspend fun getBooking(id: String): Resource<Booking> =
    try {
        val resp = api.getBooking(id)
        if (resp.isSuccessful) {
            resp.body()?.let { Resource.Success(it.toDomain()) }
                ?: Resource.Error("Empty body")
        } else {
            Resource.Error(resp.errorBody()?.string() ?: "HTTP ${resp.code()}")
        }
    } catch (e: CancellationException) {
        throw e // không nuốt cancellation của coroutine
    } catch (e: Exception) {
        Resource.Error(e.message ?: "Unknown error")
    }
```

## Phân biệt loại lỗi

- **Network** (`IOException`, `SocketTimeoutException`): mất kết nối/timeout — hiển thị message chung kiểu "Kiểm tra kết nối mạng", cho phép retry thủ công.
- **HTTP 4xx**: lỗi client (sai input, hết hạn token, không có quyền) — thường có message từ server trong body, ưu tiên hiển thị message đó cho user.
- **HTTP 5xx**: lỗi server — không hiển thị chi tiết kỹ thuật, dùng message chung ("Hệ thống đang gặp sự cố, thử lại sau").
- **Lỗi parse** (`JsonDataException`, `SerializationException`): dữ liệu server trả không đúng schema kỳ vọng — log kèm raw response để debug, không show trực tiếp cho user.

## Chọn nơi lưu local

- **Room**: cần query phức tạp/quan hệ dữ liệu (join, filter, sort nhiều điều kiện).
- **DataStore** (Preferences hoặc Proto): cần key-value có kiểu, coroutine/Flow-native — thay SharedPreferences cho code mới.
- **SharedPreferences**: chỉ giữ khi project đã dùng sẵn và chưa có nhu cầu migrate.

Không tự thêm Room nếu project chưa cần query phức tạp — YAGNI.

## Bẫy cụ thể

- Bắt `catch (e: Exception)` chung chung rồi show thẳng `e.message`/stack trace cho user — lộ chi tiết kỹ thuật, trải nghiệm kém.
- Retry vô hạn không backoff khi network lỗi → tốn pin/data, có thể spam server.
- Dùng `Response<T>` wrapper của Retrofit nhưng không check `response.isSuccessful` trước khi đọc `response.body()` — Retrofit không tự throw exception cho lỗi HTTP (4xx/5xx) khi dùng wrapper này, `body()` có thể null hoặc là data cũ dẫn tới `NullPointerException`/hiển thị sai.
- Lưu token hoặc dữ liệu nhạy cảm bằng `SharedPreferences` thường thay vì Android Keystore — dữ liệu đọc được trực tiếp khi thiết bị root/bị extract. `EncryptedSharedPreferences` (thư viện `security-crypto`) đã deprecated từ 2024 — dự án mới nên dùng Keystore trực tiếp (`EncryptedFile`/Tink) hoặc DataStore mã hoá bằng key lưu trong Keystore; dự án đang dùng `EncryptedSharedPreferences` thì chưa cần migrate gấp.
- Không set timeout cho `OkHttpClient` (dùng default hoặc quên set) → request treo lâu khi mạng chập chờn, UI kẹt ở trạng thái Loading vô thời hạn.
