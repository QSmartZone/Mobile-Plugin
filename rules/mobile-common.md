---
trigger: always_on
description: Quy tắc chung mọi platform mobile (Flutter/Android/iOS/React Native)
---

# Mobile — quy tắc chung

**Soi project trước:**
- Đọc manifest (`pubspec.yaml`/`build.gradle`/`Podfile`/`package.json`) trước khi sửa.
- Theo lib/convention đã dùng trong repo, không đề xuất lib mới khi lib có sẵn đủ.

**Giữ nguyên kiến trúc:**
- Không tự đổi công nghệ, kiến trúc, hoặc migrate khi chưa được yêu cầu tường minh.

**Test:**
- Bug fix/feature có branch, loop, hoặc parser → viết ít nhất 1 unit/widget test.
- UI tĩnh (không logic) không cần test.

**Lỗi network:**
- Tách UI khỏi HTTP client qua repository/service layer.
- Phân biệt rõ lỗi network, lỗi parse, lỗi business.
- Không nuốt exception, không rethrow lỗi thô lên UI.

**Baseline UI:**
- Touch target ≥48dp (Android)/44pt (iOS) + contrast đạt WCAG AA + label accessibility cho UI người dùng cuối.
- Null-safety triệt để, không force-unwrap (`!!`/`as!`) khi chưa chắc chắn giá trị non-null.

**Ngoài scope:**
- Đổi kiến trúc hoặc thêm native module mới ngoài file được giao → dừng, báo lý do.

**Verify trước khi báo xong:**
- Chạy analyze/lint và test liên quan.
- Dán output verify vào báo cáo.
