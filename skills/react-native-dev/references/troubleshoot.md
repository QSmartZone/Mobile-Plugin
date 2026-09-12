# Troubleshoot

| Triệu chứng | Lệnh kiểm tra | Fix |
| --- | --- | --- |
| Metro trả code cũ / không nhận thay đổi | `npx react-native start --reset-cache` | Cache stale; nếu vẫn không hết: `watchman watch-del-all` |
| Pod install lỗi/thiếu dependency iOS | `cd ios && pod install --repo-update` | Cập nhật CocoaPods repo trước khi retry |
| Gradle build lỗi sau khi upgrade RN | `cd android && ./gradlew clean` | Xoá build cache Gradle rồi build lại |
| "Unable to resolve module ..." | `rm -rf node_modules && rm -f package-lock.json yarn.lock` | Reinstall dependency sạch |
| Expo SDK version mismatch giữa lib | `npx expo-doctor` | `npx expo install --fix` để align version theo SDK |
| App chạy trên device thật không thấy Metro | `adb devices` | `adb reverse tcp:8081 tcp:8081` (Android USB) |
| Crash mơ hồ, nghi thư viện native cũ chưa support Hermes | `npx react-native info` | Kiểm tra changelog lib, update hoặc báo issue upstream |
| Lib native chưa hỗ trợ New Architecture, crash khi build | `npx react-native info` | RN < 0.82: tạm set `newArchEnabled=false` trong `gradle.properties`, ghi rõ đây là workaround tạm. RN ≥ 0.82: legacy architecture đã bị bỏ, phải update/thay lib |
