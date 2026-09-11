# Kotlin conventions — chi tiết

## Coroutines & Flow

- `viewModelScope`/`lifecycleScope` cho coroutine gắn vòng đời — tự huỷ khi component destroy, tránh leak.
- `Flow` cho stream dữ liệu (DB observe, WebSocket); `suspend fun` đơn giản cho request 1 lần.
- Đổi thread bằng `withContext(Dispatchers.IO)` quanh call blocking (DB, file, network cũ không suspend-aware), không đổi `Dispatchers.Main` thủ công trong ViewModel — Compose/`collectAsState` tự switch main thread khi collect.

```kotlin
suspend fun getBookings(): List<Booking> = withContext(Dispatchers.IO) {
    api.fetchBookings()
}
```

## Null-safety

- Tránh `!!` — nếu chắc chắn không null thì dùng kiểu non-null ngay từ đầu (khai báo đúng type), nếu không chắc thì xử lý nhánh null tường minh (`?.let`, `?:`, early return).
- `lateinit var` chỉ cho property chắc chắn được khởi tạo trước khi dùng (ví dụ trong `onCreate`), không lạm dụng để né nullable.

## Sealed class cho state

Model UI/domain state bằng sealed class/interface thay vì nhiều `Boolean`/`String?` rời rạc (`isLoading`, `error: String?`, `data: T?` cùng lúc) — tránh trạng thái không hợp lệ (vừa loading vừa có data cũ vừa có error).

```kotlin
sealed interface Resource<out T> {
    data object Loading : Resource<Nothing>
    data class Success<T>(val data: T) : Resource<T>
    data class Error(val message: String) : Resource<Nothing>
}
```

## Data class & immutability

Ưu tiên `val` hơn `var`, `data class` cho model — tự sinh `equals`/`hashCode`/`copy()`, tránh mutation ngoài ý muốn khi truyền object qua nhiều layer.

## Extension function

Dùng để thêm hành vi cho type có sẵn (Android SDK class) thay vì tạo utility class `*Utils` với static method — nhưng không lạm dụng extension cho logic nghiệp vụ phức tạp nên nằm ở đâu đó có tên rõ ràng hơn (Repository/UseCase).

## Java interop

- `@JvmStatic` cho hàm/property trong `companion object` cần gọi từ Java như static method — thiếu annotation này, Java phải gọi qua `Companion.xxx()`.
- Tránh default-argument trong hàm Kotlin sẽ bị gọi từ Java — Java không thấy overload tự sinh, trừ khi thêm `@JvmOverloads`.
- Dùng `@Nullable`/`@NonNull` (androidx.annotation) trên API Java để Kotlin hiểu đúng nullability khi gọi ngược (thiếu annotation, Kotlin coi type là platform type `String!`, mất type-safety null).
- Không migrate file Java sang Kotlin chỉ vì tiện, trừ khi được yêu cầu tường minh (chi tiết ở SKILL.md) — mục này chỉ nói khía cạnh interop kỹ thuật.
