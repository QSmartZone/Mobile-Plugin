# Expo vs bare workflow

## Managed Expo (mặc định nên dùng)

Chọn managed workflow khi app không cần native code custom ngoài những gì Expo SDK + config plugin cộng đồng đã cover (camera, location, notification, in-app purchase, biometric... đều có package Expo chính thức hoặc config plugin). Lợi ích: build qua EAS Build không cần Xcode/Android Studio local, OTA update qua `expo-updates`, upgrade SDK version có lộ trình rõ ràng.

```json
// app.json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "plugins": [
      "expo-camera",
      ["expo-location", { "locationAlwaysAndWhenInUsePermission": "Cho phép app dùng vị trí." }]
    ]
  }
}
```

Dấu hiệu nhận biết project đang ở managed workflow: có `expo` trong `dependencies`, có `app.json`/`app.config.js`, KHÔNG có thư mục `ios/`/`android/` commit trong repo (thư mục này được generate lúc build, không sống trong source control).

## Bare workflow / Expo prebuild

Cần khi:
- Native module không có SDK Expo tương đương và không có config plugin cộng đồng.
- Cần custom native code (Swift/Kotlin) sâu mà config plugin không expose được (sửa `AppDelegate`, custom `Info.plist` key phức tạp, linking SDK native bên thứ ba yêu cầu chỉnh Podfile tay).
- Migrate app cũ React Native CLI có sẵn `ios/`/`android/` custom.

Với Expo, không nhất thiết phải "eject" hẳn — chạy `npx expo prebuild` để generate `ios/`/`android/` từ config, vẫn giữ được phần lớn tooling Expo (EAS Build, most Expo SDK API). `npx react-native init` deprecated từ RN 0.75, dùng `npx @react-native-community/cli init` cho bare project thuần; project mới thường nên bắt đầu bằng `npx create-expo-app` rồi prebuild khi cần, thay vì init bare ngay từ đầu.

```bash
npx expo prebuild        # generate ios/ android/ từ app.json + plugins
npx expo prebuild --clean # regenerate sạch khi đổi plugin/native config
```

## Quy tắc quyết định

1. Mặc định giữ managed workflow càng lâu càng tốt — mỗi lần prebuild là một lần phải tự maintain code native thay vì để Expo lo.
2. Trước khi prebuild vì "cần thư viện X", kiểm tra Expo SDK hoặc `npx expo install X` có sẵn config plugin không — nhiều thư viện phổ biến (Firebase, Stripe, Sentry...) đã có plugin chính thức, không cần bare.
3. Sau khi đã prebuild, thư mục `ios/`/`android/` trở thành source of truth cho phần native — đổi `app.json` không tự động sync nữa trừ khi chạy lại `prebuild`, cẩn thận drift giữa config và code native đã sửa tay.
4. Không trộn: nếu team đã quyết định bare workflow và có code native tay trong `ios/`/`android/`, không đề xuất quay lại managed — sẽ mất code đó.
