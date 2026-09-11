# Navigation Android — chi tiết

Chọn 1 trong 3 cách theo project đã dùng gì, không tự đổi giữa chừng trong cùng app.

## Compose Navigation

Cho app Compose-first. Dùng `NavHost`/`NavController`, định nghĩa route bằng sealed class hoặc type-safe args (`navigation-compose` type-safe từ Nav 2.8+) thay vì string nối tay — tránh lỗi runtime khi đổi tên màn hình mà quên sửa hết chỗ ghép string.

```kotlin
@Serializable
sealed interface Route {
    @Serializable data object Home : Route
    @Serializable data class Detail(val bookingId: String) : Route
}

NavHost(navController, startDestination = Route.Home) {
    composable<Route.Home> { HomeScreen(onOpen = { navController.navigate(Route.Detail(it)) }) }
    composable<Route.Detail> { backStackEntry ->
        val args = backStackEntry.toRoute<Route.Detail>()
        DetailScreen(bookingId = args.bookingId)
    }
}
```

## Navigation Component XML (Fragment-based)

Cho app Fragment-based truyền thống: `nav_graph.xml` + `NavHostFragment` + SafeArgs. SafeArgs sinh class typed cho argument giữa các destination — tránh gõ tay `Bundle` key string.

```xml
<fragment android:id="@+id/detailFragment" android:name="...DetailFragment">
    <argument android:name="bookingId" app:argType="string" />
</fragment>
```

```kotlin
val args = DetailFragmentArgs.fromBundle(requireArguments())
findNavController().navigate(HomeFragmentDirections.actionHomeToDetail(bookingId))
```

## FragmentTransaction thủ công

Chỉ dùng khi maintain code cũ đã dùng cách này từ trước (`supportFragmentManager.beginTransaction()...`). Không dùng cho code mới nếu project đã có Navigation Component — mix 2 cách trong cùng activity làm back stack sai.

## Deep link / App link

- **Navigation Component**: khai `<deepLink app:uri="myapp://booking/{id}" />` trong `nav_graph.xml`.
- **Thủ công**: `<intent-filter>` với `<data android:scheme="..." android:host="..."/>` trong Manifest.
- **App Link** (mở thẳng app, không hỏi chọn browser): thêm `android:autoVerify="true"` trên intent-filter + host Digital Asset Links JSON (`.well-known/assetlinks.json`) trên server tương ứng domain khai trong `data android:host`.

## Bẫy cụ thể

- Mix Navigation Component với `FragmentTransaction` thủ công trong cùng activity → back stack sai (nút Back nhảy sai màn hoặc thoát app đột ngột).
- Truyền argument qua `Bundle` string key gõ tay, gõ sai tên key → crash `NullPointerException`/`ClassCastException` lúc runtime, compile không phát hiện được (SafeArgs hoặc type-safe Compose args tránh được lỗi này vì check ở compile time).
- Deep link thiếu `android:autoVerify="true"` hoặc thiếu/sai Digital Asset Links JSON trên server → Android không tự mở app, hiện dialog chọn browser thay vì vào thẳng app.
- Định nghĩa route Compose bằng string ghép tay (`"detail/$id"`) thay vì sealed class/type-safe args → đổi tên/thứ tự tham số ở 1 nơi mà quên sửa chỗ parse, lỗi chỉ lộ ra khi chạy thử màn đó.
- Gọi `navigate()` nhiều lần liên tiếp do double-tap (thiếu debounce) → push trùng nhiều bản của cùng destination vào back stack.
