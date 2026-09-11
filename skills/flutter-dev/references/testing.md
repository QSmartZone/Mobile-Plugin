# Testing Flutter — chi tiết

## Widget test

Test hành vi UI mà không cần thiết bị/emulator thật, chạy nhanh trong CI.

```dart
testWidgets('tap increments counter', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

Dùng `find.byKey(const Key('...'))` cho widget lặp lại nhiều lần (list item) thay vì `find.text` dễ trùng.

## Golden test

So sánh screenshot render với ảnh baseline đã duyệt — bắt được regression visual (spacing, màu, font) mà widget test thường không phát hiện (vì widget test chỉ check tree/text, không check pixel).

```dart
await expectLater(find.byType(MyCard), matchesGoldenFile('my_card.png'));
```

Chỉ thêm golden test cho UI có risk cao (design system component, màn hình checkout) — golden test dễ vỡ khi đổi font/OS version, không nên phủ toàn bộ app.

## Unit test cho logic non-trivial

Bloc, use case, parser, mapper JSON→model: test tách khỏi widget, dùng `bloc_test` cho Bloc để assert đúng thứ tự state emit.

## Integration test

Dùng package `integration_test`, chạy trên thiết bị/emulator thật — cho golden path end-to-end (login → tạo booking → thanh toán). Chi phí chạy cao hơn nhiều so với widget test, chỉ cover flow quan trọng nhất, không thay thế widget test.

## Nguyên tắc

Bug fix có branch/loop/parser bị lỗi → viết ít nhất 1 test tái hiện lỗi trước khi fix (fail → fix → pass). Không viết test cho getter/setter/UI tĩnh không logic.

## Mức test tối thiểu theo risk, không phải số lượng cố định

- Logic có branch/loop/parse/tính toán (business logic trong bloc/notifier, validator, mapper JSON→model) → luôn cần unit test hoặc `bloc_test`, bất kể team có quy định coverage % hay không — đây là chỗ lỗi im lặng gây hậu quả thật.
- UI thuần hiển thị dữ liệu, không rẽ nhánh logic → không bắt buộc test riêng cho từng widget; ưu tiên thời gian viết test cho chỗ risk cao hơn ở trên.
- Không tự suy ra yêu cầu coverage % cụ thể nếu project chưa tự quy định (CI check, file convention riêng) — áp con số cứng khi chưa có căn cứ từ chính dự án dễ biến thành rào cản hình thức thay vì bắt lỗi thật.
