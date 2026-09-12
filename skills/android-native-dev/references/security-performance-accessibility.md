# Bảo mật, hiệu năng, accessibility — cơ bản

## Bảo mật dữ liệu nhạy cảm

- Không log token/password/số thẻ/PII ra Logcat, kể cả debug build — log debug dễ lọt qua bản release nếu quên xoá hoặc quên gate theo `BuildConfig.DEBUG`, và Logcat có thể đọc được bởi app khác/tool debug trên thiết bị đã root.
- Lưu bí mật (access token, API key, refresh token) bằng Android Keystore trực tiếp (`EncryptedFile`/Tink) hoặc DataStore mã hoá bằng key lưu trong Keystore — không dùng `SharedPreferences` thường (lưu plaintext). `EncryptedSharedPreferences` (Jetpack Security `security-crypto`) đã deprecated từ 2024, dự án đang dùng thì chưa cần migrate gấp nhưng code mới không nên thêm mới.
- Khai `android:allowBackup="false"` trong Manifest nếu app xử lý dữ liệu nhạy cảm. Từ Android 12 (API 31), `adb backup` không lấy được data của app non-debuggable nữa — rủi ro thật là thiết bị root hoặc bị extract trực tiếp (không phải `adb backup` trên bản release thông thường).

## Hiệu năng cơ bản

- Không block main thread bằng I/O đồng bộ (đọc/ghi file, network call, DB query) — dùng coroutine + `Dispatchers.IO`. Block main thread quá lâu (~5s) → ANR (Application Not Responding).
- Dùng LeakCanary trong debug build để tự động phát hiện memory leak (Activity/Fragment/View không giải phóng đúng lúc) — thêm dependency `debugImplementation`, không build vào release.
- `RecyclerView`: dùng `ViewHolder` đúng pattern (`findViewById` một lần trong `ViewHolder`, không gọi lại mỗi lần `onBindViewHolder`); update list dùng `DiffUtil` (tính diff, chỉ animate/redraw phần thay đổi) thay vì `notifyDataSetChanged()` (redraw toàn bộ, giật lag với list dài).
- Compose `LazyColumn`/`LazyRow`: truyền `key()` đúng cho mỗi item (thường là id ổn định) để Compose track đúng item khi list thay đổi, tránh recompose/re-layout thừa (chi tiết ở `jetpack-compose.md`, ở đây chỉ nhắc ngắn).

## Accessibility cơ bản

- `contentDescription` cho ảnh/icon có ý nghĩa chức năng (nút bấm, icon trạng thái) để TalkBack đọc đúng; ảnh trang trí thuần thì set `contentDescription="@null"` (hoặc `null` trong Compose `Image`) để TalkBack bỏ qua, không đọc rác.
- Kích thước touch target tối thiểu 48dp x 48dp cho mọi button/icon bấm được — icon nhỏ hơn 48dp cần thêm padding để đạt vùng chạm tối thiểu, không phóng to icon.
- Test nhanh bằng TalkBack (Settings > Accessibility > TalkBack) để nghe thứ tự đọc và label có hợp lý không trước khi coi màn hình xong.
- Contrast ratio tối thiểu giữa text/icon và nền theo WCAG AA: 4.5:1 cho text thường, 3:1 cho text lớn (≥18sp hoặc ≥14sp bold) và icon có ý nghĩa chức năng.

## Bẫy cụ thể

- Log toàn bộ response body API (có thể chứa token/PII) ở interceptor debug (OkHttp `HttpLoggingInterceptor` level `BODY`) mà quên tắt/gate ở release build → lộ dữ liệu nhạy cảm qua Logcat trên bản release.
- `notifyDataSetChanged()` cho `RecyclerView` list lớn thay vì `DiffUtil` khi cập nhật list → giật lag rõ rệt mỗi lần update, đặc biệt list dài hoặc item phức tạp.
- Thiếu `contentDescription` cho icon-only button (nút chỉ có icon, không text) → TalkBack đọc "Button" vô nghĩa, user khiếm thị không biết chức năng nút.
- Touch target nhỏ hơn 48dp (icon 24dp không padding) → khó bấm chính xác, đặc biệt user vận động khó khăn hoặc màn hình nhỏ.
- Để `allowBackup="true"` mặc định trên app xử lý dữ liệu nhạy cảm mà không set `false` hoặc `dataExtractionRules` → dữ liệu app (kể cả SharedPreferences thường) trích xuất được khi thiết bị root hoặc bị extract trực tiếp.
