# Lifecycle and state — Activity/Fragment

2 main pitfalls to remember: null the binding in `onDestroyView` (Fragment), and process death differs from config change (ViewModel is lost on process death, not on config change).

## Fragment lifecycle — View lifecycle differs from Fragment lifecycle

A Fragment adds `onCreateView` → `onViewCreated` → ... → `onDestroyView` → `onDestroy`.

Key difference: **the Fragment instance can outlive its View** — e.g. when the Fragment is in the back stack (replaced but not yet popped), the View is destroyed (`onDestroyView`) but the Fragment object still exists, only truly dying at `onDestroy`.

Direct consequence for ViewBinding: null the binding in `onDestroyView`, do not hold it until `onDestroy`.

```kotlin
class ProfileFragment : Fragment() {
    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null // View is dead, the Fragment may still live in the back stack
    }
}
```

## Config change (rotation, language change, theme change...)

By default Activity/Fragment are **destroyed and recreated** when config changes. You can declare `android:configChanges` in the Manifest to handle it yourself instead of recreating, but this is discouraged — you lose the standard lifecycle callbacks (`onSaveInstanceState`/`onCreate` do not run again), and it is easy to introduce bugs when adding new config-aware resources and forgetting to update the self-handling code.

The right way: keep state that must survive config change in a `ViewModel`.

```kotlin
class ProfileViewModel : ViewModel() {
    private val _state = MutableStateFlow(ProfileUiState())
    val state: StateFlow<ProfileUiState> = _state.asStateFlow()
    // Activity rotates → Activity/Fragment is recreated,
    // but this ViewModel is still the same instance (scoped to Activity/NavBackStackEntry)
}
```

`ViewModel` survives config change and only dies when the Activity/Fragment truly finishes (the user backs out of the screen, not because of rotation). Do not use static fields or singletons to avoid losing state on recreate — holding `Context`/UI state in a static field leaks (statics live with the process, not the Activity lifecycle) and it is unclear which lifecycle the state belongs to.

## Process death — differs from config change

When the app is in the background, the system may **kill the whole process** to free RAM (not just recreate the Activity). Unlike config change: `ViewModel` is lost too because the whole process disappears, not just the Activity.

Restore with `SavedStateHandle` — inject it into the ViewModel; it automatically saves/restores small key-value pairs across process death:

```kotlin
class ProfileViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {
    var userId: String?
        get() = savedStateHandle["userId"]
        set(value) { savedStateHandle["userId"] = value }
}
```

Save only the minimal state needed to restore to the right place (the id being viewed, half-typed text, selected tab) — do not put whole lists/large data into `SavedStateHandle` (it has the same size limit as Bundle, and lists should be re-fetched from the source when the ViewModel is recreated).

### View-based Activity/Fragment without a ViewModel

`SavedStateHandle` needs a ViewModel. For pure View Activity/Fragment (no ViewModel), use `onSaveInstanceState`/`onRestoreInstanceState` to save small, temporary state (scroll position, half-typed text, selected tab) across process death and config change:

```kotlin
override fun onSaveInstanceState(outState: Bundle) {
    super.onSaveInstanceState(outState)
    outState.putString("query", currentQuery)
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    currentQuery = savedInstanceState?.getString("query") ?: ""
}
```

Same size limit as Bundle/`SavedStateHandle` — small state only, not the primary store for data.

## Specific pitfalls

- Holding a `Context`/`Activity` reference in a singleton or static field → leaks the entire Activity (View tree, resources) when the Activity is destroyed but the static field keeps the reference alive with the process.
- Registering a listener/callback (`LocationListener`, `BroadcastReceiver`, `sensorManager.registerListener`) in `onCreate`/`onStart` but forgetting to unregister in the matching `onDestroy`/`onStop` → leak, or the callback calls into a dead Activity and crashes.
- Not nulling ViewBinding in a Fragment's `onDestroyView` → leaks the entire View hierarchy when the Fragment lives on in the back stack but its View has been destroyed.
- Testing the app only on an emulator/high-RAM device without enabling "Don't keep activities" (Developer Options) → process-death bugs go undetected, only surfacing when real users on low-RAM devices lose state annoyingly.
- Declaring `android:configChanges` to avoid recreation instead of using `ViewModel` → looks like an optimization but loses standard lifecycle callbacks, and the self-handled config code is easy to forget to update when adding new config-dependent resources/layouts.
