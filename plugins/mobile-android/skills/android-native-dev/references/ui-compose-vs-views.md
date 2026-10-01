# Compose vs View/XML — when to choose which

## Decision table

| Situation | Choose |
| --- | --- |
| Brand-new project, no UI code yet | Compose |
| 100% XML legacy project, adding 1 new standalone screen | Compose via `ComposeView` interop (no need to migrate the whole app) |
| Legacy project with complex Activity/Fragment, only a small edit needed | Keep XML/View — do not switch toolkits midway just for convenience |
| Screen already in Compose, needs a small View-only interactive part (e.g. AdMob SDK view) | `AndroidView` interop in the reverse direction, do not go back to full XML |

General principle: 1 screen uses only 1 main toolkit. Switching toolkits is an architectural decision, not a convenience.

## Detect what the project uses

```
grep -rl "@Composable\|setContent(" app/src/main/java   # has Compose
grep -rl "findViewById\|ViewBinding\|DataBinding" app/src/main/java
find app/src/main/res/layout -name "*.xml"               # uses traditional View
```

Both signs present → the project is migrating gradually (hybrid); check what the specific screen you are editing uses before deciding.

## Add a Compose screen to a legacy XML app

Place a `ComposeView` in the XML layout of the old Fragment/Activity, call `setContent` in `onViewCreated`/`onCreate`:

```xml
<androidx.compose.ui.platform.ComposeView
    android:id="@+id/composeView"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

```kotlin
override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    binding.composeView.apply {
        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
        setContent {
            BookingScreen(onBook = { viewModel.book() })
        }
    }
}
```

This is one-way interop (Compose embedded in View) — no need to rewrite existing navigation or architecture. Details on writing Composables: [jetpack-compose.md](jetpack-compose.md).

## Specific pitfalls

- Forgetting to set a suitable `ViewCompositionStrategy` when embedding `ComposeView` in a Fragment (the default `DisposeOnDetachedFromWindowOrReleasedFromPool` does not dispose at the right time in nested Fragment/ViewPager) → Composable leaks, not disposed when the Fragment is destroyed.
- Calling `findViewById` after the View is destroyed (e.g. in an async callback running after `onDestroyView`) → `NullPointerException` or crash.
- Mixing state management across both XML View and Compose for the same screen (e.g. loading state set both via `ProgressBar.visibility` and via `mutableStateOf`) → hard to debug; choose 1 toolkit per screen.
