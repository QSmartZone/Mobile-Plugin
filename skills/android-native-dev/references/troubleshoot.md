# Troubleshoot Android — chi tiết

| Triệu chứng | Lệnh kiểm tra | Fix |
|---|---|---|
| Gradle sync fail (AGP/Kotlin/KSP/JDK mismatch) | `./gradlew --version`, xem `libs.versions.toml` | Đồng bộ version AGP/Kotlin/KSP theo bảng compat chính thức, khớp JDK toolchain |
| Build lỗi mơ hồ, không rõ nguyên nhân | `./gradlew <task> --stacktrace --info` | Đọc stacktrace/log chi tiết thay vì đoán |
| Gradle daemon treo, build không tiến triển | `./gradlew --status` | `./gradlew --stop` rồi build lại |
| Emulator không boot | `emulator -list-avds`, `adb devices` | Cold boot lại AVD (xoá snapshot), tăng RAM/disk AVD nếu cần |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` khi install | `adb shell pm list packages \| grep <id>` | `adb uninstall <package>` rồi install lại |
| Crash chỉ ở bản release, debug chạy bình thường | So sánh log debug vs release | Thêm/sửa R8/ProGuard keep rules cho class bị strip |
| Cần xem log riêng app đang debug | `adb shell pidof -s <package>` | `adb logcat --pid=$(adb shell pidof -s <package>)` |
| Crash native lib chỉ trên Android 15 (API 35) | Kiểm tra thiết bị dùng page size 16KB | Rebuild native lib (NDK) hỗ trợ 16KB page size |
