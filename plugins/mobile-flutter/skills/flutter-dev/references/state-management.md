# State management — details

## setState

Use for state that does not leave a single widget and whose direct descendants do not need to read it. Examples: dropdown open/closed, slider value while dragging, current page of a `PageView`.

```dart
class _CounterState extends State<Counter> {
  int _count = 0;
  void _increment() => setState(() => _count++);
}
```

Common mistake: calling `setState` in `build()` or in an async callback after the widget is disposed — always check `mounted` before `setState` after an `await`.

## Provider / InheritedWidget

Use when a few descendant widgets (not too deep) need to read a shared value, without complex business logic. `Provider.of<T>(context, listen: false)` for actions, `context.watch<T>()` to rebuild on changes.

## Bloc

Use when:
- Business logic has several clear states (loading/success/error/empty) that need testing independently of the UI.
- Complex async flows (debounce, race conditions between many events).

Simple state, no need to transform/debounce events → use `Cubit` (methods called directly, no separate event class). Need separate event classes, event stream transforms (debounce, race conditions) → use `Bloc`. Follow whichever the project already uses; do not switch between the 2 patterns within the same feature.

```dart
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState { final User user; AuthSuccess(this.user); }
class AuthError extends AuthState { final String message; AuthError(this.message); }
```

## Riverpod

Replaces Provider when you need: compile-time safety (no runtime `ProviderNotFoundException`), easy testing (override providers in tests), or auto-disposing state that is no longer used.

## Selection principle — avoid mixing

Do not use 2 different state solutions for the same data flow within a feature (for example both Bloc and Provider for the same screen) — it raises code-reading cost without raising benefit. If the project has chosen one solution in `pubspec.yaml`, follow it; do not add a new state management lib that is not already in the dependencies.
