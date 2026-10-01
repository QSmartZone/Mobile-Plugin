# Troubleshoot

| Symptom | Check command | Fix |
| --- | --- | --- |
| Metro serves old code / ignores changes | `npx react-native start --reset-cache` | Stale cache; if it persists: `watchman watch-del-all` |
| Pod install fails/missing iOS dependency | `cd ios && pod install --repo-update` | Update the CocoaPods repo before retrying |
| Gradle build fails after RN upgrade | `cd android && ./gradlew clean` | Clear the Gradle build cache, then rebuild |
| "Unable to resolve module ..." | `rm -rf node_modules && rm -f package-lock.json yarn.lock` | Reinstall dependencies cleanly |
| Expo SDK version mismatch between libs | `npx expo-doctor` | `npx expo install --fix` to align versions with the SDK |
| App on a real device cannot see Metro | `adb devices` | `adb reverse tcp:8081 tcp:8081` (Android USB) |
| Vague crash, suspect an old native lib without Hermes support | `npx react-native info` | Check the lib changelog, update or report upstream |
| Native lib lacks New Architecture support, crashes on build | `npx react-native info` | RN < 0.82: temporarily set `newArchEnabled=false` in `gradle.properties`, state clearly this is a temporary workaround. RN ≥ 0.82: legacy architecture is removed, must update/replace the lib |
