# Composition seam & session pattern — chi tiết

Đối chứng: cross-package data flow (auth token, realtime event) + "bundle compose domain screen preset" trong 1 SDK 7-package thực chiến.

## Vấn đề gốc

2 domain package (ví dụ booking và bản đồ) không được import nhau (package-layering.md), nhưng runtime vẫn cần dữ liệu chảy từ package này sang package kia (ví dụ: vị trí realtime của booking cần vẽ lên bản đồ). Nếu không có seam rõ ràng, người viết sẽ import chéo "cho tiện" — phá vỡ layering ngay lần đầu cần tính năng liên domain.

## Pattern: composition layer là nơi duy nhất biết cả 2 domain

```
domain A (booking) ─── event/stream nội bộ ───▶ core (transport chung)
                                                      │
                                    composition layer │ (app shell / bundle)
                                    — nơi DUY NHẤT     │  map payload A → type B hiểu được
                                    biết cả A và B      ▼
                                                domain B (map) nhận qua interface chung
                                                (Stream<T>, callback) — không biết A tồn tại
```

- Domain package A không mở kết nối network/realtime riêng cho nó — dùng transport chung ở core.
- Domain package B (bản đồ, chart, bất cứ thứ hiển thị dữ liệu domain khác) nhận input qua kiểu dữ liệu **của chính nó** (không phải type của A) — B không bao giờ `import` A.
- Composition layer (app shell, hoặc bundle preset theo role) là chỗ duy nhất map dữ liệu từ A sang type B hiểu. Đây là "seam" — nếu mai domain A đổi shape dữ liệu, chỉ 1 chỗ này sửa.

## Pattern: một session, một client, dùng chung

Đừng để mỗi domain package tự mở HTTP client/DB connection/socket riêng — làm vậy thì auth refresh, retry, error mapping phải viết lại N lần và dễ lệch nhau (1 domain quên refresh token là lỗ hổng bảo mật lặng lẽ).

```
core: Session(config)
    client cho service gốc ──▶ AuthInterceptor (refresh-on-401, single-flight)
    client(root khác) ─▶ client mới, CÙNG interceptor, memo hoá theo root
    realtime ─▶ kênh transport dùng chung
        │
        ▼
shared-ui: AppShell dựng (hoặc nhận) Session, expose qua scope/DI,
           nối auth state với lifecycle realtime:
           SignedIn → connect() ; SignedOut → disconnect() + clear local store
        │
        ▼
domain preset: build repository từ session.clientFor(root), LAZY —
        chỉ tạo khi màn hình đầu tiên cần, không tạo eager lúc app khởi động
```

Domain package không bao giờ tự new client hay build repository trước khi màn hình cần — tạo lazy là điều kiện để bundle/preset merge được nhiều domain mà không phải trả giá khởi tạo tất cả ngay từ đầu.

## Pattern: bundle compose preset, không tự có logic

Domain package có UI export "preset" — 1 map route-id → builder, dùng session composition layer cung cấp. Bundle (gói theo role/tenant) chỉ **merge** các preset này vào route table của app shell, host-supplied override luôn thắng preset:

```
bundle.build() = appShell(
  overrides: {...domainAPreset.overrides, ...domainBPreset.overrides, ...hostOverrides},
  extraRoutes: [...domainAPreset.extraRoutes, ...domainBPreset.extraRoutes, ...hostExtraRoutes],
)
```

Quy tắc cứng: bundle không tự tạo repository/state-holder/API-class/route logic của riêng nó. Logic nào lặp lại giữa 2 bundle → đẩy xuống domain package, không nhân đôi trong từng bundle.

## Bẫy thường gặp

- Domain package tự mở client riêng "cho nhanh" → mất refresh/retry chung, phát hiện muộn khi 1 domain bị 401 loop.
- Bundle bắt đầu chứa 1 dòng business logic "tạm thời" → 6 tháng sau bundle phình thành domain package thứ hai trá hình, khó tách lại.
- Composition layer eager-init mọi domain lúc app khởi động thay vì lazy theo màn hình cần → tăng thời gian khởi động cho consumer chỉ dùng 1 domain trong bundle.
