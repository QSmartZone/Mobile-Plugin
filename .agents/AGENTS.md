# mobile-dev — always-on

Plugin `mobile-dev`. Root = thư mục chứa `rules/`, `agents/`, `skills/`.

Routing theo file đang chạm → skill:

| File / việc | Skill |
| --- | --- |
| `*.dart`, `pubspec.yaml` | `flutter-dev` (kèm `rules/hot_reload.md` sau mỗi lần sửa) |
| Thiết kế/tái cấu trúc SDK Flutter đa package, white-label nhiều tenant | `flutter-sdk-platform` |
| `*.kt`, `*.java` (module Android) | `android-native-dev` |
| `*.swift`, `*.storyboard`, `*.xib` | `ios-dev` |
| Cần chạy/build/debug thiết bị Android, chụp screenshot, xem layout | `android-cli` |
| `*.tsx`, `*.jsx` (React Native project — có `metro.config.js`/`app.json` Expo) | `react-native-dev` |

Không có tool hỏi có cấu trúc → hỏi thẳng trong chat, gom ≤4 câu/lượt.
