# Native module / platform code

## Write one only when truly needed

Before writing a native module, check whether Expo SDK or a community package (react-native-community, or a popular well-maintained lib) already covers that native API — a hand-written native module is a long-term maintenance cost (you must track OS changes and verify on both platforms yourself).

## Old bridge vs JSI/TurboModules/Fabric

The new architecture (New Architecture: TurboModules for native modules, Fabric for native UI components) uses JSI (JavaScript Interface) to call C++ directly between JS and native, without the async bridge that serializes JSON like the old architecture — faster, and type-safe thanks to codegen from the TypeScript spec.

```ts
// TurboModule spec (TypeScript) — codegen creates the native interface from here
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  getBatteryLevel(): Promise<number>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('BatteryModule');
```

React Native 0.68-0.75 offers New Architecture as an experimental opt-in, not the default and not yet broadly stable; from 0.76 (10/2024) New Architecture became the default for new projects. Check `newArchEnabled` in `gradle.properties`/`Podfile` before writing a new module; write it as a TurboModule/Fabric instead of the old bridge (`NativeModules`/`requireNativeComponent`) if the project already enabled New Architecture, to avoid migrating again later.

The old bridge (`NativeModules`) remains in projects that have not migrated to New Architecture — do not migrate a single module to TurboModule on your own while the rest of the app still uses the old bridge; it easily causes runtime conflicts.

## Expo Modules API — the way to write native modules in the Expo ecosystem

For Expo projects (including prebuilt ones), prefer the Expo Modules API over a hand-written TurboModule — the API is simpler and integrates autolinking and config plugins automatically.

```kotlin
// android: ExampleModule.kt
class ExampleModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExampleModule")
    AsyncFunction("getBatteryLevel") {
      // read native battery level
    }
  }
}
```

## Config plugin

When a native module needs changes to `Info.plist`/`AndroidManifest.xml`/Podfile and you do not want to edit them by hand (lost on re-prebuild), write a config plugin shipped with the module — the plugin runs during `expo prebuild` to patch the native files automatically.

## Principles

- Wrap the native module in a JS/TS service layer (`src/lib/battery.ts`) — UI calls through the wrapper, not importing `NativeModules.BatteryModule` directly across many components, so changing the implementation later does not require edits in many places.
- Verify a native module by running the app on both platforms (iOS simulator + Android emulator) and calling it from the edited screen.
- Runtime permissions (camera, location, notification...) always go through the permission API built into each Expo module (`expo-camera`, `expo-location`... each has its own request/check permission functions) for managed workflow, or `react-native-permissions` for bare workflow. Check the status before calling an API that needs permission; do not assume the permission is granted.
