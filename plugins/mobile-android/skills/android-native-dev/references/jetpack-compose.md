# Jetpack Compose — details

Comparison of when to choose Compose vs XML/View: [ui-compose-vs-views.md](ui-compose-vs-views.md).

## State hoisting

Composables should be stateless — receive state + callbacks from the caller, do not hold business state internally in plain variables. This makes Composables previewable, independently testable, and reusable in many places.

```kotlin
@Composable
fun Counter(count: Int, onIncrement: () -> Unit) {
    Button(onClick = onIncrement) { Text("Count: $count") }
}
```

The caller (usually the parent screen or ViewModel) holds `count`; the child Composable only displays it and emits events upward.

## remember vs rememberSaveable vs ViewModel

- `remember`: lives within the composition, lost on rotate (config change) — use for pure UI state that need not be kept (e.g. temporary animation state).
- `rememberSaveable`: survives config change, use for simple, serializable UI state (e.g. the text field being typed in, the selected tab).
- `ViewModel`: state that must survive the Composable being fully disposed (navigate away then back), or business state that must be shared/tested independently of the UI.

## Side-effect APIs

- `LaunchedEffect(key)`: runs a coroutine when `key` changes (or on first entering the composition) — use when you need to call an API as the screen opens.
- `DisposableEffect(key)`: needs cleanup when leaving the composition — register/unregister listeners.
- `SideEffect`: sync Compose state out to non-Compose systems (analytics, logging) after every successful recomposition.

```kotlin
@Composable
fun BookingScreen(viewModel: BookingViewModel) {
    LaunchedEffect(Unit) {
        viewModel.load()
    }
    // ...
}
```

Do not call suspend functions or side effects directly in the Composable body — it re-runs on every recomposition with no lifecycle control.

## Performance

- Prefer data classes/immutable types for state passed into Composables (List → `ImmutableList` from `kotlinx.collections.immutable` if available, or ensure the state is stable) so the Compose compiler can skip unnecessary recompositions.
- Use `key(item.id)` in `LazyColumn`/`LazyRow` when the list can reorder/add/remove, to prevent Compose matching the wrong item.
- Avoid creating a new lambda on every recomposition passed to a heavy child Composable — if measurement shows a problem, wrap it in `remember { }` or use a stable method reference.

```kotlin
LazyColumn {
    items(bookings, key = { it.id }) { booking ->
        BookingRow(booking)
    }
}
```

## ViewModel integration

Use `collectAsStateWithLifecycle()` (from `androidx.lifecycle:lifecycle-runtime-compose`) instead of bare `collectAsState()`, so Flow collection stops automatically when the screen goes to the background — avoids redundant UI updates/leaks.

```kotlin
val state by viewModel.state.collectAsStateWithLifecycle()
```

## Testing

Use `createComposeRule()`, find nodes via semantics (`onNodeWithText(...)`, `onNodeWithTag(...)` — set `Modifier.testTag(...)` when needed) instead of by XML id (which does not exist in Compose). Full examples: [testing.md](testing.md).

## Specific pitfalls

- Forgetting `key()` in `LazyColumn` → re-renders the wrong item when the list reorders.
- Putting side-effect logic (API calls, logging) directly in the Composable body instead of `LaunchedEffect` → re-runs on every recomposition, causing repeated API calls.
- State not hoisted (Composable holds internal state in a property outside `remember`) → cannot preview, cannot test independently.
- Wrong `Modifier` order changes behavior: `Modifier.padding(8.dp).clickable { }` (padding first, then clickable — smaller tap area) differs from `Modifier.clickable { }.padding(8.dp)` (clickable first, then padding — larger tap area, including the padding).
