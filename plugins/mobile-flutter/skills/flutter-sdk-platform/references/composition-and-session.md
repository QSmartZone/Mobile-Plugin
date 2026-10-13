# Composition seam & session pattern — details

Reference: Cross-package data flow, authenticated HTTP client sharing, and clean DI composition in a modular Flutter architecture.

## Root problem

Modular domain packages (e.g. `booking`, `map`, `payment`) must not import each other, yet at runtime data needs to flow between them (e.g. location updates from a map module need to be sent with a booking request, or booking status changes need to trigger map route rendering).

Without a clear composition pattern, modules tend to cross-import each other for convenience, breaking modularity and creating cyclic dependency hazards.

## Pattern: The Host App is the Composition Seam

The host application (or shared app shell in `di.dart`) is the only layer that knows all modules exist.

```
module A (booking) ─── internal event/stream ───▶ app shell (di.dart)
                                                       │
                                     composition layer │ maps payload A → type B understands
                                                       ▼
                                                 module B (map) receives via its own contract
                                                 (Stream<T>, callback) — does not know A exists
```

- **Domain Isolation**: Module A does not know Module B exists.
- **Contract Boundary**: Module B defines its own data types and inputs (e.g. coordinates, callbacks); it does not import Module A's entity types.
- **Host Mapping**: The host app listens to events or reads results from Module A and forwards them to Module B. If Module A changes its internal data representation, only the host wiring changes.

## Pattern: Shared Session via Injected Authorized HTTP Client (`authorizedDio`)

Do not let each domain package open its own unauthenticated HTTP client or duplicate token refresh logic. Doing so leads to out-of-sync tokens, race conditions, and duplicate refresh requests.

In modern modular SDK architectures:
1. **Auth Module owns Session & Interceptor**: An authentication module (e.g. `auth_sdk` or `auth_module`) manages tokens in secure platform storage and provides single-flight refresh interceptors (`AuthInterceptor`).
2. **Factory method produces configured client**: The session exposes a factory method, e.g. `session.authorizedDio(serviceRoot)`, which produces a `Dio` instance wired with base headers, timeout configurations, and the token refresh interceptor.
3. **App injects client and hooks at startup**: The consuming app wires modules in `di.dart`, passing the authorized `Dio` and relevant lifecycle hooks into each module's configuration:

```dart
// 1. Initialize Auth module
final auth = AuthModule(AuthConfig(userServiceRoot: config.userServiceRoot));
final session = auth.session;

// 2. Initialize Booking module with injected authorized Dio and session hooks
final booking = BookingModule(
  BookingConfig(
    dio: session.authorizedDio(config.bookingServiceRoot),
    accessToken: session.accessToken,
    refreshAccessToken: session.refreshAccessToken,
    signedOut: session.signedOut,
  ),
);

// 3. Initialize Map module with provider configuration
final map = MapModule(MapConfig(googleApiKey: config.googleMapsKey));

// 4. Await module initialization
await booking.init();
await map.init();
```

4. **Zero Cross-Module Dependency**: `BookingModule` never imports `AuthModule`; it relies strictly on its injected `dio` and token callbacks defined in `BookingConfig`.

## Pattern: Application-Owned Presentation and State

Presentation, navigation, and state management (e.g. `Bloc`, `Cubit`, `GoRouter`) belong in the application layer:
- **Module Facades**: Each SDK module exposes service/repository contracts and pure domain models.
- **App Blocs**: The application instantiates Blocs (e.g. `BookingBloc`, `AuthBloc`) that consume module repositories.
- **UI Screens**: The application builds UI screens using design system tokens, binding directly to application Blocs.

## Common Pitfalls

- **Creating HTTP Clients inside Modules**: Modules instantiating their own `Dio()` miss global auth token refresh, retry policies, and logging interceptors.
- **Cross-Importing Sibling Modules**: Importing `package:my_auth` inside `my_booking` destroys modularity. Always decouple through the host app config or callbacks.
- **Eager Heavy Initialization**: Initializing native resources before they are needed slows app startup. Use lazy instantiation or lightweight `init()` methods.
