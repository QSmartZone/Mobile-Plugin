# Platform capabilities — permission, Keychain, background, push, deep link

## Runtime permission

Every permission needs `NSXxxUsageDescription` declared in `Info.plist` — without this key the app crashes as soon as the corresponding API is called (not denied, but crashes).

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to scan payment QR codes</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is needed to connect to the payment POS device</string>
```

Request at the moment the user performs the action needing that permission (ask for Camera when they tap the scan-QR button), not in bulk at app launch — acceptance rate is higher when the user clearly understands the reason at that moment. Real example: an app with a payment device (Bluetooth) and code scanning (Camera) declares only the 2 permissions it needs, with no extras (Location, Contacts...) if the feature doesn't need them yet.

### Handling denied / permanently denied

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
        completion(false) // denied earlier — do not call requestAccess again, the system shows no dialog anymore
    @unknown default:
        completion(false)
    }
}
```

iOS does not distinguish "first denial" from "permanent denial" like Android (no rationale flow) — `requestAccess` shows the dialog exactly once in the app's lifetime. From the 2nd time on, if the status is `.denied`, direct the user to Settings; calling `requestAccess` again does nothing (completion returns `false` immediately, no dialog):

```swift
if let url = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(url)
}
```

## Keychain for secure storage

Tokens, passwords, API secrets, refresh tokens are **always** stored in Keychain — not `UserDefaults` (plaintext, readable via backup/jailbreak).

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
        SecItemDelete(query as CFDictionary) // delete the old entry before writing, avoids errSecDuplicateItem
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

Use Keychain Services directly (no extra dependency) when the need is only simple save/read/delete as above — consider a wrapper library (KeychainAccess...) only when you need multiple access groups/complex iCloud sync.

Real example: a legacy codebase using completion-handlers throughout, with a service storing the token in `UserDefaults` (0 places use Keychain) — this is technical debt to migrate gradually when touched, not a pattern to keep copying for new code.

## Background task

- **`BGTaskScheduler`** (BackgroundTasks framework): deferrable work where the system decides when to run (periodic data sync) — requires declaring `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
- **`beginBackgroundTask(expirationHandler:)`**: short work that must finish as the app enters background (finishing a pending upload request) — time-limited (~30s), must call `endBackgroundTask` when done, do not let the system kill it midway.

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

Do not use it for indefinite background work (music, continuous location tracking) — that case needs its own capability (`UIBackgroundModes` = `audio`/`location`) declared in Info.plist, not `beginBackgroundTask`.

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
    // send this token to the backend
}
```

Request push permission at a moment of clear value for the user (after they enable a feature that needs notifications), not right on first app launch.

## Deep link / Universal Link

- **Custom URL scheme** (`myapp://...`): declare `CFBundleURLSchemes` in Info.plist — other apps can register the same scheme, the source cannot be verified.
- **Universal Link** (`https://domain.com/...`): needs an `apple-app-site-association` file on the server + the Associated Domains capability — safer because the domain is verifiable, so prefer Universal Link for links shared externally (share, email, SMS). Use custom schemes only for internal deep links between apps you control.

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

By default iOS blocks all plain HTTP connections (no TLS). Do not disable ATS globally (`NSAllowsArbitraryLoads: true`) unless truly required (calling an internal dev API without HTTPS yet) — if an exception is needed, limit it to exactly that domain:

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

## Specific pitfalls

- Missing `NSXxxUsageDescription` in Info.plist for a permission in use → the app crashes as soon as the API is called (not denied), hard to identify the cause without reading the crash log carefully.
- Calling `requestAccess`/equivalent again after the user has denied → nothing happens (no dialog); the code thinks it is waiting for the user's answer but the flow is dead — check `authorizationStatus` first and direct to Settings.
- Storing token/password in `UserDefaults` instead of Keychain → readable via backup files or a jailbroken device.
- Setting `NSAllowsArbitraryLoads: true` globally instead of limiting it to the exact domain needing an exception → disables TLS protection for all of the app's network calls, including the production API.
- Using a custom URL scheme for public share links (shared outside the app) instead of Universal Link → another app registering the same scheme can "hijack" the link, opening the wrong app.
- Forgetting to call `endBackgroundTask` after the work is done (or in the error branch) → the system treats the app as uncooperative and lowers its priority for granting background time later.
