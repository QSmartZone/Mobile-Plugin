# Project structure

## Feature-first (React Navigation, not Expo Router)

```
src/
├── app/                  # entry, providers (QueryClient, ThemeProvider, NavigationContainer)
├── features/
│   ├── auth/
│   │   ├── screens/      # LoginScreen.tsx, SignupScreen.tsx
│   │   ├── components/   # components specific to the auth feature
│   │   ├── hooks/        # useLogin.ts
│   │   ├── api/          # authApi.ts — calls the auth backend
│   │   └── types.ts
│   └── cart/
│       ├── screens/
│       ├── components/
│       └── store/        # cartStore.ts (Zustand)
├── shared/
│   ├── components/       # Button, Card... shared across features
│   ├── hooks/             # useDebounce, useAppState...
│   └── theme/
├── navigation/            # RootNavigator.tsx, types.ts (param list)
└── lib/                   # apiClient.ts, storage.ts — wrappers for external libraries
```

Do not gather all components into one flat app-level `components/` directory — as features grow, finding which feature a component belongs to becomes laborious. Put a component in `shared/components` only when it is truly used by ≥2 features.

## Expo Router (file-based routing)

The `app/` structure also determines the routes — it is not separate from `navigation/` as in plain React Navigation. Business logic (hooks, api, non-screen components) should still be split out to `src/features/` so `app/` contains only thin route-definition files that import from features.

```
app/
├── (auth)/
│   ├── login.tsx          # route /login — imports logic from src/features/auth
│   └── signup.tsx
├── (tabs)/
│   ├── home.tsx
│   └── profile.tsx
└── _layout.tsx
src/
└── features/
    └── auth/
        ├── hooks/useLogin.ts
        └── components/LoginForm.tsx
```

## Principles

- Name component files `PascalCase.tsx`, hooks `useXxx.ts`, everything else `camelCase.ts` — follow the convention already in the repo if it differs.
- 1 file, 1 main export (component or hook) — easy to find, avoids "convenience" files that gather unrelated things.
- Barrel files (`index.ts` re-exports) only at the feature/shared level; do not nest barrel files in multiple layers, which causes hard-to-debug circular imports.
- Custom native code (if any, bare workflow) lives in `ios/`/`android/`; the JS/TS side calls it through a wrapper in `src/lib/`, not importing native modules directly across components.
