---
name: flutter-sdk-platform
description: "Multi-package Flutter SDK architecture (path dependencies), multi-tenant white-label: layering, seam, config, theming. Use when designing or splitting a multi-package SDK."
---

# Flutter SDK Platform Architecture

This skill answers: when building a **multi-package Flutter SDK (pub packages, path dependencies) reusable across many apps/tenants**, which decisions must be settled first, which pattern to follow, and which traps others have already hit. Different from `skills/flutter-dev` (everyday Flutter coding conventions) — this skill covers SDK-level architecture decisions, read once when designing/restructuring, not every time you edit a widget.

Reference source: a 7-package Flutter SDK (5 domain packages + 2 role bundles) shipped across multiple phases, with ADRs recording each decision and its real trade-offs. The references below generalize that pattern — they do not copy its business logic.

## When this skill applies

- Tasks: "build a shared SDK/plugin for many apps", "split a feature into an independent package", "white-label app" (1 codebase, theme/copy/config changes per customer), "redesign multi-module mobile architecture".
- Does NOT apply to a single app, 1 tenant, with no intent to reuse — this layering has a cost (many packages, many pubspecs, many greps before adding a dependency); do not pay that cost without a reuse benefit.

## 5 decisions to settle before writing the first package

| Decision | Reference | Core question |
| --- | --- | --- |
| 1. Layering — how to split packages, who depends on whom | [package-layering.md](references/package-layering.md) | Which package is the "core everyone needs", which is an "optional feature", which is a "preset assembled for one tenant/role type"? |
| 2. Composition seam — where the logic connecting 2 packages lives | [composition-and-session.md](references/composition-and-session.md) | May a domain package know another domain package exists? Who opens the HTTP client/session? |
| 3. Config & secrets boundary | [white-label-config.md](references/white-label-config.md) | How do secrets/endpoints enter the SDK? What mechanism changes theme/copy per tenant, instead of scattered if/else? |
| 4. Contract with a backend that does not exist yet | [contract-and-legacy-port.md](references/contract-and-legacy-port.md) | What does the SDK follow while the backend is unfinished? Is there legacy code (old app, old SDK) to reference, and how to port it? |
| 5. Verify when there is no (or not yet a) reference app | [verification-strategy.md](references/verification-strategy.md) | What level of testing, and what is the trade-off of dropping package-level tests? |

Read only the reference matching the current work — do not read all 5 files for a small change in an existing package.

## Checklist when starting a new package in an existing SDK

1. Which layer does this package belong to (core / shared-ui / domain / bundle)? → confirm against [package-layering.md](references/package-layering.md) before creating the directory.
2. Need something from another package in the same layer (domain↔domain)? → do not import directly, push it down to core/shared-ui ([composition-and-session.md](references/composition-and-session.md)).
3. Need a third-party dependency → is it already declared in core? If so, do not declare it again ([package-layering.md](references/package-layering.md)#dependency-hygiene).
4. Any string/color hardcoded for a specific tenant? → must go through config/token/terminology, no literals in widgets ([white-label-config.md](references/white-label-config.md)).
5. Does the matching backend endpoint exist yet? If not → see [contract-and-legacy-port.md](references/contract-and-legacy-port.md) for how to write ahead against a frozen contract.
6. What to verify with before reporting done → [verification-strategy.md](references/verification-strategy.md).

## Overarching principle

Every rule in the 5 references exists because the opposite decision paid a real price (rework, dependency leak, tenant A seeing tenant B's text). Do not infer new rules beyond what the references say; when a situation is not covered by a reference, it is a new architecture decision — stop and ask instead of inventing one by gut feeling.
