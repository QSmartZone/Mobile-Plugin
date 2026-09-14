---
name: flutter-sdk-platform
description: "Kiến trúc Flutter SDK đa package (path dependency), white-label nhiều tenant — layering, composition seam, config/secrets, theming. Dùng khi thiết kế/tách SDK Flutter đa package. Không dùng cho app đơn lẻ 1 mục đích."
---

# Flutter SDK Platform Architecture

Skill này trả lời: khi cần dựng một **SDK Flutter đa package (pub packages, path dependency), dùng lại được cho nhiều app/tenant**, quyết định nào phải chốt trước, theo pattern nào, và bẫy nào đã có người dính. Khác `skills/flutter-dev` (convention viết code Flutter thường ngày) — skill này là quyết định kiến trúc cấp SDK, đọc 1 lần lúc thiết kế/tái cấu trúc, không phải đọc mỗi lần sửa 1 widget.

Nguồn đối chứng: 1 SDK Flutter 7-package (5 domain package + 2 role bundle) đã ship qua nhiều phase, có ADR ghi lại từng quyết định và trade-off thật. Các reference dưới đây tổng quát hoá pattern đó — không copy nguyên business logic.

## Khi nào skill này áp dụng

- Task: "xây SDK/plugin dùng chung cho nhiều app", "tách feature thành package độc lập", "white-label app" (1 codebase, đổi theme/copy/config theo khách hàng), "thiết kế lại kiến trúc mobile đa module".
- KHÔNG áp dụng cho app đơn lẻ, 1 tenant, không có ý định tái sử dụng — layering này có chi phí (nhiều package, nhiều pubspec, nhiều lần grep trước khi thêm dependency); đừng trả chi phí đó khi không có lợi ích tái dùng.

## 5 quyết định phải chốt trước khi viết package đầu tiên

| Quyết định | Reference | Câu hỏi cốt lõi |
| --- | --- | --- |
| 1. Layering — chia package thế nào, ai phụ thuộc ai | [package-layering.md](references/package-layering.md) | Package nào là "lõi mọi người đều cần", package nào là "tính năng optional", package nào là "preset lắp sẵn cho 1 kiểu tenant/role"? |
| 2. Composition seam — logic nối 2 package sống ở đâu | [composition-and-session.md](references/composition-and-session.md) | Domain package có được biết domain package khác tồn tại không? Ai mở HTTP client/session? |
| 3. Config & secrets boundary | [white-label-config.md](references/white-label-config.md) | Secret/endpoint vào SDK bằng cách nào? Theme/copy đổi theo tenant bằng cơ chế gì, không phải if/else rải rác? |
| 4. Hợp đồng với backend chưa tồn tại | [contract-and-legacy-port.md](references/contract-and-legacy-port.md) | Backend chưa xong thì SDK viết theo cái gì? Có code cũ (app cũ, SDK cũ) để tham chiếu không, port kiểu gì? |
| 5. Verify khi không có (hoặc chưa có) reference app | [verification-strategy.md](references/verification-strategy.md) | Test ở mức nào, đánh đổi gì khi bỏ test package-level? |

Đọc đúng reference tương ứng với việc đang làm — đừng đọc hết 5 file cho 1 thay đổi nhỏ trong 1 package đã có.

## Checklist khi bắt đầu 1 package mới trong SDK đã có

1. Package này thuộc layer nào (core / shared-ui / domain / bundle)? → xác nhận theo [package-layering.md](references/package-layering.md) trước khi tạo thư mục.
2. Cần dùng thứ gì từ package khác cùng layer (domain↔domain)? → không import thẳng, đẩy xuống core/shared-ui ([composition-and-session.md](references/composition-and-session.md)).
3. Cần dependency bên thứ 3 → đã khai ở core chưa? Có rồi thì không khai lại ([package-layering.md](references/package-layering.md)#dependency-hygiene).
4. Có string/màu hardcode cho 1 tenant cụ thể? → phải đi qua config/token/terminology, không literal trong widget ([white-label-config.md](references/white-label-config.md)).
5. Backend endpoint tương ứng đã có chưa? Chưa có → xem [contract-and-legacy-port.md](references/contract-and-legacy-port.md) để biết cách viết trước theo hợp đồng đóng băng.
6. Verify bằng gì trước khi báo xong → [verification-strategy.md](references/verification-strategy.md).

## Nguyên tắc bao trùm

Mọi rule trong 5 reference tồn tại vì một quyết định ngược lại đã trả giá thật (rework, leak dependency, tenant A thấy chữ của tenant B). Không suy diễn thêm rule mới ngoài những gì reference nói; gặp tình huống reference chưa cover → đó là quyết định kiến trúc mới, dừng lại hỏi thay vì tự bịa theo cảm tính.
