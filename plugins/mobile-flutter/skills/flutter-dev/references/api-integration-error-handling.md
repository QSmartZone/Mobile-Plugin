# API integration & error handling — details

## Follow the existing lib

If the project already has an HTTP client (`dio`, `http`, `chopper`...) and a serialization approach (`json_serializable`, `freezed`, hand-written `fromJson`), use exactly that — do not propose switching libs midway for being "more standard".

## Always have a repository/data source layer

Even for small apps, separate UI from direct HTTP calls with a repository layer — the reason is not "pretty architecture" but testability: without this layer, testing UI business logic forces mocking the whole HTTP client, and changing backend/endpoint means edits scattered across widgets.

Do not add a separate usecase/domain layer if only 1 repository serves 1 screen/bloc — that layer is only worth its cost when several repositories genuinely need shared coordination logic (for example: booking needs both a calendar repository and a payment repository in one transaction).

## 3 kinds of errors to distinguish

The UI must know which kind of error occurred to show the right message — lumping them into a single "has error" is the most common cause of meaningless messages like "Something went wrong":

- **Network/timeout** — no connection, server not responding. UI should allow retry.
- **Parse** — response does not match the expected schema (backend changed a field, old version not updated). UI should show a generic error, no retry (retry does not help).
- **Business** — server returns a valid domain error (insufficient balance, slot full). UI shows the exact message the server returned, not a generic one.

## Minimum states for every screen that calls an API

Whatever state management is used (`setState`/Bloc/Riverpod), a screen calling an API must distinguish at least 4 states: loading, success, error, empty (succeeded but the list/data is empty). Not distinguishing error from loading leaves the UI frozen on error while the user thinks it is loading; not distinguishing empty makes an empty list look like an error or an endless load.

## Specific pitfalls

- Catching exceptions at the UI layer (try/catch around a bloc/notifier call in a widget) — error handling logic is duplicated at every call site, and is untestable without building the whole widget tree. Catch errors at the API-calling layer (repository or bloc); the UI only reads the resulting state.
- Rethrowing the HTTP client's raw exception (`DioException`, `SocketException`...) straight up to the UI layer — the UI must import and know implementation details of the HTTP client in use, breaking the layer boundary; if the HTTP client changes later, every place catching that raw exception must change. Have a domain-specific error type (or message mapping) at the repository boundary.
- Re-calling the API on every rebuild because the call is placed in `build()` instead of `initState`/a user-triggered action.

## Retry/cancel

Add only when really needed: let the user tap retry on a network error; cancel an in-flight request when the user leaves the screen before the response arrives (avoid `setState`/emit on a disposed widget). Do not build a complex automatic retry mechanism if the app has no such requirement.
