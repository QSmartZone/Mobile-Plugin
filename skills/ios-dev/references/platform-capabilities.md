# Platform capabilities — permission, Keychain, background, push, deep link

## Runtime permission

Mọi permission cần khai `NSXxxUsageDescription` trong `Info.plist` — thiếu key này app crash ngay khi gọi API tương ứng (không phải bị từ chối, mà crash).

```xml
<key>NSCameraUsageDescription</key>
<string>Cần quyền Camera để quét mã QR thanh toán</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Cần Bluetooth để kết nối máy POS thanh toán</string>
```

Xin đúng lúc user thao tác cần quyền đó (bấm nút quét QR mới xin Camera), không xin hàng loạt lúc mở app — tỷ lệ đồng ý cao hơn khi user hiểu rõ lý do ngay tại thời điểm đó. Ví dụ thực tế: app có thiết bị thanh toán (Bluetooth) và quét mã (Camera) chỉ khai đúng 2 permission cần dùng, không xin thừa (Location, Contacts...) nếu tính năng chưa cần.

### Xử lý denied / permanently denied

```swift
import AVFoundation

func requestCameraAccess(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    case .denied, .restricted:
        completion(false) // đã từ chối trước đó — không gọi lại requestAccess, hệ thống không hiện dialog nữa
    @unknown default:
        completion(false)
    }
}
```

iOS không phân biệt "denied lần đầu" và "denied vĩnh viễn" như Android (không có rationale flow) — `requestAccess` chỉ hiện dialog đúng 1 lần trong đời app. Từ lần 2 trở đi nếu status là `.denied`, phải hướng user sang Settings, gọi lại `requestAccess` sẽ không làm gì (completion trả `false` ngay, không hiện dialog):

```swift
if let url = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(url)
}
```

## Keychain cho secure storage

Token, password, API secret, refresh token **luôn** lưu Keychain — không dùng `UserDefaults` (plaintext, đọc được qua backup/jailbreak).

```swift
import Security

enum KeychainStore {
    static func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary) // xoá bản cũ trước khi ghi, tránh lỗi errSecDuplicateItem
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

Dùng trực tiếp Keychain Services (không cần thêm dependency) khi nhu cầu chỉ là save/read/delete đơn giản như trên — chỉ cân nhắc wrapper library (KeychainAccess...) khi cần nhiều access group/sync iCloud phức tạp.

Ví dụ thực tế: codebase legacy dùng hoàn toàn completion-handler, service lưu token bằng `UserDefaults` (0 chỗ dùng Keychain) — đây là nợ kỹ thuật cần migrate dần khi chạm tới, không phải pattern để copy tiếp cho code mới.

## Background task

- **`BGTaskScheduler`** (BackgroundTasks framework): việc có thể trì hoãn, hệ thống tự quyết định thời điểm chạy (đồng bộ dữ liệu định kỳ) — cần khai `BGTaskSchedulerPermittedIdentifiers` trong Info.plist.
- **`beginBackgroundTask(expirationHandler:)`**: việc ngắn cần hoàn thành khi app vừa vào background (nốt 1 request upload dở) — có giới hạn thời gian (~30s), phải gọi `endBackgroundTask` khi xong, không để hệ thống tự kill giữa chừng.

```swift
var bgTask: UIBackgroundTaskIdentifier = .invalid
bgTask = UIApplication.shared.beginBackgroundTask { 
    UIApplication.shared.endBackgroundTask(bgTask)
    bgTask = .invalid
}
uploadPendingData {
    UIApplication.shared.endBackgroundTask(bgTask)
    bgTask = .invalid
}
```

Không dùng cho việc chạy ngầm vô thời hạn (nhạc, tracking vị trí liên tục) — trường hợp đó cần capability riêng (`UIBackgroundModes` = `audio`/`location`) khai trong Info.plist, không phải `beginBackgroundTask`.

## Push notification

```swift
func registerForPush() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        guard granted else { return }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

// AppDelegate
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    // gửi token này lên backend
}
```

Xin quyền push đúng lúc có giá trị rõ ràng cho user (sau khi họ bật 1 tính năng cần thông báo), không xin ngay app vừa mở lần đầu.

## Deep link / Universal Link

- **Custom URL scheme** (`myapp://...`): khai `CFBundleURLSchemes` trong Info.plist — dễ bị app khác đăng ký trùng scheme, không xác thực được nguồn.
- **Universal Link** (`https://domain.com/...`): cần file `apple-app-site-association` trên server + capability Associated Domains — an toàn hơn vì domain xác thực được, nên ưu tiên Universal Link cho link chia sẻ ra ngoài (share, email, SMS). Chỉ dùng custom scheme cho deep link nội bộ giữa các app do mình kiểm soát.

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    handleDeepLink(url)
    return true
}

func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return false }
    handleDeepLink(url)
    return true
}
```

## App Transport Security (ATS)

Mặc định iOS chặn mọi kết nối HTTP thường (không TLS). Không tắt ATS toàn cục (`NSAllowsArbitraryLoads: true`) trừ khi thật sự bắt buộc (gọi API nội bộ dev chưa có HTTPS) — nếu cần ngoại lệ, giới hạn đúng domain đó:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>dev.internal.local</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Bẫy cụ thể

- Thiếu `NSXxxUsageDescription` trong Info.plist cho permission đang dùng → app crash ngay khi gọi API (không phải bị denied), khó nhận ra nguyên nhân nếu không đọc crash log kỹ.
- Gọi lại `requestAccess`/tương đương sau khi user đã từ chối → không có gì xảy ra (không hiện dialog), code tưởng đang chờ user trả lời nhưng luồng đã chết, phải check `authorizationStatus` trước và hướng sang Settings.
- Lưu token/password bằng `UserDefaults` thay vì Keychain → đọc được qua file backup hoặc thiết bị jailbreak.
- Set `NSAllowsArbitraryLoads: true` toàn cục thay vì giới hạn đúng domain cần ngoại lệ → tắt bảo vệ TLS cho toàn bộ network call của app, kể cả API production.
- Dùng custom URL scheme cho link chia sẻ công khai (share ra ngoài app) thay vì Universal Link → app khác đăng ký trùng scheme có thể "cướp" link, mở nhầm app.
- Quên gọi `endBackgroundTask` sau khi việc xong (hoặc trong nhánh lỗi) → hệ thống coi app không hợp tác, giảm ưu tiên cấp background time cho các lần sau.
