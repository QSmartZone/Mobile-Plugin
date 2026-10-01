# Adaptive UI & accessibility

## Responsive

Use `useWindowDimensions` (reactive, re-renders on rotation) instead of `Dimensions.get('window')` called once at mount (stale value after rotate). Use ratios/flexbox instead of hardcoded fixed pixel values to render correctly across screen sizes.

```tsx
const { width } = useWindowDimensions();
const columns = width > 600 ? 3 : 2; // tablet vs phone
```

## Safe area

`SafeAreaView`/`useSafeAreaInsets` (from `react-native-safe-area-context`) for the notch, home indicator, status bar — do not hardcode `paddingTop: 20` or similar; the value differs between devices.

```tsx
const insets = useSafeAreaInsets();
<View style={{ paddingTop: insets.top }}>...</View>
```

## Accessibility — mandatory baseline for end-user UI

`accessibilityLabel` for every interactive element without clear text (icon button, image button); the correct `accessibilityRole` (`button`, `link`, `header`...) so screen readers (VoiceOver/TalkBack) read the right semantics.

```tsx
<Pressable
  onPress={onDelete}
  accessibilityRole="button"
  accessibilityLabel="Delete this item"
>
  <TrashIcon />
</Pressable>
```

Use `AccessibilityInfo.isScreenReaderEnabled()` when UI behavior must change while a screen reader is on (for example, disable auto-advancing slide animation). Minimum touch target 44×44pt (iOS HIG) / 48×48dp (Material) — smaller icons need an expanded `hitSlop`; do not shrink the tappable area to keep the UI "compact".

```tsx
<Pressable hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} onPress={onClose}>
```

Text/background color contrast must meet WCAG AA (at least 4.5:1 for normal text) — verify with a contrast checker tool when choosing a color theme, not by eyeballing "looks contrasty enough".

## Anti-pattern

- Using color as the only signal (only changing color to indicate a form field error) — add an icon/text so users who cannot distinguish colors still understand the state.
- Setting `accessible={false}` or skipping accessibility for an entire screen because "later" — the minimum baseline applies as soon as the UI is built, not as a final cleanup task.
