# Testing Flutter — details

**Project policy overrides every section below.** Read the project's `AGENTS.md`/`CLAUDE.md` first: tests forbidden → do not write them, do not run `flutter test`; verify with `/verify` (analyze + live preview).

## Widget test

Tests UI behavior without a real device/emulator, runs fast in CI.

```dart
testWidgets('tap increments counter', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

Use `find.byKey(const Key('...'))` for widgets repeated many times (list items) instead of `find.text`, which easily collides.

## Golden test

Compares the rendered screenshot against an approved baseline image — catches visual regressions (spacing, color, font) that widget tests usually miss (because widget tests only check the tree/text, not pixels).

```dart
await expectLater(find.byType(MyCard), matchesGoldenFile('my_card.png'));
```

Only add golden tests for high-risk UI (design system components, checkout screen) — golden tests break easily when font/OS version changes, so do not cover the whole app.

## Unit test for non-trivial logic

Bloc, use case, parser, JSON→model mapper: test separately from widgets, use `bloc_test` for Bloc to assert the correct order of emitted states.

## Integration test

Use the `integration_test` package, runs on a real device/emulator — for the end-to-end golden path (login → create booking → payment). Running cost is much higher than widget tests; cover only the most important flows, not a replacement for widget tests.

## Running tests correctly (only when the project allows)

- Run 1 file: `flutter test test/x_test.dart` — do not run the full suite when only one spot changed.
- Run 1 specific case: `flutter test test/x_test.dart --plain-name "test name"`.
- Test fails: read the first failing line + expected/actual; do not guess the cause from the test name.
- Full suite (`flutter test`) only when the user explicitly asks.
- Do not run `integration_test` when only changing pure logic (no UI flow/real device change).

## Principles (when the project allows tests)

Bug fix where a branch/loop/parser is faulty → write at least 1 test reproducing the bug before fixing (fail → fix → pass). Do not write tests for getters/setters/static UI without logic.

## Minimum test level by risk, not a fixed count

- Logic with branches/loops/parsing/computation (business logic in bloc/notifier, validators, JSON→model mappers) → always needs a unit test or `bloc_test`, regardless of whether the team has a coverage % rule — this is where silent bugs cause real consequences.
- Pure display UI with no logic branching → no mandatory per-widget test; spend test-writing time on the higher-risk areas above.
- Do not infer a specific coverage % requirement if the project has not set one itself (CI check, its own convention file) — imposing a hard number without grounds from the project itself easily becomes a formal barrier instead of catching real bugs.
