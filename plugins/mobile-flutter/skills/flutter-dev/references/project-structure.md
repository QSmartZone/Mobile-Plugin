## Layout: Application vs Headless SDK Module

### 1. Application Layout (Consumer / Client Apps)
Feature folders sit directly under `lib/` (or `lib/src/`), avoiding unnecessary nested wrappers unless requested:
```
lib/
├── app/                        # Shell, router, di, theme, bootstrap
├── auth/                       # Feature folder
│   ├── presentation/           # screens/ & widgets/
│   ├── bloc/                   # bloc, event, state
│   └── data/                   # api, dto, repository
├── booking/                    # Feature folder
└── common/                     # Helpers, utils, formatters (no entities, no widgets)
```

### 2. Headless SDK Module Layout (`sdk/*` or `packages/*`)
Pure headless domain modules. No UI widgets, no Flutter Bloc/Cubit, no routing, no hardcoded fakes:
```
sdk/my_module/
├── lib/
│   ├── my_module.dart          # Public surface API, exports domain entities & module config
│   └── src/
│       ├── common/             # Interceptors, module-scoped failures (e.g. MyModuleFailure)
│       ├── my_module_config.dart # Injected config (dio, baseUrl, tokens, callbacks)
│       ├── my_module.dart      # Main module facade (init(), getters)
│       └── <feature>/          # Specific feature domain (if multi-feature)
│           ├── api/            # Direct HTTP client calls (returns ResultDart)
│           ├── dto/            # Wire data-transfer objects
│           ├── entities/       # Domain models exposed to callers
│           ├── repository/     # Repository contracts & implementations
│           └── providers/      # Third-party adapters/seams (e.g. location, native providers)
```

### 3. File & Type naming
Follow the project's existing convention:
- Abstract interface with no concrete members: `IXxx` (or project standard)
- Abstract class with concrete members / base logic: `AbsXxx`
- Extension: `ExXxx`
- Sealed family & static namespace: plain noun
- Screen: `<feature>_screen.dart`
- Bloc / Event / State: `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`
- DTO (wire format): `<name>_dto.dart`
- Domain entity: `<name>.dart` (or `<name>_entity.dart`)
- One public top-level type per file in bloc / data / repository / common.

## Separate DTO from domain model when using a codegen HTTP client

When using a codegen HTTP client (retrofit-style) + `json_serializable`/equivalent: separate the model received directly from the backend (DTO, matching the response schema exactly) from the domain model the UI/SDK caller uses (`entities/`) — do not let one class be both DTO and UI/domain model. Reason: when the backend changes a field/data type, only the DTO + mapper need editing, not every caller consuming that model. Small single-purpose endpoints without codegen may share one entity when mapping overhead has no benefit.

## Shared Packages vs App Packages

- **Headless SDK modules**: Layer-first or domain-first inside `lib/src/`, strictly headless and returning typed `ResultDart`.
- **Shared App Shell/Core**: Holds shared design systems, common widgets, shared Blocs (e.g. `AuthBloc`), fakes, and onboarding gates.
- **Consumer Apps**: Composes SDK modules and shared core in `di.dart` / bootstrap.

## Packaging when the project grows large

Only split into a separate Dart package (`packages/<name>`, each package versioned independently via path dependency in the app's `pubspec.yaml`) when that feature genuinely needs reuse in another app, or another team needs to build it independently. Do not use melos or any monorepo management tool — pubspec path dependencies are enough. Do not split a package "to tidy up" when only 1 app uses it — it adds version pin + separate `pubspec.yaml` cost for no benefit.

## pubspec.yaml

- Pin versions with `^x.y.z` (caret), not absolute hard pins unless there is a specific compatibility reason.
- Adding a new dependency: check whether `pubspec.yaml` already has an equivalent lib before adding a new one doing the same job.
- `dev_dependencies` for: `build_runner` (if using codegen), lint package (`flutter_lints`).
