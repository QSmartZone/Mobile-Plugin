# Building ahead of the backend & porting from a legacy codebase — details

Reference: "implement frozen contract ahead of backend" + "auth API is a seam" + "rewrite not copy legacy infrastructure" — 3 ADRs of an SDK that had to be built in parallel with an unfinished backend, based on the infrastructure of an old app.

## Building the SDK before backend endpoints exist

When the timeline forces the SDK to be written before the backend has real endpoints:

1. Have a "frozen" contract document — request/response shapes, realtime events, business flows — and implement the SDK exactly to that document, no guessing.
2. Put interfaces exactly where things will change once the real backend appears (realtime transport, payment gateway...) — the concrete implementation may compile and return a controlled runtime error when calling a nonexistent endpoint, but the interface does not change when the backend arrives.
3. Accept explicitly: verification now means "correct per our reading of the contract", not "correct against the real server". Budget for rework after the backend is done — do not treat the build-first phase as 100% complete.
4. Where the contract and the implementation disagree (discovered midway) → state clearly which is the source of truth for the current build (usually: the real controller that has shipped beats the old document), do not silently pick one side.

Do not rebuild a "double"/fake server in-repo to test against — a double written by the SDK itself only proves the SDK matches its own assumptions, not the real contract. Check against the real backend/staging when available, or review carefully against the contract document.

## A backend's/customer's own dialect — isolate with an interface seam

When the core must talk to a backend/service with its own "dialect" (different field names, different refresh-token flow, different response shape per customer):

```
core: defines an interface (e.g. AuthApi) — Repository/Interceptor depend only on the interface
concrete customer/app: writes its own implementation for that backend's dialect
```

- The interface lives in core; the implementation of a specific dialect lives in the consuming project (not in core, not as a separate SDK package) — core never learns the "vocabulary" of any specific customer.
- Shared logic (retry, single-flight refresh, token storage) is written once around the interface, not rewritten per dialect.
- The interface must not weaken the common contract (e.g. the implementation must return exactly what the backend gives, and core stores exactly that — do not drop fields on your own because "this dialect doesn't have it").
- An endpoint a dialect does not support → return a clear error, do not pretend success, do not crash.

## Porting infrastructure from a legacy codebase — rewrite, do not copy as-is

When there is a legacy codebase (old app, old SDK) holding infrastructure proven to work (network module, token storage, socket registry...):

1. Use the legacy codebase as a **reference document to read and rewrite**, not copy-paste whole files — copying as-is drags in old defects and conventions that do not match the new architecture.
2. Before porting, list the known defects in the old version — do not repeat them:
   - Typical example: saving only the new access token on refresh while the backend rotates both tokens → must save both.
   - Typical example: storing tokens/secrets in unencrypted storage → the new SDK uses secure storage, and never stores sensitive secrets (PIN, OTP) anywhere.
   - Typical example: an event-listening registry blocks re-registration after reconnect (only 1 listener per event type) → rewrite the registry to allow safe re-registration.
3. What the old version is *genuinely good at* (e.g. the single-flight pattern while a token refresh is running, avoiding duplicate refresh calls) → keep it deliberately, and state why.
4. Port scope: only generic infrastructure (network, storage, transport). Do NOT port the old business-heavy UI/features wholesale, do NOT port static color/style classes — new UI is written against the new SDK's token system (white-label-config.md), not the old app's hardcoded style.
5. Every place you deliberately differ from the old version → leave a short note in code/PR stating this is an intentional difference, not an omission — later reviewers (or yourself 6 months on) should not have to guess whether it is a porting bug.
