# mobile-dev — always-on

Plugin `mobile-dev` (merged bundle of the packs chosen at `install.sh --pack`). Root = the directory containing `rules/`, `agents/`, `skills/`. A skill missing from `skills/` means its pack is not installed; ignore that row.

Read the rule for the platform of the file you are touching first: `rules/flutter.md`, `rules/android.md`, `rules/ios.md`, `rules/react-native.md` (only files of installed packs exist).

Routing by touched file → skill. Verify by live preview on a device/emulator/simulator. Flutter: workflow `verify` (analyze + live preview via Dart MCP).

| File / task | Skill |
| --- | --- |
| `*.dart`, `pubspec.yaml` | `flutter-dev` (plus `rules/hot_reload.md` after every edit) |
| Designing/restructuring a multi-package Flutter SDK, multi-tenant white-label | `flutter-sdk-platform` |
| `*.kt`, `*.java` (Android module) | `android-native-dev` |
| `*.swift`, `*.storyboard`, `*.xib` | `ios-dev` |
| Running/building/debugging an Android device, taking screenshots, inspecting layout | `android-cli` |
| `*.tsx`, `*.jsx` (React Native project — has `metro.config.js`/`app.json` Expo) | `react-native-dev` |

No structured-question tool → ask directly in chat, batching ≤4 questions per turn.
