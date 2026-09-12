# Performance — chi tiết

## Đo trước, tối ưu sau

Chỉ tối ưu khi có bằng chứng cụ thể (Flutter DevTools → Performance/Timeline, hoặc người dùng report giật thật) — tối ưu đoán mò thường làm code khó đọc hơn mà không giải quyết đúng chỗ nghẽn thật.

## `ListView.builder`/`GridView.builder` cho danh sách dài

`ListView(children: [...])` build toàn bộ children ngay khi widget dựng, kể cả phần chưa hiện trên màn hình — với danh sách dài (hàng trăm item trở lên) gây giật lúc mở màn hình. `.builder` chỉ build item đang/ sắp hiện trong viewport.

## Tác vụ nặng CPU ra khỏi main isolate

Parse JSON lớn, decode/resize ảnh, thuật toán tính toán nặng chạy trên main isolate sẽ chặn frame rendering (giật animation, input lag) vì Flutter chỉ có 1 isolate xử lý UI. Dùng `compute()` hoặc `Isolate.run()` để đẩy việc đó sang isolate riêng.

## Rebuild thừa

`Selector` (Provider), `BlocSelector`/`context.select` (Bloc/Riverpod) giúp 1 widget chỉ rebuild khi đúng phần state nó cần thay đổi, thay vì rebuild toàn bộ mỗi khi state cha đổi. Chỉ thêm khi profiler chỉ ra rebuild thừa thật sự gây giật — thêm mặc định ở mọi nơi tăng độ phức tạp code mà không có lợi ích đo được.

`const` constructor (đã nêu ở Nguyên tắc cốt lõi trong SKILL.md) là bước đầu tiên và rẻ nhất trước khi cần tới `Selector`/`BlocSelector`.

## Ảnh

Dùng đúng kích thước cần hiển thị (`cacheWidth`/`cacheHeight` trên `Image`, hoặc resize ảnh trước khi upload) — load ảnh full-resolution để hiển thị thumbnail nhỏ tốn bộ nhớ decode gấp nhiều lần kích thước thật cần, dễ gây OOM trên danh sách ảnh dài (feed, gallery).

## Bẫy cụ thể

- Gọi API hoặc tính toán nặng ngay trong `build()` — `build()` có thể chạy lại nhiều lần (mỗi lần rebuild), khiến lời gọi lặp lại không cần thiết. Đưa ra `initState`, bloc/notifier, hoặc memoize kết quả.
- Dùng `Opacity` cho hiệu ứng tĩnh không đổi theo thời gian — widget này có thể tốn 1 layer compositing riêng tuỳ engine; nếu không animate, cân nhắc thiết kế UI để không cần nó ở subtree lớn.
- Impeller là renderer mặc định trên iOS và Android hiện tại — đo chi phí compositing thật bằng DevTools Performance thay vì suy đoán theo hành vi renderer cũ.
