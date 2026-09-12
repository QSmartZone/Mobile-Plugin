---
name: android-cli
description: Dùng CLI `android` để tạo project Android, cài SDK, chạy app, quản lý emulator, chụp screenshot, xem layout UI, tra docs. Dùng khi cần thao tác thiết bị/emulator hoặc build-run APK. Không dùng khi: viết code Kotlin (đó là android-native-dev).
---
# Android CLI Specialist

Công cụ `android` thao tác project, thiết bị, SDK. Bảng dưới là lối vào nhanh; chi tiết flag: chạy `android help <command>`.

## Installation

Nếu chưa có `android` trong PATH, cài theo OS:
- Linux: `curl -fsSL https://dl.google.com/android/cli/latest/linux_x86_64/install.sh | bash`
- Mac Arm: `curl -fsSL https://dl.google.com/android/cli/latest/darwin_arm64/install.sh | bash`
- Mac Intel: `curl -fsSL https://dl.google.com/android/cli/latest/darwin_x86_64/install.sh | bash`
- Windows: `curl -fsSL https://dl.google.com/android/cli/latest/windows_x86_64/install.cmd -o "%TEMP%\i.cmd" && "%TEMP%\i.cmd"`

## Lệnh → dùng khi

| Lệnh | Dùng khi |
|---|---|
| `android init` | Setup bắt buộc lần đầu trước khi dùng các lệnh khác |
| `android sdk install/update/remove/list` | Cài/gỡ/liệt kê SDK package |
| `android create <template> --name= --output=` | Tạo project Android mới từ template |
| `android run` | Build, deploy, chạy app trên thiết bị/emulator |
| `android emulator create/start/stop/list/remove` | Quản lý Android Virtual Device |
| `android screen capture` | Chụp màn hình thiết bị đang kết nối |
| `android layout` | Trả về cây layout UI dạng JSON, nhanh hơn chụp screenshot khi debug UI |
| `android docs search "<từ khoá>"` | Tra tài liệu Android chính thức (API, migration, best practice) |
| `android install` | Cài APK vào thiết bị/emulator |
| `android info` | Xem thông tin thiết bị/SDK đang cấu hình |
| `android update` | Cập nhật CLI lên bản mới nhất |

## Tương tác thiết bị & journey test

- Xem [references/interact.md](references/interact.md) để tương tác thiết bị (tap, input, adb...).
- Xem [references/journeys.md](references/journeys.md) để chạy journey test.
