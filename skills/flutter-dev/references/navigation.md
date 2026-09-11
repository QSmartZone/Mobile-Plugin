# Navigation/routing — chi tiết

## Chọn cơ chế theo cái dự án đã có

Kiểm tra `pubspec.yaml` trước — dự án đã chọn rồi thì dùng đúng cái đó, đừng đề xuất đổi giữa chừng chỉ vì lib khác "phổ biến hơn".

| Nhu cầu | Chọn |
| --- | --- |
| App nhỏ/vừa, route không cần đồng bộ với URL, không deep link | `Navigator` 1.0 + named routes map thủ công |
| Cần deep link, sync URL trên web, nested navigation nhiều tab độc lập | `go_router` |
| Cần route type-safe qua codegen, team lớn nhiều người thêm route song song | `auto_route` |
| Chưa quyết — dự án chưa có gì trong `pubspec.yaml` | Bắt đầu bằng named routes map; chỉ nhảy sang `go_router`/`auto_route` khi thấy đúng nhu cầu ở hàng trên, không thêm lib "phòng khi cần sau" |

## Tập trung route definition ở 1 nơi

Dù chọn cách nào, định nghĩa route (tên, builder, guard) phải nằm ở 1 file/1 chỗ duy nhất — không rải `Navigator.push(context, MaterialPageRoute(builder: ...))` hardcode inline ở nhiều màn hình. Rải route như vậy khiến: đổi route đích phải sửa nhiều nơi, không thể unit-test luồng điều hướng, và deep link/analytics sau này phải quét lại toàn bộ codebase.

## Truyền dữ liệu giữa màn hình

Ưu tiên constructor argument hoặc 1 class argument có kiểu (`class BookingDetailArgs { final String bookingId; ... }`) thay vì `Map<String, dynamic>` rải rác — sai key trong `Map` chỉ lộ ra lúc runtime (thường là crash `null` khi đọc key không tồn tại), còn class có kiểu thì lỗi bắt được lúc compile.

## Bẫy cụ thể

- Quên `PopScope`/xử lý back-button khi có flow nhiều bước (form dài, checkout) cần xác nhận trước khi thoát — mất dữ liệu người dùng đã nhập.
- Push route mới mà không `await` kết quả trả về khi màn hình sau cần trả dữ liệu lại (ví dụ chọn địa chỉ) — dùng `Navigator.pop(context, result)` + `await Navigator.push(...)` để nhận lại.
- Named routes map dùng chuỗi string tay ('login', 'home') rải khắp code — định nghĩa hằng số tên route ở 1 nơi, tránh gõ sai chuỗi không được compiler bắt.
- Điều hướng bằng `Navigator` sâu bên trong widget con (nhận `BuildContext` qua nhiều tầng chỉ để gọi `Navigator.of(context)`) — cân nhắc để callback điều hướng ở tầng screen/bloc gọi xuống, widget con chỉ phát sự kiện, dễ test và dễ tái sử dụng widget ở màn hình khác.
- Không kiểm tra `context.mounted` trước khi điều hướng sau 1 thao tác `await` (gọi API xong mới push) — widget có thể đã bị dispose trong lúc chờ, gây lỗi runtime khi dùng `context` đã chết.

## Khi nào KHÔNG cần đổi cơ chế routing

Named routes map thủ công đang chạy ổn, không có yêu cầu deep link/URL sync mới → không tự ý migrate sang `go_router` chỉ vì đó là lựa chọn "hiện đại hơn". Chi phí migrate route (viết lại toàn bộ điều hướng, test lại mọi luồng) chỉ đáng trả khi có nhu cầu cụ thể chưa đáp ứng được bằng cơ chế hiện tại.
