# Package layering — details

Reference: ADR "SDK ships as N path-linked packages, without a workspace tool" + ADR "core dependencies are shared by every sub-package".

## Standard layers — 4 tiers

```
                    ┌──────┐
                    │ core │   config, HTTP client, auth, secure storage,
                    └───┬──┘   realtime transport, error model — pure Dart,
                        │      NO UI framework imports
                   ┌────▼─────┐
                   │ shared-ui│   design tokens, app shell, primitive widgets
                   └────┬─────┘
          ┌─────────────┼─────────────┐
          │             │             │
   ┌──────▼─────┐ ┌─────▼────┐ ┌──────▼─────┐
   │ domain pkg │ │domain pkg│ │ domain pkg │   do not import each other
   └──────┬─────┘ └─────┬────┘ └──────┬─────┘
          └─────────────┼─────────────┘
                  ┌──────┴──────┐
             ┌────▼───┐   ┌─────▼────┐
             │bundle A│   │ bundle B │   preset assembled for one role/tenant
             └────────┘   └──────────┘
```

- **core**: every other package depends on it. No reverse dependency. No UI framework imports (pure Dart) — core must be usable where no UI is needed (e.g. a background service).
- **shared-ui**: depends on core, provides the app shell + tokens + shared primitive widgets. Domain packages do not redraw primitives themselves.
- **domain package** (middle tier): each package = 1 independent feature/domain (booking, payment, map, chat...). **They do not import each other** — if 2 domains both need something, push it down to core/shared-ui. Reason: a consumer needing only domain A should not have to compile domain B's native layer (e.g. a consumer without maps should not pull in the Google Maps SDK/geolocator).
- **bundle** (preset per role/tenant): pre-assembles N domain packages + theme + routes + permissions for one consumer type (e.g. "end-user app" vs "worker app"). A bundle **holds no business logic of its own** — it only pins the role, forwards extension points, and merges the screen presets the domains contribute (see composition-and-session.md). A domain project matching no existing preset uses the domain packages directly; going through a bundle is not mandatory.

## Why no workspace tool (melos, pnpm workspace...)

When packages are linked only by path dependency and not published, a workspace tool adds a globally installed tool + a second configuration surface, in exchange for a "resolve each package in the right order" loop that a few-line script already does. Consider a workspace tool only when: publishing to a private registry, or the package count is so large (>15-20) that a hand-written script can no longer manage it.

## Dependency hygiene

- A third-party dependency that **every** sub-package needs → declare it exactly once in core, do NOT redeclare it in sub-packages (avoids version drift on bumps).
- A sub-package needing types from a dependency declared in core → core re-exports **selectively** (`export 'package:x/x.dart' show TypeA, TypeB;`), not the whole package — exporting the whole package is the path for 3rd-party types to leak into every consuming widget, exactly the mistake the referenced legacy SDK made.
- If the language/tool has a lint of the kind "must declare a direct dependency to import it" (`depend_on_referenced_packages` in Dart) and it blocks a legitimate transitive import per the hygiene above → disable that lint in sub-packages, keep it enabled in core (core is the only place where pubspec/package.json must be complete). Trade-off: a package genuinely missing a dependency (absent from core too) fails at the resolve/install step instead of the lint step — the error still appears, it just moves.
- Before adding a new dependency line to a sub-package: grep core's dependency declaration file first — if it is there, import directly, do not add a duplicate line.
- A package declares a dependency only when **something imports it** — a declared but unused dependency still accumulates build cost (native plugins pull in platform configuration, install time) for every consumer.

## When to split out a new domain package

Split when: (a) the domain has a heavy native plugin/dependency that consumers not needing it should not pay for, or (b) the domain will be reused independently by others/other projects. Do not split "for tidiness" when only 1 consumer uses it — adding a package adds one config file + one more thing to remember in the dependency graph, it is not free.
