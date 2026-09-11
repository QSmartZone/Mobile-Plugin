# Package layering — chi tiết

Đối chứng: ADR "SDK ships as N path-linked packages, without a workspace tool" + ADR "core dependencies are shared by every sub-package".

## Layer chuẩn — 4 tầng

```
                    ┌──────┐
                    │ core │   config, HTTP client, auth, secure storage,
                    └───┬──┘   realtime transport, error model — Dart thuần,
                        │      KHÔNG import framework UI
                   ┌────▼─────┐
                   │ shared-ui│   design tokens, app shell, widget nguyên thuỷ
                   └────┬─────┘
          ┌─────────────┼─────────────┐
          │             │             │
   ┌──────▼─────┐ ┌─────▼────┐ ┌──────▼─────┐
   │ domain pkg │ │domain pkg│ │ domain pkg │   không import nhau
   └──────┬─────┘ └─────┬────┘ └──────┬─────┘
          └─────────────┼─────────────┘
                  ┌──────┴──────┐
             ┌────▼───┐   ┌─────▼────┐
             │bundle A│   │ bundle B │   preset lắp sẵn cho 1 role/tenant
             └────────┘   └──────────┘
```

- **core**: mọi package khác đều phụ thuộc. Không phụ thuộc ngược. Không import framework UI (Dart thuần) — core phải dùng được ở nơi không cần UI (ví dụ background service).
- **shared-ui**: phụ thuộc core, cung cấp app shell + token + widget nguyên thuỷ dùng chung. Domain package không tự vẽ lại primitive.
- **domain package** (tầng giữa): mỗi package = 1 tính năng/domain độc lập (booking, payment, map, chat...). **Không import lẫn nhau** — thứ 2 domain cùng cần thì đẩy xuống core/shared-ui. Lý do: consumer chỉ cần domain A không phải compile theo native layer của domain B (ví dụ consumer không cần bản đồ thì không kéo theo Google Maps SDK/geolocator).
- **bundle** (preset theo role/tenant): gộp sẵn N domain package + theme + route + permission cho 1 kiểu consumer (ví dụ "app cho end-user" vs "app cho worker"). Bundle **không chứa business logic riêng** — chỉ pin role, forward extension point, merge preset màn hình domain đưa lên (xem composition-and-session.md). Domain project không khớp preset nào có sẵn thì dùng thẳng domain package, không bắt buộc qua bundle.

## Vì sao không dùng workspace tool (melos, pnpm workspace...)

Khi package chỉ link bằng path dependency và không publish, workspace tool thêm 1 tool cài toàn cục + 1 bề mặt cấu hình thứ hai, đổi lại 1 vòng lặp "resolve từng package theo đúng thứ tự" mà 1 script vài dòng đã làm được. Chỉ cân nhắc workspace tool khi: publish lên registry riêng, hoặc số package quá lớn (>15-20) khiến script tay không còn quản nổi.

## Dependency hygiene

- Dependency bên thứ 3 mà **mọi** package con đều cần → khai đúng 1 lần ở core, KHÔNG khai lại ở package con (tránh version drift khi bump).
- Package con cần dùng type từ dependency đã khai ở core → core re-export **có chọn lọc** (`export 'package:x/x.dart' show TypeA, TypeB;`), không export cả package — export cả package là đường leak 3rd-party type lọt vào mọi widget tiêu thụ, đúng lỗi 1 SDK cũ tham chiếu đã mắc phải.
- Nếu ngôn ngữ/tool có lint kiểu "phải khai dependency trực tiếp mới được import" (`depend_on_referenced_packages` ở Dart) và nó chặn transitive import hợp lệ theo hygiene ở trên → tắt lint đó ở package con, giữ bật ở core (core là nơi duy nhất pubspec/package.json phải đầy đủ). Đánh đổi: 1 package thực sự thiếu dependency (không có ở core) sẽ fail ở bước resolve/install thay vì ở bước lint — lỗi vẫn xuất hiện, chỉ đổi chỗ.
- Trước khi thêm dòng dependency mới vào package con: grep file khai dependency của core trước — có rồi thì import thẳng, không thêm dòng trùng.
- 1 package chỉ khai dependency khi **có nơi import nó** — dependency khai mà không dùng vẫn cộng dồn chi phí build (native plugin kéo theo cấu hình platform, thời gian cài) cho mọi consumer.

## Khi nào tách 1 domain package mới

Tách khi: (a) domain đó có native plugin/dependency nặng mà consumer không cần nó không nên trả chi phí, hoặc (b) 1 domain sẽ được người khác/dự án khác tái dùng độc lập. Không tách "cho gọn" khi chỉ 1 consumer dùng — thêm 1 package là thêm 1 file cấu hình + 1 điểm phải nhớ trong dependency graph, không miễn phí.
