# Android navigation — details

Pick 1 of 3 approaches based on what the project already uses; do not switch midway within the same app.

## Compose Navigation

For Compose-first apps. Use `NavHost`/`NavController`, define routes with a sealed class or type-safe args (`navigation-compose` type-safe from Nav 2.8+) instead of hand-concatenated strings — avoids runtime errors when renaming a screen and forgetting to fix every string-concatenation spot.

```kotlin
@Serializable
sealed interface Route {
    @Serializable data object Home : Route
    @Serializable data class Detail(val bookingId: String) : Route
}

NavHost(navController, startDestination = Route.Home) {
    composable<Route.Home> { HomeScreen(onOpen = { navController.navigate(Route.Detail(it)) }) }
    composable<Route.Detail> { backStackEntry ->
        val args = backStackEntry.toRoute<Route.Detail>()
        DetailScreen(bookingId = args.bookingId)
    }
}
```

## Navigation Component XML (Fragment-based)

For traditional Fragment-based apps: `nav_graph.xml` + `NavHostFragment` + SafeArgs. SafeArgs generates typed classes for arguments between destinations — avoids hand-typing `Bundle` key strings.

```xml
<fragment android:id="@+id/detailFragment" android:name="...DetailFragment">
    <argument android:name="bookingId" app:argType="string" />
</fragment>
```

```kotlin
val args = DetailFragmentArgs.fromBundle(requireArguments())
findNavController().navigate(HomeFragmentDirections.actionHomeToDetail(bookingId))
```

## Manual FragmentTransaction

Use only when maintaining old code that already used this approach (`supportFragmentManager.beginTransaction()...`). Do not use for new code if the project already has Navigation Component — mixing the 2 approaches in the same activity corrupts the back stack.

## Deep link / App link

- **Navigation Component**: declare `<deepLink app:uri="myapp://booking/{id}" />` in `nav_graph.xml`.
- **Manual**: `<intent-filter>` with `<data android:scheme="..." android:host="..."/>` in the Manifest.
- **App Link** (opens the app directly, no browser chooser): add `android:autoVerify="true"` on the intent-filter + host the Digital Asset Links JSON (`.well-known/assetlinks.json`) on the server for the domain declared in `data android:host`.

## Specific pitfalls

- Mixing Navigation Component with manual `FragmentTransaction` in the same activity → wrong back stack (Back button jumps to the wrong screen or suddenly exits the app).
- Passing arguments via `Bundle` with hand-typed string keys and mistyping the key name → runtime crash `NullPointerException`/`ClassCastException`, not caught at compile time (SafeArgs or type-safe Compose args avoid this since they check at compile time).
- Deep link missing `android:autoVerify="true"` or with a missing/wrong Digital Asset Links JSON on the server → Android does not open the app automatically, shows a browser chooser dialog instead of going straight to the app.
- Defining Compose routes with hand-concatenated strings (`"detail/$id"`) instead of a sealed class/type-safe args → renaming/reordering parameters in one place and forgetting the parsing spot, the error only surfaces when running that screen.
- Calling `navigate()` repeatedly due to double-tap (no debounce) → pushes duplicate copies of the same destination onto the back stack.
