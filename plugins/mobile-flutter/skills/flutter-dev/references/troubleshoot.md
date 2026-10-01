# Troubleshoot Flutter — details

| Symptom | Check command | Fix |
| --- | --- | --- |
| `pub get` hangs | watch the log, wait a few seconds | `flutter pub get --offline` if the cache is available, or check proxy/firewall |
| Version solving failed | read the dependency conflict in the log | edit the version constraint in `pubspec.yaml` per the reported conflict |
| Odd build, stale cache | compare the error with current code | `flutter clean` then `flutter pub get` again |
| CocoaPods error (ios/) | read the `pod install` error | `pod repo update` then `pod install --repo-update` in `ios/` |
| Gradle JDK mismatch | `flutter doctor -v` | `flutter config --jdk-dir <path>` pointing to the JDK Gradle needs |
| Xcode signing on simulator | build on simulator, not a physical device | running on a simulator needs no signing; ignore unless building for a real device |
| "No devices" | `flutter devices` | `flutter emulators --launch <id>` or plug in a device/open a simulator |
| Hot reload not applying | what changed most recently (const/initState/enum) | changing `const`, `initState`, enum → needs hot **restart**, not reload |
