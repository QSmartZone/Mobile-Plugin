# Navigation/routing — details

## Choose the mechanism by what the project already has

Check `pubspec.yaml` first — if the project has already chosen, use exactly that; do not propose switching midway just because another lib is "more popular".

| Need | Choose |
| --- | --- |
| Small/medium app, routes need no URL sync, no deep link | `Navigator` 1.0 + hand-written named routes map |
| Need deep link, URL sync on web, nested navigation with several independent tabs | `go_router` |
| Need type-safe routes via codegen, large team adding routes in parallel | `auto_route` |
| Undecided — project has nothing in `pubspec.yaml` | Start with a named routes map; only move to `go_router`/`auto_route` when you see exactly the need in the rows above, do not add a lib "just in case" |

## Centralize route definitions in one place

Whichever approach is chosen, route definitions (name, builder, guard) must live in one file/one place — do not scatter hardcoded inline `Navigator.push(context, MaterialPageRoute(builder: ...))` across many screens. Scattering routes means: changing a target route requires edits in many places, navigation flows cannot be unit-tested, and deep link/analytics later requires rescanning the whole codebase.

## Passing data between screens

Prefer constructor arguments or a typed argument class (`class BookingDetailArgs { final String bookingId; ... }`) over scattered `Map<String, dynamic>` — a wrong key in a `Map` only shows at runtime (usually a `null` crash when reading a missing key), while a typed class catches the error at compile time.

## Specific pitfalls

- Forgetting `PopScope`/back-button handling in a multi-step flow (long form, checkout) that needs confirmation before leaving — loses the data the user entered.
- Pushing a new route without `await`ing the returned result when the next screen must return data (for example picking an address) — use `Navigator.pop(context, result)` + `await Navigator.push(...)` to receive it.
- A named routes map using hand-typed strings ('login', 'home') scattered across the code — define route name constants in one place, avoiding typos the compiler cannot catch.
- Navigating with `Navigator` deep inside child widgets (passing `BuildContext` through many layers just to call `Navigator.of(context)`) — consider having the screen/bloc layer pass a navigation callback down; child widgets only emit events, which is easier to test and to reuse in other screens.
- Not checking `context.mounted` before navigating after an `await` (push after the API call completes) — the widget may have been disposed while waiting, causing a runtime error from using a dead `context`.

## When you do NOT need to change the routing mechanism

A hand-written named routes map that works fine, with no new deep link/URL sync requirement → do not migrate to `go_router` on your own just because it is the "more modern" choice. The cost of migrating routes (rewriting all navigation, retesting every flow) is only worth paying when there is a concrete need the current mechanism cannot meet.
