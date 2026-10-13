# Verifying an SDK — details

## Pitfalls

- Treating `analyze` clean as done — analyze catches types and lints, not runtime behavior; the live preview step is required for anything that renders or calls the backend.
- A vague review checklist ("code is clean") — it must be concrete enough to say "grep pattern X must be empty".
- Rebuilding a fake backend in-repo to verify against — it only proves the SDK matches its own assumptions; use the real backend/staging or the contract document.

## Commands by usecase
 
| Usecase | Command / Tool | Note |
| --- | --- | --- |
| Lint / Static analysis across SDK packages | `flutter analyze` in each package directory | Stops at first failure; run in dependency order |
| Dev loop: Live preview & test features | `flutter run --dart-define-from-file=<env>` | Directly on device/emulator; never use `flutter build` |
| Hot reload during active development | `hot_reload` (Dart MCP) | Immediate UI update |
| Reset state / configuration changes | `hot_restart` (Dart MCP) | Reloads app without rebuild |
| Validate UI rendering | `widget_inspector` (Dart MCP) | Confirms widget tree structure |
| Catch runtime crashes & exceptions | `get_runtime_errors` (Dart MCP) | Clear errors before test, read after |
| Multi-package cache & resolve reset | `./clean_flutter.sh` (or `flutter clean && flutter pub get`) | Cleans and re-resolves all packages |
| Release build generation | `flutter build apk` / `flutter build appbundle` | **Only** for artifact distribution |

## Trade-offs to state plainly to the decision maker

- Regressions in complex internal logic (interceptor ordering, bloc/reducer state transitions, async race conditions) are caught only by review or by exercising the flow live.
- Live preview covers the flows someone actually opened; flows nobody exercised are unverified — list which flows were checked in the report.
