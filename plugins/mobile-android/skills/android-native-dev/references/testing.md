# Android testing — details

## JUnit + coroutine test for ViewModel/Repository/UseCase

```kotlin
@Test
fun `load success updates state`() = runTest {
    val repo = FakeBookingRepository(bookings = listOf(sampleBooking))
    val vm = BookingViewModel(repo)
    vm.load()
    assertEquals(BookingUiState.Success(listOf(sampleBooking)), vm.state.value)
}

@Test
fun `load failure emits error state`() = runTest {
    val repo = FakeBookingRepository(shouldFail = true)
    val vm = BookingViewModel(repo)
    vm.load()
    assertTrue(vm.state.value is BookingUiState.Error)
}
```

Use `TestDispatcher`/`runTest` (kotlinx-coroutines-test) instead of `Thread.sleep` to wait for coroutines — fast, deterministic, not flaky with CI machine speed.

## Fake/Mock Repository

Prefer a hand-written fake class (re-implement the Repository interface, return fixed data) over a mock framework for simple tests — easy to read, no mock DSL to learn. Use Mockito/MockK when you need to verify call counts or mock many complex dependencies.

## Compose UI test

```kotlin
@get:Rule val composeRule = createComposeRule()

@Test
fun bookingList_showsItems() {
    composeRule.setContent { BookingListScreen(state = sampleState) }
    composeRule.onNodeWithText("Booking #123").assertIsDisplayed()
}
```

## Espresso (legacy View)

Use only when testing screens that still use XML layout/View — do not write new Espresso tests for screens already migrated to Compose.

## Test level by risk, not a fixed count

Logic with branches/loops/parsing/calculation → always needs a test. Purely presentational UI (static Composable preview, layout without logic) → do not force a test.

If the project has almost no tests (no existing convention to follow) → do not invent a coverage % or elaborate patterns; bootstrap from the basic patterns already in this file (JUnit + coroutine test dispatcher for ViewModel).

## Principles

Bug fix with a faulty branch/loop → write a test reproducing the bug (fails before the fix). New ViewModel → at least 2 test cases: success + error. Do not test getters/setters or static Compose previews without logic.

## Running tests correctly

- Run exactly the 1 class/method being edited with `--tests "<Class>"` or `--tests "<Class>.<method>"`, not the whole module for a small change.
- Read the first failing line in the output first — the first failing assertion is usually the root cause, later failures may just be consequences.
- `connectedAndroidTest` (Espresso/Compose UI tests on a device) only runs when the task touches UI — it is slow, do not run it by default for pure logic changes.
- Do not run the full test suite before the relevant unit tests pass — fail fast, fix, then run wider.
- Gradle hangs while resolving dependencies (slow/no network) → add `--offline` if the dependencies are already cached.
