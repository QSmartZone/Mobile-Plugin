# API integration & error handling — details

## Follow the existing lib

If the project already has an HTTP client (`dio`, `http`, `chopper`...) and a serialization approach (`json_serializable`, `freezed`, hand-written `fromJson`), use exactly that — do not propose switching libs midway for being "more standard".

## Always have a repository/data source layer

Even for small apps, separate UI from direct HTTP calls with a repository layer — the reason is not "pretty architecture": without this layer, changing backend/endpoint means edits scattered across widgets, and error mapping is duplicated per screen.

Do not add a separate usecase/domain layer if only 1 repository serves 1 screen/bloc — that layer is only worth its cost when several repositories genuinely need shared coordination logic (for example: booking needs both a calendar repository and a payment repository in one transaction).

## 3 kinds of errors to distinguish

The UI must know which kind of error occurred to show the right message — lumping them into a single "has error" is the most common cause of meaningless messages like "Something went wrong":

- **Network/timeout** — no connection, server not responding. UI should allow retry.
- **Parse** — response does not match the expected schema (backend changed a field, old version not updated). UI should show a generic error, no retry (retry does not help).
- **Business** — server returns a valid domain error (insufficient balance, slot full). UI shows the exact message the server returned, not a generic one.

## Minimum states for every screen that calls an API

Whatever state management is used (`setState`/Bloc/Riverpod), a screen calling an API must distinguish at least 4 states: loading, success, error, empty (succeeded but the list/data is empty). Not distinguishing error from loading leaves the UI frozen on error while the user thinks it is loading; not distinguishing empty makes an empty list look like an error or an endless load.

## Specific pitfalls

- Catching exceptions at the UI layer (try/catch around a bloc/notifier call in a widget) — error handling logic is duplicated at every call site. Catch errors at the API-calling layer (repository or bloc); the UI only reads the resulting state.
- Rethrowing the HTTP client's raw exception (`DioException`, `SocketException`...) straight up to the UI layer — the UI must import and know implementation details of the HTTP client in use, breaking the layer boundary; if the HTTP client changes later, every place catching that raw exception must change. Have a domain-specific error type (or message mapping) at the repository boundary.
- Re-calling the API on every rebuild because the call is placed in `build()` instead of `initState`/a user-triggered action.

## Dio + Retrofit (when `retrofit` is in `pubspec.yaml`)

Pitfalls:
- Hand-writing `dio.get(...)`/`toJson` next to an existing `@RestApi` client: two sources of truth for one endpoint. Add the method to the client.
- Editing `*.g.dart`: overwritten on the next build. Change the annotated source, then `dart run build_runner build --delete-conflicting-outputs` (or the repo's generate script). Generated files are usually gitignored, so a fresh clone needs the build before analyze/run.
- Putting entity mapping or error mapping inside the client: the client stays a pure declaration. Wrap it.
- Interpolating ids into the path by hand: use `@Path('id')` and `Uri.encodeComponent` on user-supplied values.
- Building query maps in widgets: use a typed query object with `toQueryParameters()` and `@Queries()`; omit null filters.

Shape:

| Piece | Where | Does |
| --- | --- | --- |
| `@RestApi() abstract class XxxClient` + `part 'xxx_client.g.dart'` | `data/api/` | Declares `@GET/@POST...` returning `Future<Envelope<XxxDto>>` or `Future<XxxDto>` |
| `@JsonSerializable()` DTO | `data/dto/` | Wire shape only; request DTOs emit only the schema's properties |
| Wrapper (`Xxx Api`/repository) | `data/api/` or `data/repository/` | Calls the client, maps DTO → entity, runs every call through one guard that turns `DioException` / parse errors into the module's failure type |
| `Dio` | injected | Auth, logging and timeouts live in interceptors on the injected instance; the client takes `Dio` and `baseUrl` in its factory |

Success envelope (`{message, status, data}`): one generic `@JsonSerializable(genericArgumentFactories: true)` envelope class, unwrapped in the wrapper so callers never see it.

## SDK boundary error handling (SDK Modules)

When writing or calling SDK modules (`sdk/`):
- **Never throw exceptions across the module boundary**: Public methods in SDK modules return `ResultDart<T, ModuleFailure>` (e.g. `Result<T, AuthFailure>`).
- **Module failure families**: Define a closed failure hierarchy (e.g. `sealed class AuthFailure`, `sealed class BookingFailure`) capturing specific causes (e.g. `invalidCredentials`, `network`, `sessionExpired`, `serverError`).
- **Do not leak raw HTTP client exceptions**: Catch `DioException` inside the SDK's repository/API layer and map it directly into the module's failure type before returning.
- **Interceptors & try/finally**: In auth/dio interceptors, wrap any async operation before `handler.next` / `handler.reject` in `try/finally` so the request pipeline never hangs indefinitely.
- **Sensitive data safety**: Never attach passwords, OTPs, or bearer tokens to failure objects, state properties, or log messages.

## Retry/cancel

Add only when really needed: let the user tap retry on a network error; cancel an in-flight request when the user leaves the screen before the response arrives (avoid `setState`/emit on a disposed widget). Do not build a complex automatic retry mechanism if the app has no such requirement.
