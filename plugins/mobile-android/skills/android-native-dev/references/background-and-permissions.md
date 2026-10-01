# Background work & runtime permissions — details

## WorkManager

Deferrable work that must run even if the app is killed/the device reboots (periodic data sync, file upload). Use `Constraints` (network, battery) + `WorkRequest`.

```kotlin
val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.CONNECTED)
    .build()

val request = OneTimeWorkRequestBuilder<UploadWorker>()
    .setConstraints(constraints)
    .build()

WorkManager.getInstance(context).enqueue(request)
```

## Foreground Service

Work that must run immediately and that the user needs to see running (music, location tracking, calls) — a visible notification is required from Android 8+ (API 26). From Android 14 (API 34), you must declare `android:foregroundServiceType` in the Manifest **and** request the matching `FOREGROUND_SERVICE_<TYPE>` permission (e.g. `FOREGROUND_SERVICE_LOCATION`) — missing either one crashes with `MissingForegroundServiceTypeException`/`SecurityException` when starting the service.

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<service
    android:name=".LocationTrackingService"
    android:foregroundServiceType="location" />
```

## BroadcastReceiver

Reacts to system events (boot completed, network change, battery low). From Android 8 (API 26), most implicit broadcasts are not received if registered statically in the Manifest — register dynamically (`registerReceiver` in code) or use WorkManager/JobScheduler instead.

Monitor the network with `ConnectivityManager.registerDefaultNetworkCallback` instead of a broadcast — `CONNECTIVITY_ACTION` has been deprecated since API 28 and does not reflect whether the network is actually usable:

```kotlin
val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
connectivityManager.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) { /* network usable */ }
    override fun onLost(network: Network) { /* network lost */ }
})
```

For other system broadcasts (non-network), still register dynamically via `registerReceiver`. From API 34, dynamically registering a receiver for non-system broadcasts requires the `RECEIVER_NOT_EXPORTED` flag (or `RECEIVER_EXPORTED` if you really need to receive from other apps), otherwise it crashes with `SecurityException`.

## Runtime permission flow

Use `registerForActivityResult(ActivityResultContracts.RequestPermission())` instead of the old `onRequestPermissionsResult`. Call `registerForActivityResult` before the Activity/Fragment reaches the `STARTED` state (declare at field init or in `onCreate`, do not call later in a click handler) — calling late crashes with `IllegalStateException: LifecycleOwner ... is attempting to register while current state is ...`.

```kotlin
val requestPermission = registerForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted ->
    if (granted) startTracking() else showRationaleOrSettings()
}
```

- Check `shouldShowRequestPermissionRationale()` to show an explanation before re-requesting a permission denied the first time.
- Permanently denied permission (denied + "Don't ask again") → direct the user to Settings (`Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)`), do not re-request pointlessly (the system blocks it and the dialog no longer appears).
- Android 13 (API 33): showing notifications requires the runtime permission `POST_NOTIFICATIONS` (previously only a Manifest declaration) — without this step notifications (including a foreground Service's) do not show, and it does not crash so it is easy to miss.

## Background execution limits on Android 8+ (API 26)

Apps in the background have plain Services limited after a few minutes, and implicit broadcasts are restricted — this is why WorkManager/foreground Service exist instead of a plain Service running in the background indefinitely.

## Specific pitfalls

- Using a plain Service (not foreground) for long-running background work on Android 8+ → killed by the system after a few minutes, work does not complete.
- Requesting permission as soon as the app opens (no context for why it is needed) instead of when the user performs the action that needs it → high denial rate, user does not understand why.
- Registering a static `BroadcastReceiver` in the Manifest for implicit broadcasts on Android 8+ → events are not received; the code looks correct but the receiver is never called.
- Missing `foregroundServiceType` in the Manifest for a Foreground Service when targeting Android 14 (API 34) → `MissingForegroundServiceTypeException` on service start, immediate crash.
- Repeatedly re-requesting a permission after permanent denial instead of checking the state and directing to Settings → the dialog does not show; the code thinks it is waiting for the user's answer but the permission flow is actually dead.
