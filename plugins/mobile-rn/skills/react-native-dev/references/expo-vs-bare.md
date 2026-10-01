# Expo vs bare workflow

## Managed Expo (the recommended default)

Choose managed workflow when the app needs no custom native code beyond what Expo SDK + community config plugins already cover (camera, location, notification, in-app purchase, biometric... all have an official Expo package or config plugin). Benefits: builds via EAS Build without local Xcode/Android Studio, OTA updates via `expo-updates`, SDK version upgrades have a clear path.

```json
// app.json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "plugins": [
      "expo-camera",
      ["expo-location", { "locationAlwaysAndWhenInUsePermission": "Allow the app to use location." }]
    ]
  }
}
```

Signs a project is in managed workflow: `expo` in `dependencies`, has `app.json`/`app.config.js`, NO committed `ios/`/`android/` directories in the repo (these are generated at build time and do not live in source control).

## Bare workflow / Expo prebuild

Needed when:
- A native module has no Expo SDK equivalent and no community config plugin.
- Deep custom native code (Swift/Kotlin) that a config plugin cannot expose (editing `AppDelegate`, complex custom `Info.plist` keys, linking a third-party native SDK that requires hand-editing the Podfile).
- Migrating an old React Native CLI app that already has custom `ios/`/`android/`.

With Expo you do not have to fully "eject" — run `npx expo prebuild` to generate `ios/`/`android/` from config, keeping most Expo tooling (EAS Build, most Expo SDK APIs). `npx react-native init` is deprecated since RN 0.75, use `npx @react-native-community/cli init` for a pure bare project; new projects should usually start with `npx create-expo-app` and prebuild when needed, instead of initializing bare from the start.

```bash
npx expo prebuild        # generate ios/ android/ from app.json + plugins
npx expo prebuild --clean # regenerate cleanly when changing plugins/native config
```

## Decision rules

1. Keep managed workflow as long as possible by default — each prebuild means maintaining native code yourself instead of letting Expo handle it.
2. Before prebuilding because "we need library X", check whether Expo SDK or `npx expo install X` provides a config plugin — many popular libraries (Firebase, Stripe, Sentry...) already have an official plugin, no bare needed.
3. After prebuild, the `ios/`/`android/` directories become the source of truth for the native part — changing `app.json` no longer syncs automatically unless you re-run `prebuild`; beware of drift between config and hand-edited native code.
4. Do not mix: if the team has decided on bare workflow and has hand-written native code in `ios/`/`android/`, do not propose going back to managed — that code would be lost.
