---
name: android-cli
description: "`android` CLI: create projects, install SDK, run apps, emulator, screenshots, inspect layout. Use when operating a device/emulator or building/running an APK."
---
# Android CLI Specialist

The `android` tool operates on projects, devices, SDK. The table below is a quick entry point; for flag details run `android help <command>`.

## Installation

If `android` is not in PATH, install per OS:
- Linux: `curl -fsSL https://dl.google.com/android/cli/latest/linux_x86_64/install.sh | bash`
- Mac Arm: `curl -fsSL https://dl.google.com/android/cli/latest/darwin_arm64/install.sh | bash`
- Mac Intel: `curl -fsSL https://dl.google.com/android/cli/latest/darwin_x86_64/install.sh | bash`
- Windows: `curl -fsSL https://dl.google.com/android/cli/latest/windows_x86_64/install.cmd -o "%TEMP%\i.cmd" && "%TEMP%\i.cmd"`

## Command → use when

| Command | Use when |
|---|---|
| `android init` | Required first-time setup before using other commands |
| `android sdk install/update/remove/list` | Install/remove/list SDK packages |
| `android create <template> --name= --output=` | Create a new Android project from a template |
| `android run` | Build, deploy, run the app on a device/emulator |
| `android emulator create/start/stop/list/remove` | Manage Android Virtual Devices |
| `android screen capture` | Capture the screen of the connected device |
| `android layout` | Return the UI layout tree as JSON, faster than screenshots when debugging UI |
| `android docs search "<keyword>"` | Search official Android docs (API, migration, best practices) |
| `android install` | Install an APK on a device/emulator |
| `android info` | Show the configured device/SDK info |
| `android update` | Update the CLI to the latest version |

## Device interaction & journey tests

- See [references/interact.md](references/interact.md) for device interaction (tap, input, adb...).
- See [references/journeys.md](references/journeys.md) to run journey tests.
