# Cấu trúc dự án

## Feature-first (React Navigation, không Expo Router)

```
src/
├── app/                  # entry, providers (QueryClient, ThemeProvider, NavigationContainer)
├── features/
│   ├── auth/
│   │   ├── screens/      # LoginScreen.tsx, SignupScreen.tsx
│   │   ├── components/   # component riêng của feature auth
│   │   ├── hooks/        # useLogin.ts
│   │   ├── api/          # authApi.ts — gọi backend auth
│   │   └── types.ts
│   └── cart/
│       ├── screens/
│       ├── components/
│       └── store/        # cartStore.ts (Zustand)
├── shared/
│   ├── components/       # Button, Card... dùng chung nhiều feature
│   ├── hooks/             # useDebounce, useAppState...
│   └── theme/
├── navigation/            # RootNavigator.tsx, types.ts (param list)
└── lib/                   # apiClient.ts, storage.ts — wrapper thư viện ngoài
```

Không gom toàn bộ component vào 1 thư mục `components/` phẳng cấp app — khi feature lớn dần, tìm component thuộc feature nào trở nên mất công. Chỉ đặt vào `shared/components` khi component thật sự dùng ở ≥2 feature.

## Expo Router (file-based routing)

Cấu trúc `app/` quyết định luôn route — không tách rời `navigation/` như React Navigation thuần. Logic nghiệp vụ (hook, api, component không phải screen) vẫn nên tách ra `src/features/` để `app/` chỉ chứa file định nghĩa route mỏng, import từ feature.

```
app/
├── (auth)/
│   ├── login.tsx          # route /login — import logic từ src/features/auth
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

## Nguyên tắc

- Đặt tên file component `PascalCase.tsx`, hook `useXxx.ts`, còn lại `camelCase.ts` — theo đúng convention đã có trong repo nếu khác.
- 1 file 1 export chính (component hoặc hook) — dễ tìm, dễ test, tránh file "tiện tay" gom nhiều thứ không liên quan.
- Barrel file (`index.ts` re-export) chỉ ở cấp feature/shared, không lồng barrel file nhiều tầng gây vòng import khó debug.
- Native code custom (nếu có, bare workflow) nằm trong `ios/`/`android/`, JS/TS side gọi qua wrapper trong `src/lib/`, không import trực tiếp native module rải rác trong component.
