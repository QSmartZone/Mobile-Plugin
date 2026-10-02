# Adaptive UI & accessibility — details

This is the minimum baseline for an ordinary app, not a full accessibility audit (WCAG AAA, checks with real TalkBack/VoiceOver) — that is beyond this skill's scope and needs a separate request.

## Responsive layout

`MediaQuery.of(context).size`/`LayoutBuilder` to split layout by breakpoint (phone vs tablet vs web) — do not hardcode fixed px sizes for widgets that must run on many screen sizes.

`OrientationBuilder` only when the UI genuinely needs to change layout by device orientation (for example video player, map) — not the default for every screen; most apps only need a portrait layout.

Pitfall: calling `MediaQuery.of(context)` broadly in many small widgets makes the whole widget tree rebuild on every resize/rotation (`MediaQuery.of` registers a dependency on the entire `MediaQueryData`, even when the widget needs only 1 field like `size.width`). When only the size of one specific subtree is needed, a local `LayoutBuilder` is cheaper.

## Accessibility

`Semantics`/`semanticLabel` is mandatory for icon-only buttons and meaningful images (not purely decorative ones) — screen readers (TalkBack/VoiceOver) cannot infer the meaning of an icon.

Text/background color contrast at least WCAG AA (4.5:1 for normal text, 3:1 for large text) — if the design system already has color tokens, use exactly those tokens instead of picking colors by eye.

Touch targets (buttons, tappable icons) at least 48x48dp — smaller is hard to tap accurately, especially on small screens or for users with limited motor ability.

Specific pitfall: a bare `GestureDetector` wrapping a `Container`/`Padding` without `Semantics` or without `InkWell`/`Material` — to the eye it taps fine, but a screen reader does not recognize it as an interactive element at all (cannot focus, cannot be read). Prefer `InkWell`/`ElevatedButton`/widgets with built-in semantics over hand-building a bare `GestureDetector` for tap behavior.

Text scale: respect the OS `MediaQuery.textScaler` instead of hardcoding a non-scaling `fontSize` — users enabling "large text" in system settings is a real accessibility need, not a rare edge case. Quick check: raise the text scale in the device/emulator Settings and see whether the layout overflows/clips text.

## When mandatory, when not

Public-facing screens (login, payment, the main flows end users use daily) → apply this baseline in full. Internal/admin-only screens with few users, or debug/dev-only UI → may be skipped if there is no specific compliance requirement — do not apply it rigidly and equally to every screen in the app.
