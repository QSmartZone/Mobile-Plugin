# Verifying without a reference app / test suite — details

Reference: the decision to drop package-level tests in an SDK that had no runnable reference app at build time, replacing them with resolve+analyze+review.

## When to consider dropping package-level tests (not the default)

This is a deliberate decision for one specific circumstance — **not a general recommendation**, and it does not apply outside the SDK/package in that circumstance:

- There is no real app/consumer to run the SDK during development (the reference app was removed or not yet built).
- In that circumstance, self-written unit tests + self-written doubles/fakes only prove the code matches **the test writer's own assumptions**, not real backend behavior or real runtime behavior — risk: green tests while real bugs still slip through (e.g. asserting one color/state that the actual widget tree never renders).

## When NOT to apply this decision

- A runnable reference app/real backend exists → prefer integration tests on the real app or a staging backend; do not drop tests just because "this SDK is hard to unit test".
- Pure algorithm/parser/mapping logic that depends on neither the UI runtime nor the backend (easy to unit test, high value, low cost) — this kind should still have unit tests even if the SDK overall chooses the drop-package-level-tests strategy; do not equate "dropping UI/integration tests" with "dropping all tests".

## What to use instead of tests

1. **Resolve + analyze every package in dependency order** — a short script (no workspace tool needed, see package-layering.md) running `pub get`/`analyze` (or the equivalent in another language) for each package, stopping immediately when one package fails.
2. **A review checklist in place of tests** — since no tests catch errors automatically, the review checklist must be concrete enough to say "grep pattern X must be empty" rather than vague ("code is clean"). This checklist lives with the SDK's skill/rule and is updated whenever a bug slipped past the previous review — meaning the checklist grows over time, it is not written once and left alone.
3. **The review gate is the final safety net** — do not merge without passing review, because review is carrying the work a test suite normally carries.
4. **Run for real at the first opportunity** (backend comes up, reference app rebuilt) — expect a round of rework then; it is not a sign the SDK was built wrong earlier.

## Trade-offs to state plainly to the decision maker (do not hide)

- Regressions in complex internal logic (interceptor ordering, bloc/reducer state transitions, async race conditions) are caught only by manual review or manual runs — they may slip through to a later real run, slower than a fast local test suite.
- This decision applies exactly to the scope lacking a reference app; record the scope (which packages, which phase) in the ADR/decision — do not let later readers misread it as "this SDK permanently needs no tests".
- Keep the test-running path as a "dead code path" instead of removing the test-running tooling entirely — if a reference app returns later and the decision is reversed, the test-running mechanism does not have to be rewritten from scratch.
