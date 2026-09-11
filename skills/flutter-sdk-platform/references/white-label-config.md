# White-label config, secrets & theming — chi tiết

Đối chứng: single-origin base URL ADR + terminology noun-set ADR của 1 SDK white-label thực chiến (1 codebase, mỗi customer clone và đổi config).

## Secrets & endpoint — không bao giờ commit vào SDK

SDK không đọc file `.env`, không ship endpoint/key mặc định nào. Mọi thứ "theo môi trường" vào từ app tiêu thụ lúc build:

| Loại giá trị | Cách vào | Ví dụ cơ chế |
| --- | --- | --- |
| Base URL, feature flag | Build-time define | `--dart-define`, `BuildConfig` field, `xcconfig` |
| API key bên thứ 3 (maps, payment) | Config native platform | Gradle `manifestPlaceholders`, `Info.plist`/`GMSServices` |

SDK không tự quyết "biết" giá trị nào — mọi domain package đọc qua 1 object config chung (ví dụ `SdkConfig`) do app tiêu thụ truyền vào lúc khởi tạo, không đọc biến môi trường trực tiếp rải rác từng nơi.

## Một origin, nhiều path prefix — không phải 1 URL mỗi service

Kể cả khi backend là nhiều service độc lập (nhiều origin/port), SDK chỉ expose **1 `baseUrl`** cấu hình được, các service phân biệt bằng path prefix (`/booking-service`, `/payment-service`...), mỗi prefix cũng cấu hình được riêng. Lý do: 1 chứng chỉ TLS, 1 CORS origin, 1 audience token cho mọi build — thêm service mới sau này không cần đổi client. Hệ quả ngược: nếu backend thật sự nhiều origin, phải có gateway/reverse-proxy đứng trước — đó là việc của backend/devops, không phải việc SDK tự mở nhiều client theo nhiều origin.

## Theming — token, không literal

Mọi màu/kích thước chữ trong widget lấy từ 1 hệ token trung tâm (`ThemeConfig` → design tokens), không bao giờ hex color hay `fontSize:` literal ngay trong widget — literal trong widget nghĩa là đổi theme cho customer khác phải sửa từng file thay vì sửa 1 chỗ.

Token phái sinh (ví dụ màu chữ "on-surface") phải tính từ cặp màu **thật sự vẽ bên dưới** tại thời điểm dùng, không phải màu nền mặc định giả định — text đặt trên gradient/nền trong suốt mà không kiểm tra độ tương phản là lỗi hay gặp nhất khi theme đổi theo tenant.

## Terminology — noun set, không phải feature flag logic

Khi nhiều tenant dùng chung 1 domain nhưng gọi tên khác nhau (tenant A gọi "đặt chỗ", tenant B gọi "yêu cầu"), tách riêng 1 **noun set** (ví dụ: `entityNoun`, `entityNounPlural`, `actorRoleLabel`...) trong config, và **thay hết string cứng chứa noun đó trong toàn bộ UI** — không chỉ thêm field cấu hình rồi dùng nửa vời ở vài màn (kiểu nửa vời = giả white-label, tenant thứ 2 vào mới lộ ra chỗ chưa thay).

Ràng buộc:
- Terminology chỉ đổi **text hiển thị**, không rẽ nhánh logic theo terminology (nếu logic phải khác theo tenant, đó là 1 quyết định kiến trúc khác — feature flag hoặc tách domain, không phải terminology).
- String kỹ thuật (log, exception message nội bộ) giữ nguyên, không cần qua terminology.
- String ghép câu có noun ở giữa (`"Huỷ $entityNoun"`) phải xử lý viết hoa đúng vị trí bằng helper chung, không tự viết hoa tay từng chỗ.
- Không cần kéo cả 1 framework i18n nếu chưa cần dịch đa ngôn ngữ thật — noun set là bước trung gian đủ dùng khi chỉ cần đổi thuật ngữ theo tenant, không đổi ngôn ngữ.

## Bẫy thường gặp

- Thêm field terminology mới nhưng chỉ áp vào 2-3 màn "chính" — tenant thứ 2 dùng tới màn còn lại mới phát hiện string cứng còn sót, sửa muộn tốn hơn sửa ngay từ đầu.
- Base URL cấu hình được nhưng service path prefix hardcode — tưởng đã config-hoá xong nhưng vẫn phải sửa code khi thêm service.
- Theme token đúng ở component gốc nhưng 1 màn mới viết vội hex trực tiếp — cần 1 bước review/grep định kỳ (`grep "Color(0x\|fontSize:"`) trước khi coi 1 batch code là xong.
