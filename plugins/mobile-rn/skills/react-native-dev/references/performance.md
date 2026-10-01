# Performance

## Measure before optimizing

Use React Native DevTools (RN ≥0.76, press `j` in Metro; RN 0.73 removed Flipper) to identify which components re-render unnecessarily/take time before adding `useMemo`/`useCallback`/`React.memo` — arbitrary memoization makes code harder to read and often changes nothing because the dependency comparison costs more than the re-render.

## Hermes engine

Hermes is the default JS engine for both iOS/Android since React Native 0.70+ — precompiled bytecode gives faster startup than JSC. Check it is enabled in `android/gradle.properties` (`hermesEnabled=true`, moved there from `build.gradle` in RN 0.71) and `ios/Podfile` (`:hermes_enabled => true`) if an older project has not migrated; do not disable Hermes unless a specific native library is incompatible (rare in recent versions).

## New Architecture (Fabric/TurboModules)

New Architecture is the default for new projects since RN 0.76. From RN 0.82, the legacy architecture is removed entirely — native libraries without Fabric/TurboModule support will break when upgrading to 0.82+; check the lib changelog before upgrading.

## Long lists: FlatList/FlashList, not `.map()`

```tsx
// wrong: renders all N items at once, no windowing
{items.map((item) => <ItemRow key={item.id} item={item} />)}

// right: renders only items in the viewport + buffer
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemRow item={item} />}
  getItemLayout={getItemLayout} // known height up front → avoids extra layout passes
/>
```

Use `FlashList` (Shopify) when `FlatList` is measured as a real bottleneck (very long list, complex items) — it improves view recycling; it is not the default replacement for `FlatList` unless a problem was measured.

## Animation: Reanimated for 60fps

The standard `Animated` API runs on the JS thread — complex animations/gesture interactions stutter when the JS thread is busy (network, re-render). `react-native-reanimated` (combined with `react-native-gesture-handler`) runs worklets on the UI thread, not blocked by the JS thread.

```tsx
const offset = useSharedValue(0);
const style = useAnimatedStyle(() => ({
  transform: [{ translateX: offset.value }],
}));
// worklet runs on the UI thread, no round-trip through the bridge every frame
```

Switch to Reanimated only when an `Animated` API animation is measured to stutter/drop frames — do not rewrite all existing animations "just in case".

## Images and bundle

Use `react-native-fast-image` (or `expo-image`) to cache network images when the default `Image` causes measured re-fetch/flicker; enable Hermes bytecode and check bundle size with `npx react-native-bundle-visualizer` when startup time is a real problem, do not guess by adding lazy-load to everything.

## Anti-pattern

- Wrapping every function/value in `useCallback`/`useMemo` "just in case" — use only when passing to a `React.memo` child or as another effect's dependency; otherwise it only adds useless comparison cost.
- Inline function/object literals as props to a `React.memo` component without memoizing — makes memo pointless because the reference changes every render.
