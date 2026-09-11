# UI thích ứng & accessibility — chi tiết

Đây là baseline tối thiểu cho app thông thường, không phải audit accessibility đầy đủ (WCAG AAA, test với TalkBack/VoiceOver thật) — việc đó vượt phạm vi skill này, cần yêu cầu riêng.

## Responsive layout

`MediaQuery.of(context).size`/`LayoutBuilder` để chia layout theo breakpoint (điện thoại vs tablet vs web) — không hardcode kích thước px cố định cho widget phải chạy trên nhiều kích thước màn hình khác nhau.

`OrientationBuilder` chỉ khi UI thật sự cần đổi layout theo chiều xoay máy (ví dụ video player, bản đồ) — không phải mặc định cho mọi màn hình, phần lớn app chỉ cần layout dọc.

Bẫy: gọi `MediaQuery.of(context)` toàn cục ở nhiều widget nhỏ lẻ khiến cả cây widget rebuild mỗi khi resize/xoay máy (`MediaQuery.of` đăng ký dependency vào toàn bộ `MediaQueryData`, dù widget chỉ cần 1 field như `size.width`). Khi chỉ cần kích thước của 1 subtree cụ thể, `LayoutBuilder` cục bộ ít tốn hơn.

## Accessibility

`Semantics`/`semanticLabel` bắt buộc cho icon-only button và ảnh mang ý nghĩa (không phải ảnh trang trí thuần) — screen reader (TalkBack/VoiceOver) không tự suy ra được ý nghĩa của 1 icon.

Contrast màu chữ/nền theo tối thiểu WCAG AA (tỷ lệ 4.5:1 cho chữ thường, 3:1 cho chữ lớn) — nếu design system đã có token màu, dùng đúng token đó thay vì tự chọn màu theo mắt.

Touch target (nút bấm, icon bấm được) tối thiểu 48x48dp — nhỏ hơn khó bấm chính xác, đặc biệt trên màn hình nhỏ hoặc người dùng có vận động hạn chế.

Bẫy cụ thể: `GestureDetector` bọc `Container`/`Padding` trần không kèm `Semantics` hoặc không dùng `InkWell`/`Material` — mắt thường thấy bấm được bình thường, nhưng screen reader hoàn toàn không nhận diện được đây là phần tử tương tác (không focus được, không đọc được). Ưu tiên `InkWell`/`ElevatedButton`/widget có sẵn semantics thay vì tự dựng `GestureDetector` trần cho hành vi bấm.

Text scale: tôn trọng `MediaQuery.textScaler` của hệ điều hành thay vì fix cứng `fontSize` không co giãn — người dùng bật "chữ lớn" trong cài đặt hệ thống là nhu cầu accessibility thật, không phải edge case hiếm. Test nhanh: tăng text scale trong Settings của thiết bị/emulator, xem layout có tràn/cắt chữ không.

## Khi nào bắt buộc, khi nào không

Màn hình public-facing (đăng nhập, thanh toán, flow chính người dùng cuối dùng hàng ngày) → áp baseline này đầy đủ. Màn hình nội bộ/admin-only ít người dùng, hoặc UI debug/dev-only → có thể bỏ qua nếu không có yêu cầu compliance cụ thể — không áp cứng nhắc như nhau cho mọi màn hình trong app.
