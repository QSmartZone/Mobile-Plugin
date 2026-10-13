# Building ahead of the backend & interface seams — details

Reference: "implement frozen contract ahead of backend" + "auth API is a seam" — patterns for delivering reliable SDK modules aligned with service contracts.

## Building the SDK before backend endpoints exist

When the timeline forces the SDK to be written before the backend has real endpoints:

1. **Frozen contract document**: Base request/response models, realtime events, and business flows on frozen contract documents (OpenAPI/Swagger specs, API contracts), avoiding guesswork.
2. **Interface seams**: Place clean interfaces (`seams`) where backends or third-party implementations may evolve (realtime transport, payment gateway, geolocator). The concrete implementation compiles and returns typed errors if an endpoint is unreachable, but the interface contract remains stable.
3. **Acceptance criteria**: Verification at this stage validates correctness against the contract spec. Budget for an integration pass once live staging endpoints become available.
4. **Discrepancy handling**: When contract docs and live services diverge, establish the source of truth explicitly (e.g. shipping controller/Swagger over stale markdown).

Do not rebuild an ad-hoc in-repo "fake server" — fakes written inside the SDK only prove the SDK matches its own assumptions. Verify against real backend/staging environments or frozen Swagger contracts.

## A backend's/customer's own dialect — isolate with an interface seam

When the module must talk to a backend or service with a specific dialect or custom provider:

```
module: defines an interface (e.g. IAuthApi, IPaymentProvider) — Repository depends only on the interface
consuming app: injects or configures the provider implementation matching their backend
```

- The interface lives in the SDK module; specific dialect/provider implementations are passed in via `ModuleConfig` or registered by the app.
- Shared logic (retry, single-flight refresh, token storage) is implemented once in the module around the interface.
- The interface must not weaken the common contract (return typed `ResultDart` values with domain-specific failure representations).
- Unsupported operations return explicit failure states rather than pretending success or crashing.

## Infrastructure design principles for fresh SDKs

When designing fresh SDK packages:
1. **Clean abstractions**: Do not copy over old anti-patterns or monolithic classes. Design minimal, focused components matching current best practices.
2. **Credential safety**: Store tokens only in secure platform storage (`flutter_secure_storage`). Never persist one-time secrets (OTP, PIN, passwords) in state, logs, or storage.
3. **Token rotation**: Ensure refresh handlers store both rotated access and refresh tokens atomically.
4. **Robust event streams**: Ensure event registries allow clean re-subscription on network reconnections without dropping active listeners or duplicating streams.
5. **Single-flight concurrency**: Guard token refresh and one-time initialization procedures with single-flight locks to prevent redundant parallel network requests.
