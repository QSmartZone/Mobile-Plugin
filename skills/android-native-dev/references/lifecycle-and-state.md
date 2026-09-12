# Lifecycle và state — Activity/Fragment

2 bẫy chính cần nhớ: null binding ở `onDestroyView` (Fragment), và process death khác config change (ViewModel mất theo process death, không mất theo config change).

## Fragment lifecycle — View lifecycle khác Fragment lifecycle

Fragment thêm `onCreateView` → `onViewCreated` → ... → `onDestroyView` → `onDestroy`.

Điểm khác biệt quan trọng: **Fragment instance có thể sống lâu hơn View của nó** — ví dụ khi Fragment nằm trong back stack (bị replace nhưng chưa pop), View bị destroy (`onDestroyView`) nhưng Fragment object vẫn tồn tại, chỉ thật sự chết ở `onDestroy`.

Hệ quả trực tiếp với ViewBinding: phải null binding trong `onDestroyView`, không giữ tới `onDestroy`.

```kotlin
class ProfileFragment : Fragment() {
    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null // View đã chết, Fragment có thể còn sống trong back stack
    }
}
```

## Config change (xoay màn hình, đổi ngôn ngữ, đổi theme...)

Mặc định Activity/Fragment bị **destroy và recreate** khi config thay đổi. Có thể khai `android:configChanges` trong Manifest để tự xử lý thay vì recreate, nhưng không khuyến khích — mất callback lifecycle đúng chuẩn (`onSaveInstanceState`/`onCreate` không chạy lại), dễ bug khi thêm resource mới cần config-aware mà quên cập nhật code tự xử lý.

Cách đúng: giữ state cần sống qua config change bằng `ViewModel`.

```kotlin
class ProfileViewModel : ViewModel() {
    private val _state = MutableStateFlow(ProfileUiState())
    val state: StateFlow<ProfileUiState> = _state.asStateFlow()
    // Activity xoay màn hình → Activity/Fragment bị recreate,
    // nhưng ViewModel này vẫn là cùng 1 instance (scope theo Activity/NavBackStackEntry)
}
```

`ViewModel` sống qua config change, chỉ chết khi Activity/Fragment thật sự finish (user back ra khỏi màn hình, không phải do xoay màn hình). Không dùng static field hay singleton để né việc mất state khi recreate — giữ `Context`/state UI trong static field gây leak (static sống theo process, không theo vòng đời Activity) và state không rõ ràng thuộc vòng đời nào.

## Process death — khác config change

Khi app ở background, hệ thống có thể **kill hẳn process** để giải phóng RAM (không phải chỉ recreate Activity). Khác config change ở chỗ: `ViewModel` cũng mất theo vì cả process biến mất, không chỉ Activity.

Khôi phục bằng `SavedStateHandle` — inject vào ViewModel, tự động lưu/khôi phục các cặp key-value nhỏ qua process death:

```kotlin
class ProfileViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {
    var userId: String?
        get() = savedStateHandle["userId"]
        set(value) { savedStateHandle["userId"] = value }
}
```

Chỉ lưu state tối thiểu cần để khôi phục đúng chỗ (id đang xem, text đang gõ dở, tab đang chọn) — không lưu toàn bộ danh sách/data lớn vào `SavedStateHandle` (giới hạn dung lượng như Bundle, và danh sách nên fetch lại từ nguồn khi ViewModel được tạo lại).

### Activity/Fragment View-based không có ViewModel

`SavedStateHandle` cần ViewModel. Với Activity/Fragment thuần View (không qua ViewModel), dùng `onSaveInstanceState`/`onRestoreInstanceState` để lưu state nhỏ, tạm thời (scroll position, text đang gõ dở, tab đang chọn) qua process death và config change:

```kotlin
override fun onSaveInstanceState(outState: Bundle) {
    super.onSaveInstanceState(outState)
    outState.putString("query", currentQuery)
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    currentQuery = savedInstanceState?.getString("query") ?: ""
}
```

Cùng giới hạn dung lượng như Bundle/`SavedStateHandle` — chỉ state nhỏ, không phải nguồn lưu data chính.

## Bẫy cụ thể

- Giữ `Context`/`Activity` reference trong singleton hoặc static field → leak toàn bộ Activity (View tree, resource) khi Activity bị destroy nhưng static field vẫn giữ reference sống theo process.
- Đăng ký listener/callback (`LocationListener`, `BroadcastReceiver`, `sensorManager.registerListener`) ở `onCreate`/`onStart` nhưng quên unregister ở `onDestroy`/`onStop` tương ứng → leak, hoặc callback gọi vào Activity đã chết gây crash.
- Không null ViewBinding trong `onDestroyView` của Fragment → leak toàn bộ View hierarchy khi Fragment còn sống trong back stack nhưng View đã bị destroy.
- Test app chỉ trên emulator/thiết bị RAM cao, không bật "Don't keep activities" (Developer Options) → không phát hiện bug process death, chỉ lộ ra khi user thật dùng thiết bị RAM thấp và mất state khó chịu.
- Khai `android:configChanges` để né recreate thay vì dùng `ViewModel` → tưởng tối ưu nhưng mất callback lifecycle chuẩn, code tự xử lý config dễ quên update khi thêm resource/layout mới theo config.
