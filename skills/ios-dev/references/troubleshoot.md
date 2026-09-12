# Troubleshoot iOS — chi tiết

| Triệu chứng | Lệnh kiểm tra | Fix |
|---|---|---|
| Pod install lỗi/version conflict | `pod repo list` | `pod repo update`, hoặc `pod deintegrate && pod install` |
| Build fail "signing" trên simulator | `xcodebuild -showBuildSettings \| grep CODE_SIGN` | Thêm `CODE_SIGNING_ALLOWED=NO` khi build cho simulator |
| "No such module '<X>'" | `ls ~/Library/Developer/Xcode/DerivedData` | Xoá DerivedData của project, `xcodebuild -resolvePackageDependencies` |
| App Store reject thiếu Privacy Manifest | `find . -name PrivacyInfo.xcprivacy` | Thêm `PrivacyInfo.xcprivacy` cho target (bắt buộc từ 5/2024) |
| Simulator không boot/treo | `xcrun simctl list devices` | `xcrun simctl shutdown all`, không hết thì `xcrun simctl erase <udid>` |
| Build treo lúc "Resolving Package Graph" | Xcode > Package Dependencies | `rm -rf ~/Library/Caches/org.swift.swiftpm`, mở lại project |
| Crash ngay khi request permission | Kiểm tra `Info.plist` | Thêm đúng key `NSXxxUsageDescription` trước khi gọi API xin quyền |
