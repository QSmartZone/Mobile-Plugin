# Performance — details

## Measure first, optimize later

Only optimize with concrete evidence (Flutter DevTools → Performance/Timeline, or a real jank report from users) — guesswork optimization usually makes code harder to read without fixing the real bottleneck.

## `ListView.builder`/`GridView.builder` for long lists

`ListView(children: [...])` builds all children as soon as the widget is built, including parts not yet on screen — with long lists (hundreds of items or more) this causes jank when opening the screen. `.builder` only builds items currently or about to be visible in the viewport.

## Move CPU-heavy work off the main isolate

Parsing large JSON, decoding/resizing images, heavy computation running on the main isolate blocks frame rendering (animation jank, input lag) because Flutter has only 1 isolate handling the UI. Use `compute()` or `Isolate.run()` to push that work to a separate isolate.

## Redundant rebuilds

`Selector` (Provider), `BlocSelector`/`context.select` (Bloc/Riverpod) let a widget rebuild only when the exact part of state it needs changes, instead of rebuilding entirely whenever the parent state changes. Add only when the profiler shows redundant rebuilds really cause jank — adding it everywhere by default increases code complexity with no measurable benefit.

`const` constructor (see "Commonly wrong decisions" in SKILL.md) is the first and cheapest step before reaching for `Selector`/`BlocSelector`.

## Images

Use the exact size needed for display (`cacheWidth`/`cacheHeight` on `Image`, or resize the image before upload) — loading a full-resolution image to show a small thumbnail costs many times the memory actually needed to decode it, easily causing OOM in long image lists (feed, gallery).

## Specific pitfalls

- Calling an API or doing heavy computation directly in `build()` — `build()` can run many times (every rebuild), making the call repeat needlessly. Move it to `initState`, a bloc/notifier, or memoize the result.
- Using `Opacity` for a static effect that does not change over time — this widget may cost its own compositing layer depending on the engine; if not animating, consider designing the UI so it is not needed on a large subtree.
- Impeller is currently the default renderer on iOS and Android — measure real compositing cost with DevTools Performance instead of guessing from old renderer behavior.
