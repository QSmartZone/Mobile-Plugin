# Testing

## Jest + React Native Testing Library — unit/component test

Test behavior (người dùng thấy gì, tương tác gì) thay vì implementation detail (state nội bộ, tên hàm private) — dùng query theo role/text/label giống cách người dùng thật tìm phần tử.

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

test('hiển thị lỗi khi submit form trống', () => {
  render(<LoginForm />);
  fireEvent.press(screen.getByRole('button', { name: 'Đăng nhập' }));
  expect(screen.getByText('Email không được để trống')).toBeOnTheScreen();
});
```

Custom hook non-trivial (branch, loop, tính toán phức tạp) test qua `renderHook` từ cùng thư viện, không cần mount cả component chỉ để test logic hook.

```tsx
import { renderHook, act } from '@testing-library/react-native';

test('useToggle đổi giá trị khi gọi toggle', () => {
  const { result } = renderHook(() => useToggle(false));
  act(() => result.current[1]());
  expect(result.current[0]).toBe(true);
});
```

## Mock native module

Native module (camera, location, storage...) mock ở `jest.setup.js` hoặc per-test, không để test thật gọi native code (sẽ crash/hang trong môi trường Jest node). Expo SDK có sẵn `jest-expo` preset mock phần lớn module Expo mặc định.

```ts
jest.mock('expo-location', () => ({
  getCurrentPositionAsync: jest.fn().mockResolvedValue({ coords: { latitude: 0, longitude: 0 } }),
}));
```

## E2E: Detox hoặc Maestro

Chỉ cho luồng người dùng critical (login, checkout, luồng chính của app) — không bắt buộc cho mọi PR vì chi phí maintain và thời gian chạy cao hơn hẳn unit test.

- **Detox**: gắn sâu vào build process (cần build app riêng cho test), kiểm soát chi tiết, đồng bộ tốt với animation/network idle — phù hợp team đã đầu tư CI riêng cho E2E.
- **Maestro**: YAML flow đơn giản, không cần build đặc biệt, chạy trên app đã build thường — phù hợp muốn setup nhanh, ít maintain hơn Detox.

```yaml
# maestro: login-flow.yaml
appId: com.myapp
---
- launchApp
- tapOn: "Email"
- inputText: "user@example.com"
- tapOn: "Đăng nhập"
- assertVisible: "Trang chủ"
```

## Nguyên tắc

- Mỗi bug fix cần thêm 1 test tái hiện bug trước khi fix (regression test), không chỉ sửa code rồi bỏ qua test.
- Snapshot test dùng có chọn lọc — snapshot toàn bộ UI dễ trở thành "update snapshot" theo phản xạ mà không thật sự review đổi gì, ưu tiên assertion cụ thể hơn snapshot lớn.
- Test không phụ thuộc thứ tự chạy hoặc state global còn sót từ test trước — mỗi test tự setup/cleanup (`beforeEach`/`afterEach`).

## Chạy test đúng cách

- Chạy đúng file/test cần: `npx jest path/to/file.test.tsx -t "tên test"`, không chạy cả suite khi chỉ sửa 1 chỗ.
- Đọc dòng `●` báo fail đầu tiên trong output — đó là assertion thật sự sai, các dòng sau thường là hệ quả.
- Không dùng `--watch` trong agent/CI — process không tự thoát, làm treo session.
- Detox/Maestro chỉ chạy khi thay đổi chạm luồng E2E critical, không chạy mặc định mỗi lần sửa code.
- Lỗi transform/module lạ không liên quan đến code vừa sửa → thử `npx jest --clearCache` trước khi debug sâu.
