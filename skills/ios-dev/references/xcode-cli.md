# Xcode/Simulator CLI — chi tiết

## Simulator

```
xcrun simctl list devices available          # liệt kê simulator có sẵn, lấy UDID
xcrun simctl boot <udid>                     # bật simulator
xcrun simctl install <udid> <path.app>       # cài app đã build
xcrun simctl launch --console <udid> <bundle-id>   # chạy app, in log stdout/stderr ra terminal
xcrun simctl io <udid> screenshot out.png    # chụp màn hình simulator
xcrun simctl spawn <udid> log stream --predicate 'subsystem == "<bundle-id>"'   # xem log runtime theo bundle
xcrun simctl openurl <udid> "myapp://path"   # test deep link/universal link
xcrun simctl privacy <udid> grant camera <bundle-id>   # cấp quyền trước để test flow không bị chặn dialog
xcrun simctl shutdown all                    # tắt hết simulator (khi simulator treo)
xcrun simctl erase <udid>                    # reset simulator về factory (mất data/app đã cài)
```

## Build & scheme

```
xcodebuild -list                             # xem scheme/target/config có trong project
xcodebuild -showdestinations -scheme <S>     # liệt kê destination hợp lệ (simulator/device) cho scheme
xcodebuild build -scheme <S> -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath build | tail -20   # build không cần ký, output gọn vào ./build
```

Cài `xcbeautify` (brew) để log build dễ đọc hơn: pipe `| xcbeautify` thay cho `| tail -20`, optional không bắt buộc.

## Device thật

```
xcrun devicectl list devices                          # liệt kê device đã pair
xcrun devicectl device install app --device <id> <path.app>   # cài app lên device thật
```

## Ghi chú

- `-derivedDataPath build` giữ output build trong project thay vì thư mục DerivedData toàn cục — dễ dọn (`rm -rf build`), tránh lẫn cache giữa các branch.
- Mọi lệnh `simctl`/`devicectl` cần Xcode command line tools đã trỏ đúng (`xcode-select -p`), không phải chỉ Command Line Tools rời.
