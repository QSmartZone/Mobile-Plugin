---
name: react-native-dev
description: "React Native conventions: Expo vs bare, state, navigation, performance, native modules. Use when touching RN .tsx/.jsx, app.json/app.config.js. Not for web React."
---

# React Native Dev Specialist

Read `rules/react-native.md` at the plugin root first. Claude Code: `${CLAUDE_PLUGIN_ROOT}/rules/react-native.md`.

## Inspect the project first

| If you see | Conclusion |
| --- | --- |
| `expo` + `app.json`, no `ios/`/`android/` | Managed Expo |
| Has `ios/`/`android/` | Bare workflow (or already prebuilt) |
| Has an `app/` directory | Expo Router |
| State lib already in `package.json` | Use that exact lib |

## Commonly wrong decisions

- TypeScript by default; no `any`.
- Extract complex logic into custom hooks.
- Long lists use `FlatList`/`FlashList`, not `.map()`.
- Do not memoize before measuring unnecessary rebuilds.
- Do not hand-roll server state caching — use React Query if already chosen.
- Do not write a new native module when Expo/community already covers it.
- RN/Expo deprecation facts change fast — verify official docs before asserting.

## State management

| Need | Choose |
| --- | --- |
| Local state in 1 component | `useState`/`useReducer` |
| Share across a few nearby components | Context API |
| Large app, many async flows | Zustand or Redux Toolkit |
| Server state (fetch/cache API) | React Query (TanStack Query) |

Details: [references/state-management.md](references/state-management.md).

## References

[expo-vs-bare](references/expo-vs-bare.md) · [project-structure](references/project-structure.md) · [navigation](references/navigation.md) · [api-integration-error-handling](references/api-integration-error-handling.md) · [performance](references/performance.md) · [ui-adaptive-accessibility](references/ui-adaptive-accessibility.md) · [native-modules](references/native-modules.md) · [troubleshoot](references/troubleshoot.md)

## Verify

- `tsc --noEmit` clean.
- `eslint` clean, no arbitrary rule disabling.
- Live preview: Fast Refresh on the running app, open the edited screen, no red box/LogBox error.
- `npx expo run:ios|android` or `npx react-native run-android` when touching native.
