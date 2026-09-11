# Native module / platform code

## Chỉ viết khi thật sự cần

Trước khi viết native module, kiểm tra Expo SDK, package cộng đồng (react-native-community, hoặc lib phổ biến đã maintain tốt) đã cover API native đó chưa — viết native module tay là chi phí maintain dài hạn (phải tự theo kịp thay đổi OS, tự test trên cả 2 platform).

## Bridge cũ vs JSI/TurboModules/Fabric

Kiến trúc mới (New Architecture: TurboModules cho native module, Fabric cho native UI component) dùng JSI (JavaScript Interface) gọi trực tiếp C++ giữa JS và native, không qua bridge async serialize JSON như kiến trúc cũ — nhanh hơn, type-safe hơn nhờ codegen từ TypeScript spec.

```ts
// TurboModule spec (TypeScript) — codegen tạo native interface từ đây
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  getBatteryLevel(): Promise<number>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('BatteryModule');
```

React Native 0.68-0.75 mở New Architecture cho opt-in thử nghiệm, chưa phải mặc định và chưa ổn định trên diện rộng; từ 0.76 (10/2024) New Architecture mới thành mặc định cho project mới. Kiểm tra `newArchEnabled` trong `gradle.properties`/`Podfile` trước khi viết module mới; viết theo TurboModule/Fabric thay vì bridge cũ (`NativeModules`/`requireNativeComponent`) nếu project đã bật New Architecture, để tránh viết xong phải migrate lại.

Bridge cũ (`NativeModules`) vẫn còn trong project chưa migrate New Architecture — không tự ý migrate 1 module riêng lẻ sang TurboModule khi phần còn lại của app vẫn dùng bridge cũ, dễ xung đột runtime.

## Expo Modules API — cách viết native module trong hệ Expo

Với project Expo (kể cả đã prebuild), ưu tiên Expo Modules API thay vì viết TurboModule tay — API đơn giản hơn, tự tích hợp autolinking và config plugin.

```kotlin
// android: ExampleModule.kt
class ExampleModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExampleModule")
    AsyncFunction("getBatteryLevel") {
      // đọc battery level native
    }
  }
}
```

## Config plugin

Khi native module cần thay đổi `Info.plist`/`AndroidManifest.xml`/Podfile mà không muốn tự tay sửa (mất khi prebuild lại), viết config plugin đi kèm module — plugin chạy lúc `expo prebuild` để tự động patch file native.

## Nguyên tắc

- Wrapper JS/TS che native module đi 1 lớp service (`src/lib/battery.ts`) — UI gọi qua wrapper, không import thẳng `NativeModules.BatteryModule` rải rác nhiều component, để sau này đổi implementation không phải sửa nhiều nơi.
- Test native module qua mock ở tầng JS, không cố chạy code native thật trong Jest.
- Permission runtime (camera, location, notification...) luôn qua API permission có sẵn trong từng module Expo tương ứng (`expo-camera`, `expo-location`... đều tự có hàm request/check permission riêng) cho managed workflow, hoặc `react-native-permissions` cho bare workflow. Kiểm tra trạng thái trước khi gọi API cần quyền, không giả định permission đã được cấp.
