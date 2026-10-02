# Security, performance, accessibility — basics

## Sensitive data security

- Do not log tokens/passwords/card numbers/PII to Logcat, even in debug builds — debug logs easily slip into release if you forget to remove them or gate them by `BuildConfig.DEBUG`, and Logcat is readable by other apps/debug tools on a rooted device.
- Store secrets (access token, API key, refresh token) with Android Keystore directly (`EncryptedFile`/Tink) or DataStore encrypted with a key stored in Keystore — do not use plain `SharedPreferences` (stores plaintext). `EncryptedSharedPreferences` (Jetpack Security `security-crypto`) has been deprecated since 2024; projects already using it need not migrate urgently, but new code should not add it.
- Declare `android:allowBackup="false"` in the Manifest if the app handles sensitive data. From Android 12 (API 31), `adb backup` can no longer retrieve data of non-debuggable apps — the real risk is a rooted device or direct extraction (not `adb backup` on an ordinary release build).

## Basic performance

- Do not block the main thread with synchronous I/O (file read/write, network calls, DB queries) — use coroutines + `Dispatchers.IO`. Blocking the main thread too long (~5s) → ANR (Application Not Responding).
- Use LeakCanary in debug builds to automatically detect memory leaks (Activity/Fragment/View not released in time) — add as a `debugImplementation` dependency, do not build it into release.
- `RecyclerView`: use the `ViewHolder` pattern correctly (`findViewById` once in the `ViewHolder`, not on every `onBindViewHolder`); update lists with `DiffUtil` (computes the diff, animates/redraws only what changed) instead of `notifyDataSetChanged()` (redraws everything, janky with long lists).
- Compose `LazyColumn`/`LazyRow`: pass the right `key()` for each item (usually a stable id) so Compose tracks the right item when the list changes, avoiding extra recomposition/re-layout (details in `jetpack-compose.md`, only a brief mention here).

## Basic accessibility

- `contentDescription` for images/icons with functional meaning (buttons, status icons) so TalkBack reads them correctly; purely decorative images get `contentDescription="@null"` (or `null` in Compose `Image`) so TalkBack skips them instead of reading noise.
- Minimum touch target of 48dp x 48dp for every tappable button/icon — icons smaller than 48dp need added padding to reach the minimum hit area, do not enlarge the icon.
- Quick check with TalkBack (Settings > Accessibility > TalkBack) to check the reading order and labels make sense before considering a screen done.
- Minimum contrast ratio between text/icon and background per WCAG AA: 4.5:1 for normal text, 3:1 for large text (≥18sp or ≥14sp bold) and functionally meaningful icons.

## Specific pitfalls

- Logging the entire API response body (may contain tokens/PII) in a debug interceptor (OkHttp `HttpLoggingInterceptor` level `BODY`) and forgetting to disable/gate it in the release build → sensitive data leaks via Logcat on release.
- `notifyDataSetChanged()` for a large `RecyclerView` list instead of `DiffUtil` when updating the list → visible jank on every update, especially for long lists or complex items.
- Missing `contentDescription` on an icon-only button (icon, no text) → TalkBack reads a meaningless "Button", visually impaired users do not know what the button does.
- Touch target smaller than 48dp (24dp icon with no padding) → hard to tap accurately, especially for users with motor difficulties or on small screens.
- Leaving `allowBackup="true"` by default on an app handling sensitive data without setting `false` or `dataExtractionRules` → app data (including plain SharedPreferences) is extractable on a rooted device or by direct extraction.
