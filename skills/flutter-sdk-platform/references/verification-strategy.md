# Verify khi không có reference app / test suite — chi tiết

Đối chứng: quyết định bỏ test package-level trong 1 SDK không có app tham chiếu chạy được tại thời điểm build, thay bằng resolve+analyze+review.

## Khi nào cân nhắc bỏ test package-level (không phải mặc định)

Đây là quyết định có chủ đích cho 1 hoàn cảnh cụ thể — **không phải khuyến nghị chung**, và không áp dụng ngoài phạm vi SDK/package đang trong hoàn cảnh đó:

- Không có app/consumer thật để chạy SDK trong lúc phát triển (reference app đã bị gỡ hoặc chưa dựng).
- Trong hoàn cảnh đó, unit test tự viết + double/fake tự viết chỉ chứng minh code khớp **giả định của chính người viết test**, không chứng minh khớp hành vi backend thật hay hành vi runtime thật — rủi ro: test xanh nhưng bug thật vẫn lọt (ví dụ: assert đúng 1 màu/state mà cây widget thực tế không render ra màu/state đó).

## Khi KHÔNG nên áp dụng quyết định này

- Có reference app/backend thật chạy được → ưu tiên test tích hợp chạy trên app thật hoặc backend staging, không bỏ test chỉ vì "SDK này khó test đơn vị".
- Logic thuần thuật toán/parser/mapping không phụ thuộc runtime UI hay backend (dễ test đơn vị, giá trị cao, chi phí thấp) — loại này vẫn nên có unit test dù SDK tổng thể chọn chiến lược bỏ test package-level, đừng đánh đồng "bỏ test UI/integration" thành "bỏ test mọi thứ".

## Thay test bằng gì

1. **Resolve + analyze mọi package theo đúng thứ tự dependency** — 1 script ngắn (không cần workspace tool, xem package-layering.md) chạy `pub get`/`analyze` (hoặc tương đương ngôn ngữ khác) cho từng package, dừng ngay khi 1 package lỗi.
2. **Checklist review thay test** — vì không có test bắt lỗi tự động, checklist review phải cụ thể tới mức "grep pattern X phải rỗng" thay vì mô tả chung chung ("code sạch"). Checklist này sống cùng skill/rule của SDK, cập nhật mỗi khi 1 lỗi lọt qua review lần trước — nghĩa là checklist tăng dần theo thời gian, không viết 1 lần rồi để yên.
3. **Review gate là lưới an toàn cuối** — không merge khi chưa qua review, vì review đang gánh phần việc mà test suite thường gánh.
4. **Chạy thật khi có cơ hội đầu tiên** (backend lên, app tham chiếu dựng lại) — đây là lúc kỳ vọng có 1 đợt rework, không phải dấu hiệu SDK làm sai trước đó.

## Trade-off phải nói rõ với người quyết định (không giấu)

- Regression trong logic nội bộ phức tạp (thứ tự interceptor, chuyển state bloc/reducer, race condition async) chỉ bị bắt bởi review thủ công hoặc chạy tay — có thể lọt tới lần chạy thật sau, chậm hơn so với 1 test suite nhanh tại chỗ.
- Quyết định này áp dụng đúng cho phạm vi đang thiếu reference app; ghi rõ phạm vi (package nào, giai đoạn nào) trong ADR/quyết định — không để người đọc sau hiểu nhầm thành "SDK này vĩnh viễn không cần test".
- Giữ lại đường chạy test làm "dead code path" thay vì xoá hẳn tool chạy test — nếu sau này có reference app trở lại và quyết định đảo ngược, không phải viết lại từ đầu cơ chế chạy test.
