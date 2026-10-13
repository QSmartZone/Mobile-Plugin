# Package layering — details

Reference: ADR "SDK ships as N path-linked packages, without a workspace tool" + ADR "headless domain packages with injected dependencies".

## Standard Architecture: Headless Feature Modules

In a clean, modern multi-package Flutter SDK, the SDK contains **only headless feature packages** with no UI, no Flutter Blocs, and no routing:

```
sdk/ (Headless Domain Modules)
  ├── <prefix>_auth (session, tokens, interceptor, biometric seam)
  ├── <prefix>_booking (booking API, repository, realtime transport)
  ├── <prefix>_map (location, geocoding, places behind provider seams)
  ├── <prefix>_payment (payment API seam, payment providers)
  └── <prefix>_notification (notification provider seam, streams)
       ▲              ▲              ▲
       │              │              │ path dependencies
┌──────┴──────────────┴──────────────┴──────┐
│ App / Shared App Shell Layer              │
│ (e.g. core shell + customer/role apps)   │
│ - Wires modules in di.dart                │
│ - Injects Dio (authorizedDio from auth)   │
│ - Holds design system, UI, Blocs, fakes   │
└───────────────────────────────────────────┘
```

### Core Invariants

1. **Strictly Headless**: No widgets, themes, routers, or Blocs live in `sdk/`. App shells and consumer apps own all UI and state management.
2. **Zero Cross-SDK Imports**: Sibling SDK packages never import each other (e.g. `booking` never imports `auth` or `map`). Each module stays standalone and lightweight.
3. **Injected Dependencies via Config**: Modules accept dependencies (HTTP client `Dio`, baseUrl, session token getters, callbacks) from the consuming app at startup via a typed `Config` class (e.g. `BookingConfig`, `MapConfig`).
4. **Typed Result Boundaries**: All public API methods return `ResultDart<T, ModuleFailure>` (or equivalent typed result). Never throw uncaught exceptions across the module boundary.
5. **App Shell Ownership**: Role-specific flows, screens, forms, tabs, and navigation logic live entirely in the application layer, keeping the SDK domain pure and reusable.

## Workspace Management: Path Dependencies

When packages are linked in a monorepo via path dependencies and not published to a public registry, keep the build system simple:
- Use direct `path:` dependencies in `pubspec.yaml` (e.g. `path: ../../sdk/<module>`).
- A lightweight shell script (e.g. `./clean_flutter.sh` running `flutter pub get` in dependency order) is preferred over heavy monorepo management tools (melos, etc.).
- Avoid extra configuration layers unless publishing to a private registry or managing >15-20 packages.

## Dependency Hygiene

- **Minimal Surface**: A headless package declares a dependency only when something inside it directly imports that dependency. Unused dependencies add unnecessary native and compile-time overhead.
- **Export Control**: Re-export external types selectively (`export '...' show TypeA;`) rather than exposing entire third-party libraries. This prevents third-party API types from leaking into consumers.
- **No Native Leaks**: If a domain does not require native device capabilities (e.g. pure HTTP/JSON domain), keep it pure Dart so consumers do not pay native build overhead.

## When to Split Out a New Package

Split a feature into a new SDK package when:
1. The domain has heavy dependencies or native plugins (e.g. maps, geolocators, biometrics) that consumers who do not use the feature should not have to compile.
2. The domain is genuinely shared and reused across multiple distinct applications.

Avoid splitting packages prematurely for trivial helper functions or features used by only one application.
