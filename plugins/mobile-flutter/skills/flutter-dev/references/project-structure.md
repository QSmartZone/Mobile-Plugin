# Flutter project structure — details

## Feature-first layout

```
lib/
├── src/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   ├── blocs/          # or providers/, controllers/
│   │   │   └── models/
│   │   └── booking/
│   │       ├── screens/
│   │       ├── widgets/
│   │       ├── blocs/
│   │       └── models/
│   ├── core/                   # shared: theme, routing, network client, utils
│   └── widgets/                # widgets reused across features (button, input, card...)
└── main.dart
```

Reason: changing/removing a feature touches only one directory, with no files scattered across the app-wide `screens/`, `widgets/`, `models/`.

## File naming — follow the project's existing convention, fall back if none

| Kind | Pattern | Example |
| --- | --- | --- |
| Screen | `<feature>_screen.dart` | `booking_screen.dart` |
| Bloc/Event/State | `<feature>_bloc.dart` / `_event.dart` / `_state.dart` | `booking_bloc.dart` |
| Repository interface | `<domain>_repository_abs.dart` (or the equivalent suffix the project uses) | `chat_repository_abs.dart` |
| Repository implementation | `<domain>_repository.dart` | `chat_repository.dart` |
| DTO (wire format from backend) | `<name>_dto.dart` | `booking_dto.dart` |
| Generated file (`build_runner`) | `<name>.g.dart` | do not edit by hand; edit the source file and rerun codegen |

Always prefer the project's own convention (check existing files before naming a new file) — the table above is only the default when the project has no clear convention.

## Separate DTO from domain model when using a codegen HTTP client

When using a codegen HTTP client (retrofit-style) + `json_serializable`/equivalent: separate the model received directly from the backend (DTO, matching the response schema exactly) from the domain model the UI uses (`models/`) — do not let one class be both DTO and UI model. Reason: when the backend changes a field/data type, only the DTO + mapper need editing, not every widget consuming that model. A small project with only 1-2 API calls and no codegen → may share one model; separating DTOs is not worth the cost yet.

## Package/module shared by many apps — layer-first instead of feature-first

When several apps in the same repo (monorepo) depend on one shared package via path dependency (see the section below) — organize the inside of that shared package **layer-first** (`blocs/`, `dto/`, `models/`, `network/`, `repository/`, `service/`, `widgets/`), unlike feature-first in the apps. Reason: the shared package holds cross-cutting code (network client, repositories, shared models), not a set of complete features with their own UI — grouping by layer helps consuming apps find what to import (for example all repositories in one place) better than grouping by feature, whose boundaries are unclear at the shared level.

## Packaging when the project grows large

Only split into a separate Dart package (`packages/<name>`, each package versioned independently via path dependency in the app's `pubspec.yaml`) when that feature genuinely needs reuse in another app, or another team needs to build/test it independently. Do not use melos or any monorepo management tool — pubspec path dependencies are enough. Do not split a package "to tidy up" when only 1 app uses it — it adds version pin + separate `pubspec.yaml` cost for no benefit.

## pubspec.yaml

- Pin versions with `^x.y.z` (caret), not absolute hard pins unless there is a specific compatibility reason.
- Adding a new dependency: check whether `pubspec.yaml` already has an equivalent lib before adding a new one doing the same job.
- `dev_dependencies` for: `flutter_test`, `mocktail`/`mockito`, `build_runner` (if using codegen), lint package (`flutter_lints`).
