# Xây trước backend & port từ codebase cũ — chi tiết

Đối chứng: "implement frozen contract ahead of backend" + "auth API is a seam" + "rewrite not copy legacy infrastructure" — 3 ADR của 1 SDK phải build song song với backend chưa xong, dựa trên hạ tầng 1 app cũ.

## Xây SDK trước khi backend endpoint tồn tại

Khi timeline buộc SDK phải viết trước khi backend có endpoint thật:

1. Có 1 tài liệu hợp đồng (contract) được "đóng băng" — request/response shape, sự kiện realtime, luồng nghiệp vụ — SDK implement đúng theo tài liệu đó, không đoán.
2. Interface hoá đúng những chỗ sẽ đổi khi backend thật xuất hiện (transport realtime, payment gateway...) — implementation cụ thể có thể compile được và trả lỗi runtime có kiểm soát khi gọi vào endpoint chưa tồn tại, nhưng interface không đổi khi backend lên.
3. Chấp nhận tường minh: verify lúc này là "đúng theo cách đọc hợp đồng của mình", không phải "đúng với server thật". Có ngân sách rework sau khi backend xong — không coi giai đoạn build-trước là xong 100%.
4. Chỗ hợp đồng và implementation lệch nhau (phát hiện giữa chừng) → ghi rõ ai là nguồn đúng cho lần build hiện tại (thường: controller thật đã lên thắng tài liệu cũ), không im lặng chọn 1 bên.

Không dựng lại 1 "double"/fake server trong-repo để tự test khớp cái double đó — double do chính SDK viết ra chỉ chứng minh SDK khớp giả định của chính nó, không chứng minh khớp hợp đồng thật. Đối chiếu bằng backend thật/staging khi có, hoặc review kỹ theo tài liệu hợp đồng.

## Dialect riêng của 1 backend/customer — cô lập bằng seam interface

Khi phần lõi (core) phải giao tiếp với backend/service có "phương ngữ" riêng (tên field khác, luồng refresh token khác, response shape khác theo từng khách hàng):

```
core: định nghĩa interface (vd AuthApi) — Repository/Interceptor chỉ phụ thuộc interface
customer/app cụ thể: viết implementation riêng cho phương ngữ của backend đó
```

- Interface sống ở core, implementation của 1 dialect cụ thể sống ở project tiêu thụ (không sống trong core, không thành 1 package SDK riêng) — core không học "từ vựng" của bất kỳ khách hàng cụ thể nào.
- Logic dùng chung (retry, single-flight refresh, lưu token) viết 1 lần quanh interface, không viết lại theo từng dialect.
- Interface không được làm yếu hợp đồng chung (ví dụ: implementation phải trả đúng những gì backend cho, core lưu đúng như vậy — không tự ý bỏ field vì "dialect này không có").
- Endpoint 1 dialect không hỗ trợ → trả lỗi rõ ràng, không giả vờ thành công, không crash.

## Port hạ tầng từ codebase cũ — rewrite, không copy nguyên

Khi có 1 codebase cũ (app cũ, SDK cũ) chứa hạ tầng đã chứng minh chạy được (module network, lưu token, socket registry...):

1. Dùng codebase cũ làm **tài liệu tham chiếu để đọc và viết lại**, không copy-paste nguyên file — copy nguyên kéo theo defect cũ và convention không khớp kiến trúc mới.
2. Trước khi port, liệt kê rõ defect đã biết trong bản cũ — không lặp lại chúng:
   - Ví dụ điển hình: chỉ lưu access token mới khi refresh trong khi backend rotate cả 2 token → phải lưu cả 2.
   - Ví dụ điển hình: lưu token/secret bằng storage không mã hoá → SDK mới dùng secure storage, không bao giờ lưu secret nhạy cảm (PIN, OTP) dù ở đâu.
   - Ví dụ điển hình: registry lắng nghe sự kiện chặn đăng ký lại sau reconnect (chỉ cho 1 listener/loại sự kiện) → viết lại registry cho phép re-register an toàn.
3. Phần nào của bản cũ *thực sự tốt* (ví dụ: pattern single-flight khi refresh token đang chạy, tránh gọi refresh trùng) → giữ lại có chủ đích, ghi rõ lý do giữ.
4. Phạm vi port: chỉ hạ tầng generic (network, storage, transport). KHÔNG port nguyên bộ UI/feature nặng nghiệp vụ cũ, KHÔNG port class màu/style tĩnh — UI mới viết theo hệ token của SDK mới (white-label-config.md), không theo style cứng của app cũ.
5. Mỗi chỗ cố ý làm khác bản cũ → để lại ghi chú ngắn trong code/PR nêu rõ đây là khác biệt có chủ đích, không phải sót — người review sau (hoặc chính mình 6 tháng sau) không phải đoán có phải bug port hay không.
