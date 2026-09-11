# Kiến trúc Android — chi tiết

## Layer

```
UI (Compose/View) → ViewModel → Repository → DataSource (network/DB/cache)
```

- **UI**: chỉ đọc state từ ViewModel (`collectAsStateWithLifecycle()` trong Compose), gửi event/action xuống. Không chứa business logic.
- **ViewModel**: expose `StateFlow<UiState>` (hoặc `LiveData` nếu dự án cũ dùng View), gọi Repository qua coroutine trong `viewModelScope`. Không giữ `Context`, `View`, hay reference vòng đời UI.
- **Repository**: 1 nguồn sự thật cho 1 loại dữ liệu, quyết định lấy từ cache hay network, không biết gì về UI.

  **Khi nào KHÔNG cần Repository**: app nhỏ/thin-MVVM đang chạy ổn, ViewModel gọi thẳng service (Retrofit) qua 1 helper chung (vd `BaseViewModel.launchApi`) — đừng tự thêm layer Repository chỉ vì "đúng chuẩn kiến trúc". Chỉ thêm khi có nhu cầu cụ thể: nhiều nguồn dữ liệu cho cùng loại data, cần cache, hoặc test cần fake nguồn dữ liệu độc lập với network.
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
- **Dagger 2 classic**: phải tự khai `@Component`/`@Module` và tự nối scope thủ công; Hilt sinh sẵn component theo lifecycle Android (`SingletonComponent`/`ActivityComponent`...) nên đỡ boilerplate hơn. Inject ViewModel qua multibinding: `@IntoMap` + `@ViewModelKey` (hoặc `AssistedInject`) đăng ký từng ViewModel vào 1 `Map<Class<out ViewModel>, Provider<ViewModel>>`, rồi 1 `ViewModelFactory` chung dùng map đó để tạo ViewModel qua Dagger graph. Chọn khi: dự án đã dùng Dagger 2 từ trước, muốn kiểm soát graph thủ công, chưa muốn migrate sang Hilt.

Dự án đã chọn 1 trong các cách trên thì theo đúng cái đó — không tự thêm framework DI thứ hai.

## Navigation

Chi tiết lựa chọn Compose Navigation / Navigation Component XML / FragmentTransaction thủ công: [navigation.md](navigation.md).
