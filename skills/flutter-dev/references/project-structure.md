# Cấu trúc dự án Flutter — chi tiết

## Feature-first layout

```
lib/
├── src/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── blocs/          # hoặc providers/, controllers/
│   │   │   └── models/
│   │   └── booking/
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── blocs/
│   │       └── models/
│   ├── core/                   # shared: theme, routing, network client, utils
│   └── widgets/                # widget tái dùng đa feature (button, input, card...)
└── main.dart
```

Lý do: đổi/xoá 1 feature chỉ động vào 1 thư mục, không rải file khắp `screens/`, `widgets/`, `models/` toàn app.

## Package hoá khi dự án lớn

Chỉ tách thành package Dart riêng (`packages/<name>`, mỗi package quản lý version độc lập qua path dependency trong `pubspec.yaml` của app) khi feature đó thực sự cần dùng lại ở app khác, hoặc team khác cần build/test độc lập. Không dùng melos hay tool quản lý monorepo — pubspec path dependency đủ dùng. Đừng tách package "cho gọn" khi chỉ có 1 app dùng — thêm chi phí version pin + `pubspec.yaml` riêng không đổi lại lợi ích gì.

## pubspec.yaml

- Pin version theo `^x.y.z` (caret), không pin cứng tuyệt đối trừ khi có lý do tương thích cụ thể.
- Thêm dependency mới: kiểm tra đã có lib tương đương trong `pubspec.yaml` chưa trước khi thêm cái mới làm cùng việc.
- `dev_dependencies` cho: `flutter_test`, `mocktail`/`mockito`, `build_runner` (nếu dùng codegen), lint package (`flutter_lints`).
