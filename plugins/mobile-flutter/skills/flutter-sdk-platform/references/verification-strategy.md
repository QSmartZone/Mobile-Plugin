# Verifying an SDK — details

## Pitfalls

- Treating `analyze` clean as done — analyze catches types and lints, not runtime behavior; the live preview step is required for anything that renders or calls the backend.
- A vague review checklist ("code is clean") — it must be concrete enough to say "grep pattern X must be empty".
- Rebuilding a fake backend in-repo to verify against — it only proves the SDK matches its own assumptions; use the real backend/staging or the contract document.

## Verify steps

1. **Resolve + analyze every package in dependency order** — a short script (no workspace tool needed, see package-layering.md) running `flutter pub get` + `flutter analyze` for each package, stopping at the first package that fails.
2. **Live preview on a host app** — run the consuming app (or the package's `example/` app) on a device/emulator, hot reload after each edit, and check the edited screen via `/mobile-flutter:verify` (runtime errors + widget tree). No host app yet → build a minimal `example/` app that wires the package with real config.
3. **A concrete review checklist** — lives with the SDK's skill/rule, grows whenever a bug slipped past the previous review; it is not written once and left alone.
4. **The review gate is the final safety net** — do not merge without passing review.
5. **Run against the real backend/staging at the first opportunity** — expect a round of rework then; it is not a sign the SDK was built wrong earlier.

## Trade-offs to state plainly to the decision maker

- Regressions in complex internal logic (interceptor ordering, bloc/reducer state transitions, async race conditions) are caught only by review or by exercising the flow live.
- Live preview covers the flows someone actually opened; flows nobody exercised are unverified — list which flows were checked in the report.
