# UI thích ứng & accessibility

## Responsive

`useWindowDimensions` (reactive, tự re-render khi xoay màn hình) thay vì `Dimensions.get('window')` gọi 1 lần lúc mount (giá trị cũ khi rotate). Dùng tỉ lệ/flexbox thay vì hardcode giá trị pixel cố định để chạy đúng trên nhiều kích thước màn hình.

```tsx
const { width } = useWindowDimensions();
const columns = width > 600 ? 3 : 2; // tablet vs phone
```

## Safe area

`SafeAreaView`/`useSafeAreaInsets` (từ `react-native-safe-area-context`) cho notch, home indicator, status bar — không hardcode `paddingTop: 20` hay tương tự, giá trị này khác nhau giữa thiết bị.

```tsx
const insets = useSafeAreaInsets();
<View style={{ paddingTop: insets.top }}>...</View>
```

## Accessibility — baseline bắt buộc cho UI người dùng cuối

`accessibilityLabel` cho mọi phần tử tương tác không có text rõ ràng (icon button, image button); `accessibilityRole` đúng loại (`button`, `link`, `header`...) để screen reader (VoiceOver/TalkBack) đọc đúng ngữ nghĩa.

```tsx
<Pressable
  onPress={onDelete}
  accessibilityRole="button"
  accessibilityLabel="Xóa mục này"
>
  <TrashIcon />
</Pressable>
```

`AccessibilityInfo.isScreenReaderEnabled()` khi cần đổi hành vi UI lúc screen reader bật (ví dụ tắt animation tự động chuyển slide). Touch target tối thiểu 44×44pt (iOS HIG) / 48×48dp (Material) — icon nhỏ hơn cần `hitSlop` mở rộng vùng chạm, không thu nhỏ vùng bấm để "gọn" giao diện.

```tsx
<Pressable hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }} onPress={onClose}>
```

Contrast màu chữ/nền đạt WCAG AA (tối thiểu 4.5:1 cho text thường) — kiểm tra bằng tool contrast checker khi chọn theme màu, không chỉ nhìn "có vẻ đủ tương phản".

## Anti-pattern

- Dùng màu là tín hiệu duy nhất (chỉ đổi màu để báo lỗi field form) — thêm icon/text để người dùng không phân biệt màu vẫn hiểu được trạng thái.
- Set `accessible={false}` hoặc bỏ qua accessibility cho toàn bộ 1 màn hình vì "làm sau" — baseline tối thiểu áp dụng ngay khi build UI, không phải việc dọn dẹp cuối cùng.
