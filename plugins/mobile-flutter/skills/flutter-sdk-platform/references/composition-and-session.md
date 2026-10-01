# Composition seam & session pattern — details

Reference: cross-package data flow (auth token, realtime event) + "bundle composes domain screen preset" in a real 7-package SDK.

## Root problem

2 domain packages (e.g. booking and map) must not import each other (package-layering.md), yet at runtime data still needs to flow from one package to the other (e.g. the realtime position of a booking must be drawn on the map). Without a clear seam, writers will cross-import "for convenience" — breaking the layering the first time a cross-domain feature is needed.

## Pattern: the composition layer is the only place that knows both domains

```
domain A (booking) ─── internal event/stream ───▶ core (shared transport)
                                                      │
                                    composition layer │ (app shell / bundle)
                                    — the ONLY place   │  maps payload A → type B understands
                                    that knows A and B ▼
                                                domain B (map) receives via a common interface
                                                (Stream<T>, callback) — does not know A exists
```

- Domain package A does not open its own network/realtime connection — it uses the shared transport in core.
- Domain package B (map, chart, anything displaying other domains' data) receives input through **its own** data types (not A's types) — B never `import`s A.
- The composition layer (app shell, or role-based preset bundle) is the only place that maps data from A to the type B understands. This is the "seam" — if domain A changes its data shape tomorrow, only this one place needs to change.

## Pattern: one session, one client, shared

Do not let each domain package open its own HTTP client/DB connection/socket — doing so means auth refresh, retry, and error mapping get rewritten N times and drift apart (one domain forgetting token refresh is a silent security hole).

```
core: Session(config)
    client for the root service ──▶ AuthInterceptor (refresh-on-401, single-flight)
    client(other root) ─▶ new client, SAME interceptor, memoized per root
    realtime ─▶ shared transport channel
        │
        ▼
shared-ui: AppShell builds (or receives) the Session, exposes it via scope/DI,
           ties auth state to the realtime lifecycle:
           SignedIn → connect() ; SignedOut → disconnect() + clear local store
        │
        ▼
domain preset: builds repository from session.clientFor(root), LAZY —
        created only when the first screen needs it, not eagerly at app startup
```

A domain package never creates its own client or builds a repository before a screen needs it — lazy creation is the condition for a bundle/preset to merge many domains without paying initialization for all of them up front.

## Pattern: bundle composes presets, has no logic of its own

A domain package with UI exports a "preset" — a map of route-id → builder, using the session the composition layer provides. A bundle (package per role/tenant) only **merges** these presets into the app shell's route table; host-supplied overrides always win over presets:

```
bundle.build() = appShell(
  overrides: {...domainAPreset.overrides, ...domainBPreset.overrides, ...hostOverrides},
  extraRoutes: [...domainAPreset.extraRoutes, ...domainBPreset.extraRoutes, ...hostExtraRoutes],
)
```

Hard rule: a bundle does not create its own repository/state-holder/API-class/route logic. Logic repeated across 2 bundles → push it down into a domain package, do not duplicate it in each bundle.

## Common pitfalls

- A domain package opens its own client "to be quick" → loses shared refresh/retry, discovered late when one domain hits a 401 loop.
- A bundle starts holding one line of "temporary" business logic → 6 months later the bundle has grown into a second domain package in disguise, hard to separate again.
- The composition layer eagerly initializes every domain at app startup instead of lazily per screen → longer startup time for consumers using only 1 domain in the bundle.
