---
name: flutter-sdk-platform
description: "Multi-package Flutter SDK architecture (path dependencies), headless domain modules, composition seams, config & theming. Use when designing or building a multi-package SDK."
---

# Flutter SDK Platform Architecture

This skill defines the architectural blueprint for designing and building a **multi-package Flutter SDK (pub packages, path dependencies) reusable across multiple client applications**. Different from `skills/flutter-dev` (everyday Flutter widget and feature coding) — this skill covers SDK-level architectural invariants, boundaries, and package composition.

## Standard Architecture Blueprint

- **Headless Domain Modules**: The SDK is strictly composed of independent, headless feature packages (e.g. `o2o_auth`, `o2o_booking`, `o2o_map`, `o2o_payment`, `o2o_notification`).
- **Pure Domain & Zero UI**: No Flutter widgets, no `flutter_bloc` / state management, no routing, and no hardcoded fakes live in the SDK.
- **Typed Boundary Results**: Public methods return typed results (e.g. `ResultDart<T, ModuleFailure>`). Never throw uncaught exceptions across module boundaries.
- **Application Shell Ownership**: UI, design tokens, app Blocs, routes, and role-specific screens live entirely in the consuming applications or a shared app shell.

## When this skill applies

- Designing or structuring a fresh multi-package Flutter SDK.
- Adding a new domain package to an existing SDK.
- Decoupling business logic and network communications from the UI into reusable modules.
- White-label configurations (one codebase supporting multiple tenant brands/configs).

## Core Architectural Decisions

| Decision | Reference | Core question |
| --- | --- | --- |
| 1. Layering & Boundaries | [package-layering.md](references/package-layering.md) | How are headless modules structured? Who depends on whom? |
| 2. Composition Seam & Session | [composition-and-session.md](references/composition-and-session.md) | How does the host app wire modules together? How is `authorizedDio` injected? |
| 3. Config, Secrets & White-label | [white-label-config.md](references/white-label-config.md) | How do endpoints and secrets enter the SDK? How are tokens/nouns configured? |
| 4. Contract Alignment & Seams | [contract-and-backend-alignment.md](references/contract-and-backend-alignment.md) | How to build against frozen contracts and isolate provider differences with seams? |
| 5. Verification Strategy | [verification-strategy.md](references/verification-strategy.md) | How to verify multi-package SDKs with static analysis and live host apps? |

Read only the reference matching the current task.

## Checklist for New SDK Packages

1. **Confirm Headless Nature**: Ensure zero UI widgets, zero Blocs, and zero routers exist in the package.
2. **Zero Cross-SDK Imports**: Sibling domain modules must never import each other directly ([package-layering.md](references/package-layering.md)).
3. **Injected Configuration**: Accept dependencies (e.g. `dio`, `baseUrl`, session token callbacks) through a typed `Config` class at initialization ([composition-and-session.md](references/composition-and-session.md)).
4. **Typed Error Families**: Define a closed failure hierarchy (e.g. `sealed class ModuleFailure`) and return `ResultDart<T, ModuleFailure>`.
5. **Dependency Hygiene**: Declare only dependencies that are directly imported. Keep packages pure Dart wherever native plugins are not required.
6. **Backend Contract Alignment**: Align models and endpoints directly with frozen OpenAPI/Swagger contracts ([contract-and-backend-alignment.md](references/contract-and-backend-alignment.md)).
7. **Verification**: Verify packages in dependency order with `flutter analyze` ([verification-strategy.md](references/verification-strategy.md)).

## Overarching Principle

Every rule in these references ensures modularity, clean boundaries, and zero circular dependencies. When a situation is not explicitly covered, treat it as an architectural boundary question: keep modules headless, isolate cross-module communication to the host composition layer, and inject dependencies cleanly.
