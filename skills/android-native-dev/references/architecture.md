# Kiến trúc Android — chi tiết

## Layer

```
UI (Compose/View) → ViewModel → Repository → DataSource (network/DB/cache)
```

- **UI**: chỉ đọc state từ ViewModel (`collectAsStateWithLifecycle()` trong Compose), gửi event/action xuống. Không chứa business logic.
- **ViewModel**: expose `StateFlow<UiState>` (hoặc `LiveData` nếu dự án cũ dùng View), gọi Repository qua coroutine trong `viewModelScope`. Không giữ `Context`, `View`, hay reference vòng đời UI.
- **Repository**: 1 nguồn sự thật cho 1 loại dữ liệu, quyết định lấy từ cache hay network, không biết gì về UI.
- **DataSource**: Retrofit/Ktor cho network, Room cho local DB.

## Ví dụ ViewModel

```kotlin
sealed interface BookingUiState {
    data object Loading : BookingUiState
    data class Success(val bookings: List<Booking>) : BookingUiState
    data class Error(val message: String) : BookingUiState
}

class BookingViewModel(private val repo: BookingRepository) : ViewModel() {
    private val _state = MutableStateFlow<BookingUiState>(BookingUiState.Loading)
    val state: StateFlow<BookingUiState> = _state.asStateFlow()

    fun load() = viewModelScope.launch {
        _state.value = BookingUiState.Loading
        _state.value = runCatching { repo.getBookings() }
            .fold(BookingUiState::Success) { e -> BookingUiState.Error(e.message ?: "Unknown error") }
    }
}
```

## Dependency Injection

- **Hilt**: annotation-based, tích hợp sẵn với `ViewModel`/`WorkManager`/Compose Navigation. Chọn khi dự án dùng nhiều Jetpack component chuẩn Google.
- **Koin**: DSL Kotlin thuần, không cần annotation processing (build nhanh hơn), phù hợp module nhỏ/KMP.

Dự án đã chọn 1 trong 2 thì theo đúng cái đó — không tự thêm framework DI thứ hai.

## Navigation

Compose Navigation (`NavHost`/`NavController`) cho app Compose-first. Định nghĩa route bằng sealed class/type-safe args thay vì string nối tay để tránh lỗi runtime khi đổi tên màn hình.
