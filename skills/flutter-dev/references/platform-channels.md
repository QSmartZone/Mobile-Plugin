# Platform Channels — chi tiết

## Khi nào cần

Chỉ viết `MethodChannel`/`EventChannel` khi:
1. Không có package trên pub.dev cover được API native cần dùng (kiểm tra pub.dev trước khi tự viết — rung lắc BLE, sensor lạ, SDK bên thứ 3 chỉ có native).
2. Package có sẵn nhưng thiếu đúng API cần (ví dụ thiếu 1 callback native mới) — cân nhắc fork/contribute package trước khi viết riêng channel song song.

## MethodChannel — gọi native, nhận kết quả 1 lần

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

## EventChannel — stream liên tục (sensor, location)

Dùng khi native cần đẩy nhiều giá trị theo thời gian (không phải request-response 1 lần). Dart side lắng nghe qua `Stream`, native side implement `StreamHandler` với `onListen`/`onCancel`.

## Nguyên tắc

- Đặt tên channel theo convention `<package_id>/<feature>` để tránh đụng channel giữa các package.
- Luôn wrap `invokeMethod` trong try/catch bắt `PlatformException` — native có thể throw exception không kiểm soát được từ phía Dart.
- Test logic Dart-side bằng cách mock `MethodChannel` qua `TestDefaultBinaryMessengerBinding` — không cần chạy trên thiết bị thật để test phần xử lý kết quả.
