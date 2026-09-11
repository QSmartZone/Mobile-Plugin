# Performance

## Đo trước khi tối ưu

Dùng React DevTools Profiler hoặc Flipper để xác định component nào re-render thừa/tốn thời gian trước khi thêm `useMemo`/`useCallback`/`React.memo` — memoization tùy tiện làm code khó đọc hơn mà nhiều khi không đổi gì vì chi phí so sánh dependency còn tốn hơn re-render.

## Hermes engine

Hermes là JS engine mặc định cho cả iOS/Android từ React Native 0.70+ — bytecode precompile giúp startup nhanh hơn JSC. Kiểm tra đã bật trong `android/app/build.gradle` (`hermesEnabled true`) và `ios/Podfile` (`:hermes_enabled => true`) nếu project cũ chưa migrate; không tắt Hermes trừ khi có thư viện native cụ thể chưa tương thích (hiếm ở bản mới).

## List dài: FlatList/FlashList, không `.map()`

```tsx
// sai: render hết N item cùng lúc, không có windowing
{items.map((item) => <ItemRow key={item.id} item={item} />)}

// đúng: chỉ render item trong viewport + buffer
<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <ItemRow item={item} />}
  getItemLayout={getItemLayout} // biết trước height → tránh layout pass thừa
/>
```

`FlashList` (Shopify) khi `FlatList` đã đo là bottleneck thật (list rất dài, item phức tạp) — cải thiện recycling view, không phải lựa chọn mặc định thay `FlatList` nếu chưa đo vấn đề.

## Animation: Reanimated cho 60fps

`Animated` API chuẩn chạy trên JS thread — animation phức tạp/tương tác gesture dễ giật khi JS thread bận (network, re-render). `react-native-reanimated` (kết hợp `react-native-gesture-handler`) chạy worklet trên UI thread, không bị block bởi JS thread.

```tsx
const offset = useSharedValue(0);
const style = useAnimatedStyle(() => ({
  transform: [{ translateX: offset.value }],
}));
// worklet chạy trên UI thread, không round-trip qua bridge mỗi frame
```

Chỉ chuyển sang Reanimated khi animation `Animated` API đã đo bị giật/drop frame — không viết lại toàn bộ animation có sẵn "cho chắc".

## Ảnh và bundle

`react-native-fast-image` (hoặc `expo-image`) cho cache ảnh network khi `Image` mặc định gây re-fetch/flicker đã đo được; bật Hermes bytecode + kiểm tra bundle size bằng `npx react-native-bundle-visualizer` khi startup time là vấn đề thật, không đoán mò thêm lazy-load cho mọi thứ.

## Anti-pattern

- Wrap `useCallback`/`useMemo` quanh mọi hàm/giá trị "cho chắc" — chỉ dùng khi truyền xuống `React.memo` child hoặc dependency của effect khác, nếu không chỉ thêm chi phí so sánh vô ích.
- Inline function/object literal làm prop cho `React.memo` component mà không memo — làm memo vô nghĩa vì reference đổi mỗi render.
