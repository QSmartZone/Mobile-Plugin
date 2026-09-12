# Background work & runtime permissions — chi tiết

## WorkManager

Việc có thể trì hoãn, cần đảm bảo chạy dù app bị kill/reboot máy (đồng bộ dữ liệu định kỳ, upload file). Dùng `Constraints` (network, battery) + `WorkRequest`.

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

Việc phải chạy ngay, user cần thấy đang chạy (nhạc, tracking vị trí, cuộc gọi) — bắt buộc notification hiển thị từ Android 8+ (API 26). Từ Android 14 (API 34), bắt buộc khai `android:foregroundServiceType` trong Manifest **và** xin permission `FOREGROUND_SERVICE_<TYPE>` tương ứng (ví dụ `FOREGROUND_SERVICE_LOCATION`) — thiếu 1 trong 2 là crash `MissingForegroundServiceTypeException`/`SecurityException` khi start service.

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<service
    android:name=".LocationTrackingService"
    android:foregroundServiceType="location" />
```

## BroadcastReceiver

Phản ứng event hệ thống (boot completed, network change, battery low). Từ Android 8 (API 26), hầu hết implicit broadcast không nhận được nếu đăng ký tĩnh trong Manifest — phải đăng ký động (`registerReceiver` trong code) hoặc dùng WorkManager/JobScheduler thay thế.

Theo dõi network nên dùng `ConnectivityManager.registerDefaultNetworkCallback` thay vì broadcast — `CONNECTIVITY_ACTION` đã deprecated từ API 28 và không phản ánh network thực sự usable:

```kotlin
val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
connectivityManager.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) { /* network usable */ }
    override fun onLost(network: Network) { /* network mất */ }
})
```

Với broadcast hệ thống khác (không phải network), vẫn đăng ký động qua `registerReceiver`. Từ API 34, đăng ký động receiver không thuộc hệ thống bắt buộc kèm cờ `RECEIVER_NOT_EXPORTED` (hoặc `RECEIVER_EXPORTED` nếu thật sự cần nhận từ app khác), nếu không sẽ crash `SecurityException`.

## Runtime permission flow

Dùng `registerForActivityResult(ActivityResultContracts.RequestPermission())` thay vì `onRequestPermissionsResult` cũ. Phải gọi `registerForActivityResult` trước khi Activity/Fragment qua trạng thái `STARTED` (khai báo lúc field init hoặc trong `onCreate`, không gọi trễ hơn trong click handler) — gọi muộn sẽ crash `IllegalStateException: LifecycleOwner ... is attempting to register while current state is ...`.

```kotlin
val requestPermission = registerForActivityResult(
    ActivityResultContracts.RequestPermission()
) { granted ->
    if (granted) startTracking() else showRationaleOrSettings()
}
```

- Check `shouldShowRequestPermissionRationale()` để hiển thị giải thích trước khi xin lại quyền bị từ chối lần đầu.
- Permission bị từ chối vĩnh viễn (denied + "Don't ask again") → hướng user sang Settings (`Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)`), không xin lại vô ích (hệ thống tự chặn, dialog không hiện nữa).
- Android 13 (API 33): hiển thị notification cần xin runtime permission `POST_NOTIFICATIONS` (trước đó chỉ cần khai Manifest) — thiếu bước này thì notification (kể cả của foreground Service) không hiện, không crash nên dễ bỏ sót.

## Giới hạn background execution Android 8+ (API 26)

App ở background bị giới hạn chạy Service thường sau vài phút, implicit broadcast bị hạn chế — đây là lý do WorkManager/foreground Service tồn tại thay vì Service thường chạy ngầm vô thời hạn.

## Bẫy cụ thể

- Dùng Service thường (không phải foreground) để làm việc dài hơi ở background trên Android 8+ → bị hệ thống kill sau vài phút, việc không hoàn thành.
- Xin permission ngay lúc app mở (chưa có context tại sao cần) thay vì xin đúng lúc user thao tác cần quyền đó → tỷ lệ từ chối cao, user không hiểu lý do.
- Đăng ký `BroadcastReceiver` tĩnh trong Manifest cho implicit broadcast trên Android 8+ → không nhận được event, tưởng code chạy đúng nhưng thực tế receiver không bao giờ được gọi.
- Thiếu `foregroundServiceType` trong Manifest khi target Android 14 (API 34) cho Foreground Service → `MissingForegroundServiceTypeException` khi start service, crash ngay.
- Xin lại permission liên tục sau khi bị từ chối vĩnh viễn thay vì check trạng thái và hướng sang Settings → dialog không hiện, code tưởng đang chờ user trả lời nhưng thực chất luồng permission đã chết.
