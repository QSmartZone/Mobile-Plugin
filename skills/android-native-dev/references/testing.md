# Testing Android — chi tiết

## JUnit + coroutine test cho ViewModel/Repository/UseCase

```kotlin
@Test
fun `load success updates state`() = runTest {
    val repo = FakeBookingRepository(bookings = listOf(sampleBooking))
    val vm = BookingViewModel(repo)
    vm.load()
    assertEquals(BookingUiState.Success(listOf(sampleBooking)), vm.state.value)
}

@Test
fun `load failure emits error state`() = runTest {
    val repo = FakeBookingRepository(shouldFail = true)
    val vm = BookingViewModel(repo)
    vm.load()
    assertTrue(vm.state.value is BookingUiState.Error)
}
```

Dùng `TestDispatcher`/`runTest` (kotlinx-coroutines-test) thay vì `Thread.sleep` để chờ coroutine — nhanh, deterministic, không flaky theo tốc độ máy CI.

## Fake/Mock Repository

Ưu tiên fake class tự viết (implement lại interface Repository, trả dữ liệu cố định) hơn mock framework cho test đơn giản — dễ đọc, không cần học DSL mock. Dùng Mockito/MockK khi cần verify số lần gọi hoặc mock nhiều dependency phức tạp.

## Compose UI test

```kotlin
@get:Rule val composeRule = createComposeRule()

@Test
fun bookingList_showsItems() {
    composeRule.setContent { BookingListScreen(state = sampleState) }
    composeRule.onNodeWithText("Booking #123").assertIsDisplayed()
}
```

## Espresso (View cũ)

Chỉ dùng khi test màn hình còn XML layout/View — không viết Espresso test mới cho màn hình đã migrate Compose.

## Mức test theo risk, không phải số lượng cố định

Logic có branch/loop/parse/tính toán → luôn cần test. UI thuần hiển thị (Composable preview tĩnh, layout không logic) → không ép viết test.

Nếu project gần như chưa có test nào (không có convention sẵn để soi theo) → không tự bịa coverage % hay pattern cầu kỳ, bootstrap từ pattern cơ bản đã có sẵn trong chính file này (JUnit + coroutine test dispatcher cho ViewModel).

## Nguyên tắc

Bug fix có branch/loop lỗi → viết test tái hiện bug (fail trước khi fix). ViewModel mới → test tối thiểu 2 case: thành công + lỗi. Không test getter/setter hay Compose preview tĩnh không logic.

## Chạy test đúng cách

- Chạy đúng 1 class/method đang sửa bằng `--tests "<Class>"` hoặc `--tests "<Class>.<method>"`, không chạy cả module cho 1 thay đổi nhỏ.
- Đọc dòng fail đầu tiên trong output trước — assertion đầu tiên fail thường là nguyên nhân gốc, các fail sau có thể chỉ là hệ quả.
- `connectedAndroidTest` (Espresso/Compose UI test trên thiết bị) chỉ chạy khi task chạm UI — tốn thời gian, không chạy mặc định cho thay đổi logic thuần.
- Không chạy full test suite trước khi unit test liên quan đã pass — fail nhanh, sửa, rồi mới chạy rộng hơn.
- Gradle treo lúc resolve dependency (mạng chậm/không có) → thêm `--offline` nếu dependency đã có trong cache.
