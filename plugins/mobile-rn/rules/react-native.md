---
trigger: glob
globs: ["**/*.tsx", "**/*.jsx", "**/app.json", "**/app.config.js", "**/metro.config.js"]
description: General React Native rules
---

# React Native — general rules

**Inspect the project first:**
- Read `package.json`, `app.json`/`app.config.js` (Expo or bare), `tsconfig.json` before editing.
- Follow the existing state/navigation/fetch libs (`zustand`/`redux`, `@react-navigation`/`expo-router`, `@tanstack/react-query`). Do not propose a new lib when an existing one suffices.

**Keep the architecture:**
- Do not switch Expo↔bare, change the navigation lib, or change the state lib unless explicitly requested.

**Network errors:**
- Components do not call `fetch`/axios directly; go through a service/hook.
- Distinguish network errors, HTTP status (`fetch` does not throw on 4xx/5xx — check `res.ok`), parse errors, business errors.
- Do not swallow promise rejections, do not push raw error messages to the UI.

**UI baseline:**
- Touch target ≥44pt (iOS)/48dp (Android), use `hitSlop` for small icons; `accessibilityLabel` + `accessibilityRole` for icon-only Pressables.
- TypeScript: no `!` non-null assertion or `as any` when unsure of the type.

**Hot reload:**
- Metro applies Fast Refresh on file save. Metro not running → tell the user in 1 line, keep editing code.

**Out of scope:**
- New native module, new Expo config plugin, app-wide state lib change → stop, state the reason.

**Verify before reporting done:**
- `npx tsc --noEmit` + `npx eslint <edited file>`.
- Live preview: Metro running + app open on an emulator/simulator → Fast Refresh → open the edited screen; check Metro output and the screen for red box/LogBox errors. Screenshot: Android `android screen capture` (skill `mobile-android:android-cli`, if installed), iOS `xcrun simctl io booted screenshot`.
- No device/emulator available → say so in 1 line.
- Paste the verify output into the report.
