# API integration & error handling — chi tiết

## Theo đúng lib đã có

Dự án đã có HTTP client (`dio`, `http`, `chopper`...) và cách serialize (`json_serializable`, `freezed`, tự viết `fromJson`) thì dùng đúng cái đó — không đề xuất đổi lib giữa chừng vì lý do "chuẩn hơn".

## Luôn có 1 lớp repository/data source

Kể cả app nhỏ, tách UI khỏi lời gọi HTTP trực tiếp bằng 1 lớp repository — lý do không phải "kiến trúc đẹp" mà là testability: không có lớp này thì test business logic của UI bắt buộc phải mock cả HTTP client, và đổi backend/endpoint phải sửa rải rác trong widget.

Không tự thêm usecase/domain layer riêng nếu chỉ có 1 repository phục vụ 1 màn hình/bloc — layer đó chỉ đáng chi phí khi thật sự có nhiều repository cần phối hợp logic chung (ví dụ: đặt chỗ cần gọi cả repository lịch + repository thanh toán trong 1 giao dịch).

## 3 loại lỗi cần phân biệt

UI cần biết đang gặp loại lỗi nào để hiển thị đúng thông điệp — gộp chung thành 1 "có lỗi" là nguyên nhân phổ biến nhất của thông báo lỗi vô nghĩa kiểu "Something went wrong":

- **Network/timeout** — không có mạng, server không phản hồi. UI nên cho retry.
- **Parse** — response không đúng schema mong đợi (backend đổi field, version cũ chưa update). UI nên báo lỗi chung, không retry (retry không giúp gì).
- **Business** — server trả lỗi hợp lệ theo domain (số dư không đủ, slot đã đầy). UI hiển thị đúng message server trả, không phải message generic.

## Trạng thái tối thiểu cho mọi màn hình gọi API

Bất kể dùng state management nào (`setState`/Bloc/Riverpod), màn hình gọi API cần phân biệt tối thiểu 4 trạng thái: loading, success, error, empty (thành công nhưng danh sách/dữ liệu rỗng). Thiếu phân biệt error vs loading khiến UI đứng im khi lỗi mà người dùng tưởng đang tải; thiếu empty khiến danh sách rỗng trông giống lỗi hoặc giống đang tải mãi.

## Bẫy cụ thể

- Bắt exception ở tầng UI (try/catch quanh lời gọi bloc/notifier trong widget) — logic xử lý lỗi bị lặp lại ở mọi nơi gọi, và không test được vì phải dựng cả widget tree. Bắt lỗi ở tầng gọi API (repository hoặc bloc), UI chỉ đọc state kết quả.
- Rethrow nguyên exception gốc của HTTP client (`DioException`, `SocketException`...) thẳng lên tầng UI — UI phải import và biết chi tiết implementation của HTTP client đang dùng, phá vỡ ranh giới tách lớp; nếu đổi HTTP client sau này, mọi nơi bắt exception gốc đó phải sửa theo. Nên có 1 kiểu lỗi domain-specific (hoặc mapping message) ở ranh giới repository.
- Gọi lại API mỗi lần rebuild vì đặt lời gọi trong `build()` thay vì `initState`/khi user chủ động trigger.

## Retry/cancel

Chỉ thêm khi thật sự cần: cho phép user bấm retry khi lỗi network; hủy request đang chạy khi user rời màn hình trước khi response về (tránh `setState`/emit trên widget đã dispose). Không cần dựng cơ chế retry tự động phức tạp nếu app không có yêu cầu đó.
