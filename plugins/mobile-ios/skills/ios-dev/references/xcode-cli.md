# Xcode/Simulator CLI — details

## Simulator

```
xcrun simctl list devices available          # list available simulators, get UDID
xcrun simctl boot <udid>                     # boot the simulator
xcrun simctl install <udid> <path.app>       # install the built app
xcrun simctl launch --console <udid> <bundle-id>   # run the app, print stdout/stderr logs to the terminal
xcrun simctl io <udid> screenshot out.png    # take a simulator screenshot
xcrun simctl spawn <udid> log stream --predicate 'subsystem == "<bundle-id>"'   # view runtime logs by bundle
xcrun simctl openurl <udid> "myapp://path"   # test deep link/universal link
xcrun simctl privacy <udid> grant camera <bundle-id>   # grant permission up front so the flow isn't blocked by a dialog
xcrun simctl shutdown all                    # shut down all simulators (when the simulator hangs)
xcrun simctl erase <udid>                    # reset the simulator to factory (loses data/installed apps)
```

## Build & scheme

```
xcodebuild -list                             # show schemes/targets/configs in the project
xcodebuild -showdestinations -scheme <S>     # list valid destinations (simulator/device) for the scheme
xcodebuild build -scheme <S> -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath build | tail -20   # build without signing, concise output into ./build
```

Install `xcbeautify` (brew) for more readable build logs: pipe `| xcbeautify` instead of `| tail -20`, optional, not required.

## Real device

```
xcrun devicectl list devices                          # list paired devices
xcrun devicectl device install app --device <id> <path.app>   # install the app on a real device
```

## Notes

- `-derivedDataPath build` keeps build output inside the project instead of the global DerivedData folder — easy to clean (`rm -rf build`), avoids cache mixing between branches.
- All `simctl`/`devicectl` commands need Xcode command line tools pointed correctly (`xcode-select -p`), not just the standalone Command Line Tools.
