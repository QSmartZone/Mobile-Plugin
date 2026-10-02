# Android architecture — details

## Layers

```
UI (Compose/View) → ViewModel → Repository → DataSource (network/DB/cache)
```

- **UI**: only reads state from the ViewModel (`collectAsStateWithLifecycle()` in Compose), sends events/actions down. Contains no business logic.
- **ViewModel**: exposes `StateFlow<UiState>` (or `LiveData` if the existing project uses View), calls the Repository via coroutines in `viewModelScope`. Does not hold `Context`, `View`, or UI lifecycle references.
- **Repository**: single source of truth for one kind of data, decides whether to fetch from cache or network, knows nothing about the UI.

  **When a Repository is NOT needed**: a small/thin-MVVM app that works fine, where the ViewModel calls the service (Retrofit) directly via a shared helper (e.g. `BaseViewModel.launchApi`) — do not add a Repository layer just because it is "the proper architecture". Add one only for a concrete need: multiple data sources for the same kind of data, or caching needed.
- **DataSource**: Retrofit/Ktor for network, Room for local DB.

## ViewModel example

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

- **Hilt**: annotation-based, built-in integration with `ViewModel`/`WorkManager`/Compose Navigation. Choose when the project uses many standard Google Jetpack components.
- **Koin**: pure Kotlin DSL, no annotation processing (faster builds), suits small modules/KMP.
- **Classic Dagger 2**: you declare `@Component`/`@Module` and wire scopes manually; Hilt generates components per Android lifecycle (`SingletonComponent`/`ActivityComponent`...) so it has less boilerplate. Inject ViewModels via multibinding: `@IntoMap` + `@ViewModelKey` (or `AssistedInject`) registers each ViewModel into a `Map<Class<out ViewModel>, Provider<ViewModel>>`, then one shared `ViewModelFactory` uses that map to create ViewModels through the Dagger graph. Choose when: the project already used Dagger 2, wants manual control of the graph, and is not ready to migrate to Hilt.

If the project has chosen one of the above, follow exactly that one — do not add a second DI framework.

## Navigation

Details on choosing Compose Navigation / Navigation Component XML / manual FragmentTransaction: [navigation.md](navigation.md).
