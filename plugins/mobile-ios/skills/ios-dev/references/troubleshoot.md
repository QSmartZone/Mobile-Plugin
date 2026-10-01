# iOS Troubleshoot — details

| Symptom | Check command | Fix |
|---|---|---|
| Pod install error/version conflict | `pod repo list` | `pod repo update`, or `pod deintegrate && pod install` |
| Build fails with "signing" on simulator | `xcodebuild -showBuildSettings \| grep CODE_SIGN` | Add `CODE_SIGNING_ALLOWED=NO` when building for simulator |
| "No such module '<X>'" | `ls ~/Library/Developer/Xcode/DerivedData` | Delete the project's DerivedData, `xcodebuild -resolvePackageDependencies` |
| App Store rejects for missing Privacy Manifest | `find . -name PrivacyInfo.xcprivacy` | Add `PrivacyInfo.xcprivacy` for the target (required since 5/2024) |
| Simulator won't boot/hangs | `xcrun simctl list devices` | `xcrun simctl shutdown all`, if still stuck `xcrun simctl erase <udid>` |
| Build hangs at "Resolving Package Graph" | Xcode > Package Dependencies | `rm -rf ~/Library/Caches/org.swift.swiftpm`, reopen the project |
| Crash right when requesting permission | Check `Info.plist` | Add the correct `NSXxxUsageDescription` key before calling the permission API |
