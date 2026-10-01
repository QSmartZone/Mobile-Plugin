# API integration & error handling — details

## API call pattern

Retrofit interface + `suspend fun`, with an OkHttp interceptor handling auth header/logging/retry in one single place (`OkHttpClient.Builder().addInterceptor(...)`) — do not repeat this logic at each call site.

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

## Map errors → UI state with a sealed class

Use `Resource`/`Result` (Loading/Success/Error) instead of try-catch scattered across call sites.

`runCatching` around a suspend function also swallows `CancellationException` (a cancelled coroutine is treated as an ordinary error, breaking structured concurrency's cancellation mechanism) — use try/catch, rethrow `CancellationException` before the generic catch, or write one `runSuspendCatching` helper that does this in one place instead of repeating it at every call site.

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
        throw e // do not swallow coroutine cancellation
    } catch (e: Exception) {
        Resource.Error(e.message ?: "Unknown error")
    }
```

## Distinguish error types

- **Network** (`IOException`, `SocketTimeoutException`): lost connection/timeout — show a generic message like "Check your network connection", allow manual retry.
- **HTTP 4xx**: client error (bad input, expired token, no permission) — usually has a server message in the body; prefer showing that message to the user.
- **HTTP 5xx**: server error — do not show technical details, use a generic message ("The system is having problems, try again later").
- **Parse error** (`JsonDataException`, `SerializationException`): server data does not match the expected schema — log with the raw response for debugging, do not show it directly to the user.

## Choose local storage

- **Room**: need complex queries/relational data (join, filter, multi-condition sort).
- **DataStore** (Preferences or Proto): need typed key-value, coroutine/Flow-native — replaces SharedPreferences for new code.
- **SharedPreferences**: keep only when the project already uses it and has no need to migrate.

Do not add Room if the project has no complex query need — YAGNI.

## Specific pitfalls

- A generic `catch (e: Exception)` then showing `e.message`/stack trace straight to the user — leaks technical details, poor experience.
- Infinite retry without backoff on network errors → wastes battery/data, may spam the server.
- Using Retrofit's `Response<T>` wrapper without checking `response.isSuccessful` before reading `response.body()` — Retrofit does not throw for HTTP errors (4xx/5xx) with this wrapper, `body()` may be null or stale data leading to `NullPointerException`/wrong display.
- Storing tokens or sensitive data in plain `SharedPreferences` instead of Android Keystore — data is directly readable on a rooted/extracted device. `EncryptedSharedPreferences` (`security-crypto` library) has been deprecated since 2024 — new projects should use Keystore directly (`EncryptedFile`/Tink) or DataStore encrypted with a key stored in Keystore; projects already using `EncryptedSharedPreferences` need not migrate urgently.
- Not setting a timeout for `OkHttpClient` (using the default or forgetting to set it) → requests hang long on flaky networks, UI stuck in Loading indefinitely.
