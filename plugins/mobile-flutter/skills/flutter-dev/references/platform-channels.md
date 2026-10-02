# Platform Channels — details

## When needed

Only write a `MethodChannel`/`EventChannel` when:
1. No pub.dev package covers the needed native API (check pub.dev before writing your own — BLE vibration, unusual sensors, third-party SDKs that are native-only).
2. An existing package lacks exactly the needed API (for example missing a new native callback) — consider forking/contributing to the package before writing a parallel channel of your own.

## MethodChannel — call native, receive a one-time result

```dart
static const _channel = MethodChannel('com.example.app/battery');

Future<int> getBatteryLevel() async {
  try {
    return await _channel.invokeMethod('getBatteryLevel');
  } on PlatformException catch (e) {
    throw Exception('Failed to get battery level: ${e.message}');
  }
}
```

Native side (Android Kotlin):
```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.app/battery")
    .setMethodCallHandler { call, result ->
        if (call.method == "getBatteryLevel") {
            result.success(getBatteryLevel())
        } else {
            result.notImplemented()
        }
    }
```

## EventChannel — continuous stream (sensor, location)

Use when native must push many values over time (not a one-time request-response). The Dart side listens via a `Stream`; the native side implements `StreamHandler` with `onListen`/`onCancel`.

## Principles

- Name channels by the convention `<package_id>/<feature>` to avoid channel collisions between packages.
- Always wrap `invokeMethod` in try/catch catching `PlatformException` — native may throw exceptions that Dart cannot control.
