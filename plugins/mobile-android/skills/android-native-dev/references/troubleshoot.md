# Android troubleshooting — details

| Symptom | Check command | Fix |
|---|---|---|
| Gradle sync fails (AGP/Kotlin/KSP/JDK mismatch) | `./gradlew --version`, see `libs.versions.toml` | Align AGP/Kotlin/KSP versions per the official compatibility table, match the JDK toolchain |
| Vague build error, unclear cause | `./gradlew <task> --stacktrace --info` | Read the detailed stacktrace/log instead of guessing |
| Gradle daemon hangs, build makes no progress | `./gradlew --status` | `./gradlew --stop` then rebuild |
| Emulator does not boot | `emulator -list-avds`, `adb devices` | Cold boot the AVD again (wipe snapshot), increase AVD RAM/disk if needed |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` on install | `adb shell pm list packages \| grep <id>` | `adb uninstall <package>` then install again |
| Crash only in the release build, debug runs fine | Compare debug vs release logs | Add/fix R8/ProGuard keep rules for the stripped class |
| Need the log of just the app being debugged | `adb shell pidof -s <package>` | `adb logcat --pid=$(adb shell pidof -s <package>)` |
| Native lib crash only on Android 15 (API 35) | Check whether the device uses 16KB page size | Rebuild the native lib (NDK) with 16KB page size support |
