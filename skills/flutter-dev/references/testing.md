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

Bloc/Cubit, use case, parser, mapper JSON→model: test tách khỏi widget, dùng `bloc_test` cho Bloc/Cubit để assert đúng thứ tự state emit.

## Integration test

Dùng package `integration_test`, chạy trên thiết bị/emulator thật — cho golden path end-to-end (login → tạo booking → thanh toán). Chi phí chạy cao hơn nhiều so với widget test, chỉ cover flow quan trọng nhất, không thay thế widget test.

## Nguyên tắc

Bug fix có branch/loop/parser bị lỗi → viết ít nhất 1 test tái hiện lỗi trước khi fix (fail → fix → pass). Không viết test cho getter/setter/UI tĩnh không logic.
