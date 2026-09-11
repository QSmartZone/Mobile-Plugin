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

## Đặt tên file — theo convention project đã có, fallback nếu chưa có

| Loại | Pattern | Ví dụ |
| --- | --- | --- |
| Screen | `<feature>_screen.dart` | `booking_screen.dart` |
| Bloc/Event/State | `<feature>_bloc.dart` / `_event.dart` / `_state.dart` | `booking_bloc.dart` |
| Repository interface | `<domain>_repository_abs.dart` (hoặc hậu tố tương đương project đang dùng) | `chat_repository_abs.dart` |
| Repository implementation | `<domain>_repository.dart` | `chat_repository.dart` |
| DTO (wire format từ backend) | `<name>_dto.dart` | `booking_dto.dart` |
| File generated (`build_runner`) | `<name>.g.dart` | không sửa tay, sửa file nguồn rồi chạy lại codegen |

Convention cụ thể luôn ưu tiên theo cái project đã dùng (kiểm tra file hiện có trước khi đặt tên file mới) — bảng trên chỉ là mặc định khi project chưa có quy ước rõ.

## DTO tách khỏi domain model khi có codegen HTTP client

Khi dùng HTTP client codegen (retrofit-style) + `json_serializable`/tương đương: tách model nhận trực tiếp từ backend (DTO, khớp đúng schema response) khỏi model domain UI dùng (`models/`) — đừng để 1 class vừa làm DTO vừa làm model UI. Lý do: backend đổi field/kiểu dữ liệu chỉ cần sửa DTO + mapper, không phải sửa lại mọi widget đang tiêu thụ model đó. Dự án nhỏ chỉ 1-2 API call, không codegen → có thể dùng chung 1 model, tách DTO lúc này chưa đáng chi phí.

## Package/module dùng chung nhiều app — layer-first thay vì feature-first

Khi có nhiều app trong cùng repo (monorepo) cùng phụ thuộc 1 package chung qua path dependency (mục dưới) — tổ chức bên trong package chung đó theo **layer-first** (`blocs/`, `dto/`, `models/`, `network/`, `repository/`, `service/`, `widgets/`), khác với feature-first ở app. Lý do: package chung chứa cross-cutting code (network client, repository, model dùng chung) chứ không phải 1 tập hợp feature hoàn chỉnh có UI riêng — nhóm theo layer giúp app tiêu thụ dễ tìm đúng thứ cần import (ví dụ mọi repository nằm 1 chỗ) hơn là theo feature vốn không rõ ranh giới ở tầng chia sẻ.

## Package hoá khi dự án lớn

Chỉ tách thành package Dart riêng (`packages/<name>`, mỗi package quản lý version độc lập qua path dependency trong `pubspec.yaml` của app) khi feature đó thực sự cần dùng lại ở app khác, hoặc team khác cần build/test độc lập. Không dùng melos hay tool quản lý monorepo — pubspec path dependency đủ dùng. Đừng tách package "cho gọn" khi chỉ có 1 app dùng — thêm chi phí version pin + `pubspec.yaml` riêng không đổi lại lợi ích gì.

## pubspec.yaml

- Pin version theo `^x.y.z` (caret), không pin cứng tuyệt đối trừ khi có lý do tương thích cụ thể.
- Thêm dependency mới: kiểm tra đã có lib tương đương trong `pubspec.yaml` chưa trước khi thêm cái mới làm cùng việc.
- `dev_dependencies` cho: `flutter_test`, `mocktail`/`mockito`, `build_runner` (nếu dùng codegen), lint package (`flutter_lints`).
