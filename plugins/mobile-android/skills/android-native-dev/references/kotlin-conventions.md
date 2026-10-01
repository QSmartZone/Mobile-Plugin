# Kotlin conventions — details

## Coroutines & Flow

- `viewModelScope`/`lifecycleScope` for lifecycle-bound coroutines — automatically cancelled when the component is destroyed, avoiding leaks.
- `Flow` for data streams (DB observe, WebSocket); a simple `suspend fun` for one-shot requests.
- Switch threads with `withContext(Dispatchers.IO)` around blocking calls (DB, file, legacy non-suspend-aware network), do not manually switch to `Dispatchers.Main` in a ViewModel — Compose/`collectAsState` switches to the main thread automatically when collecting.

```kotlin
suspend fun getBookings(): List<Booking> = withContext(Dispatchers.IO) {
    api.fetchBookings()
}
```

## Null-safety

- Avoid `!!` — if you are sure it is non-null, use a non-null type from the start (declare the right type); if not sure, handle the null branch explicitly (`?.let`, `?:`, early return).
- `lateinit var` only for properties guaranteed to be initialized before use (e.g. in `onCreate`), do not abuse it to dodge nullable.

## Sealed class for state

Model UI/domain state with a sealed class/interface instead of several loose `Boolean`/`String?` (`isLoading`, `error: String?`, `data: T?` at once) — avoids invalid states (loading while also having stale data and an error).

```kotlin
sealed interface Resource<out T> {
    data object Loading : Resource<Nothing>
    data class Success<T>(val data: T) : Resource<T>
    data class Error(val message: String) : Resource<Nothing>
}
```

## Data class & immutability

Prefer `val` over `var`, `data class` for models — auto-generates `equals`/`hashCode`/`copy()`, avoiding unintended mutation when passing objects across layers.

## Extension functions

Use to add behavior to existing types (Android SDK classes) instead of creating a `*Utils` class with static methods — but do not abuse extensions for complex business logic that belongs somewhere with a clearer name (Repository/UseCase).

## Java interop

- `@JvmStatic` for functions/properties in a `companion object` that must be called from Java as static methods — without this annotation, Java must call through `Companion.xxx()`.
- Avoid default arguments in Kotlin functions that will be called from Java — Java does not see the auto-generated overloads unless you add `@JvmOverloads`.
- Use `@Nullable`/`@NonNull` (androidx.annotation) on Java APIs so Kotlin understands nullability correctly when calling back (without the annotations, Kotlin treats the type as a platform type `String!`, losing null type-safety).
- Do not migrate a Java file to Kotlin just for convenience, unless explicitly requested (details in SKILL.md) — this section only covers the technical interop aspect.
