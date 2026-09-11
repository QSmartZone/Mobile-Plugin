# mobile-plugin

Plugin generic cho mobile dev (Flutter, Android native, iOS) — không dính business logic của project cụ thể nào.

## Nội dung

- `rules/hot_reload.md` — kết nối `dtd`/`hot_reload` sau mỗi lần sửa file Dart/Flutter.
- `skills/android-cli` — dùng CLI `android` (tạo project, chạy app, quản lý emulator, chụp screenshot, xem layout).
- `skills/flutter-dev`, `skills/android-native-dev`, `skills/ios-dev` — convention theo platform.
- `agents/flutter-expert.md`, `agents/android-native-expert.md`, `agents/ios-expert.md` — agent chuyên gia tương ứng.

## Cài đặt

### Tự động, mọi host phát hiện được trên máy

```sh
./install.sh                          # hỏi scope + host qua menu
./install.sh --scope project          # cài vào project đang đứng (thư mục gọi lệnh này)
./install.sh --scope user             # cài global cho user
./install.sh --dry-run                # xem sẽ làm gì, không đổi gì trên đĩa
./install.sh --only claude            # chỉ cài Claude, bỏ qua agy/dsh
```

Sửa repo xong: Claude cập nhật qua marketplace (`claude plugin update mobile-dev@mobile`); Antigravity/dsh là bản copy nên chạy lại `./install.sh` với đúng scope đã dùng lần trước.

### Claude Code / Desktop — tay

```sh
# user scope (mặc định của claude CLI)
claude plugin marketplace add /Users/ctquyen/Documents/project/self-project/core/mobile-plugin --scope user
claude plugin install mobile-dev@mobile --scope user

# project scope — chạy 2 lệnh trên trong chính thư mục project muốn dùng plugin
cd /path/to/your-project
claude plugin marketplace add /Users/ctquyen/Documents/project/self-project/core/mobile-plugin --scope project
claude plugin install mobile-dev@mobile --scope project
```

### Antigravity IDE (`agy`)

```sh
agy plugin install /Users/ctquyen/Documents/project/self-project/core/mobile-plugin
```

## Đa nền tảng

Hỗ trợ 3 host: Claude Code/Desktop, Antigravity IDE + `agy`, DeepSeek Harness `dsh`. Xem `docs/adr/multi-platform-support.md` cho quyết định kiến trúc (core + overlay, copy-not-symlink, scope user/project).
