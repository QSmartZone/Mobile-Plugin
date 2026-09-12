# Troubleshoot Flutter — chi tiết

| Triệu chứng | Lệnh kiểm tra | Fix |
| --- | --- | --- |
| `pub get` treo | quan sát log, chờ vài giây | `flutter pub get --offline` nếu cache có sẵn, hoặc kiểm tra proxy/firewall |
| Version solving failed | đọc dependency conflict trong log | sửa version constraint trong `pubspec.yaml` theo đúng conflict báo |
| Build lạ, cache stale | so sánh lỗi với code hiện tại | `flutter clean` rồi `flutter pub get` lại |
| CocoaPods lỗi (ios/) | đọc lỗi `pod install` | `pod repo update` rồi `pod install --repo-update` trong `ios/` |
| Gradle JDK mismatch | `flutter doctor -v` | `flutter config --jdk-dir <path>` trỏ đúng JDK Gradle cần |
| Xcode signing trên simulator | build trên simulator, không physical device | chạy trên simulator không cần signing, bỏ qua nếu không build device thật |
| "No devices" | `flutter devices` | `flutter emulators --launch <id>` hoặc cắm thiết bị/mở simulator |
| Hot reload không ăn | đổi gì gần nhất (const/initState/enum) | đổi `const`, `initState`, enum → cần hot **restart**, không phải reload |
