# Testing

## Jest + React Native Testing Library — unit/component test

Test behavior (what the user sees, what they interact with) rather than implementation details (internal state, private function names) — use queries by role/text/label the way a real user finds elements.

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

test('shows an error when submitting an empty form', () => {
  render(<LoginForm />);
  fireEvent.press(screen.getByRole('button', { name: 'Log in' }));
  expect(screen.getByText('Email must not be empty')).toBeOnTheScreen();
});
```

Test a non-trivial custom hook (branch, loop, complex computation) via `renderHook` from the same library; no need to mount a whole component just to test hook logic.

```tsx
import { renderHook, act } from '@testing-library/react-native';

test('useToggle flips the value when toggle is called', () => {
  const { result } = renderHook(() => useToggle(false));
  act(() => result.current[1]());
  expect(result.current[0]).toBe(true);
});
```

## Mock native modules

Mock native modules (camera, location, storage...) in `jest.setup.js` or per test; do not let tests call real native code (it will crash/hang in the Jest node environment). Expo SDK ships the `jest-expo` preset, which mocks most Expo modules by default.

```ts
jest.mock('expo-location', () => ({
  getCurrentPositionAsync: jest.fn().mockResolvedValue({ coords: { latitude: 0, longitude: 0 } }),
}));
```

## E2E: Detox or Maestro

Only for critical user flows (login, checkout, the app's main flow) — not required for every PR because maintenance cost and run time are far higher than unit tests.

- **Detox**: deeply tied to the build process (needs a separate app build for tests), fine-grained control, syncs well with animation/network idle — fits teams that already invested in dedicated E2E CI.
- **Maestro**: simple YAML flows, no special build needed, runs on a regular built app — fits quick setup with less maintenance than Detox.

```yaml
# maestro: login-flow.yaml
appId: com.myapp
---
- launchApp
- tapOn: "Email"
- inputText: "user@example.com"
- tapOn: "Log in"
- assertVisible: "Home"
```

## Principles

- Every bug fix needs 1 test that reproduces the bug before the fix (regression test); do not just edit code and skip the test.
- Use snapshot tests selectively — snapshotting the whole UI easily becomes reflexive "update snapshot" without really reviewing what changed; prefer specific assertions over large snapshots.
- Tests must not depend on run order or leftover global state from a previous test — each test sets up/cleans up itself (`beforeEach`/`afterEach`).

## Running tests correctly

- Run exactly the file/test needed: `npx jest path/to/file.test.tsx -t "test name"`; do not run the whole suite when only one place changed.
- Read the first `●` failure line in the output — that is the assertion that is really wrong; later lines are usually consequences.
- Do not use `--watch` in an agent/CI — the process never exits and hangs the session.
- Run Detox/Maestro only when the change touches a critical E2E flow, not by default on every code edit.
- Odd transform/module errors unrelated to the code you just edited → try `npx jest --clearCache` before debugging deeper.
