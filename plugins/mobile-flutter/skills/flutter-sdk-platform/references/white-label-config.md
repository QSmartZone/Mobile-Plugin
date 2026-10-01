# White-label config, secrets & theming — details

Reference: single-origin base URL ADR + terminology noun-set ADR of a real white-label SDK (1 codebase, each customer clones and changes config).

## Secrets & endpoints — never commit into the SDK

The SDK does not read `.env` files and ships no default endpoint/key. Everything "per environment" enters from the consuming app at build time:

| Value type | How it enters | Example mechanism |
| --- | --- | --- |
| Base URL, feature flag | Build-time define | `--dart-define`, `BuildConfig` field, `xcconfig` |
| Third-party API key (maps, payment) | Native platform config | Gradle `manifestPlaceholders`, `Info.plist`/`GMSServices` |

The SDK does not decide what values it "knows" — every domain package reads through one shared config object (e.g. `SdkConfig`) passed in by the consuming app at initialization, and does not read environment variables directly in scattered places.

## One origin, many path prefixes — not one URL per service

Even when the backend is several independent services (multiple origins/ports), the SDK exposes only **one configurable `baseUrl`**, with services distinguished by path prefix (`/booking-service`, `/payment-service`...), each prefix also separately configurable. Reason: 1 TLS certificate, 1 CORS origin, 1 token audience for every build — adding a new service later needs no client change. Converse consequence: if the backend truly has multiple origins, a gateway/reverse-proxy must sit in front — that is backend/devops work, not the SDK opening multiple clients across multiple origins.

## Theming — tokens, not literals

Every color/text size in a widget comes from one central token system (`ThemeConfig` → design tokens), never a hex color or `fontSize:` literal directly in a widget — a literal in a widget means changing the theme for another customer requires editing file by file instead of one place.

Derived tokens (e.g. an "on-surface" text color) must be computed from the color pair **actually painted underneath** at the time of use, not an assumed default background — placing text on a gradient/transparent background without checking contrast is the most common bug when the theme changes per tenant.

## Terminology — a noun set, not feature-flag logic

When several tenants share one domain but name things differently (tenant A says "booking", tenant B says "request"), split out a **noun set** (e.g. `entityNoun`, `entityNounPlural`, `actorRoleLabel`...) in config, and **replace every hardcoded string containing that noun across the whole UI** — not just add a config field and use it half-heartedly on a few screens (half-hearted = fake white-label, which only shows the unreplaced spots when the second tenant comes in).

Constraints:
- Terminology changes **display text** only, never branches logic by terminology (if logic must differ per tenant, that is a different architecture decision — feature flag or domain split, not terminology).
- Technical strings (logs, internal exception messages) stay as they are, no need to go through terminology.
- Sentence-composed strings with the noun in the middle (`"Cancel $entityNoun"`) must handle capitalization correctly through a shared helper, not by hand-capitalizing at each spot.
- No need to pull in a whole i18n framework until real multi-language translation is needed — a noun set is a sufficient intermediate step when only terminology changes per tenant, not the language.

## Common pitfalls

- Adding a new terminology field but applying it only on 2-3 "main" screens — the second tenant reaches the remaining screens and only then finds the leftover hardcoded strings; fixing late costs more than fixing from the start.
- Base URL is configurable but the service path prefixes are hardcoded — it looks fully config-driven but code still has to change when a service is added.
- Theme tokens are correct in base components but one hastily written new screen uses a hex directly — a periodic review/grep step (`grep "Color(0x\|fontSize:"`) is needed before treating a batch of code as done.
