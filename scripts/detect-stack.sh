#!/bin/sh
# Detect mobile stack (flutter/android/ios/react-native) from manifest files in a dir.
# Usage: detect-stack.sh [dir]  (default: .)
set -eu

dir="${1:-.}"
platforms=""
has() { [ -f "$dir/$1" ]; }
grep_q() { grep -q -- "$1" "$dir/$2" 2>/dev/null; }
# word-boundary match so "bloc:" doesn't hit inside "flutter_bloc:"
grep_word() { grep -Eq -- "(^|[^A-Za-z0-9_])$1" "$dir/$2" 2>/dev/null; }

if has pubspec.yaml; then
  platforms="flutter"
fi
if has package.json && grep_q '"react-native"' package.json; then
  platforms="${platforms:+$platforms,}react-native"
fi
if has settings.gradle || has settings.gradle.kts || has build.gradle || has build.gradle.kts; then
  platforms="${platforms:+$platforms,}android"
fi
if ls "$dir"/*.xcodeproj >/dev/null 2>&1 || ls "$dir"/*.xcworkspace >/dev/null 2>&1 || has Package.swift; then
  platforms="${platforms:+$platforms,}ios"
fi

if [ -z "$platforms" ]; then
  echo "platform: unknown"
  exit 0
fi

echo "platform: $platforms"

libs=""
add_lib() {
  case ",$libs," in
    *",$1,"*) ;;
    *) libs="${libs:+$libs, }$1" ;;
  esac
}

case ",$platforms," in
  *",flutter,"*)
    for lib in flutter_bloc bloc riverpod provider go_router dio; do
      grep_word "$lib:" pubspec.yaml && add_lib "$lib"
    done
    ;;
esac
case ",$platforms," in
  *",react-native,"*)
    for lib in expo zustand redux "@tanstack/react-query" "@react-navigation"; do
      grep_q "\"$lib\"" package.json && add_lib "$lib"
    done
    ;;
esac
case ",$platforms," in
  *",android,"*)
    for f in build.gradle build.gradle.kts app/build.gradle app/build.gradle.kts; do
      [ -f "$dir/$f" ] || continue
      for lib in hilt koin retrofit ktor compose; do
        grep_q "$lib" "$f" && add_lib "$lib"
      done
    done
    ;;
esac
case ",$platforms," in
  *",ios,"*)
    for lib in alamofire combine swiftui; do
      grep -riq -- "$lib" "$dir"/Podfile "$dir"/Package.swift 2>/dev/null && add_lib "$lib"
    done
    ;;
esac
[ -n "$libs" ] && echo "libs: $libs"

case ",$platforms," in
  *",flutter,"*)
    echo "test: flutter test"
    echo "analyze: flutter analyze"
    echo "build: flutter build apk --debug"
    ;;
  *",android,"*)
    echo "test: ./gradlew testDebugUnitTest"
    echo "analyze: ./gradlew lintDebug"
    echo "build: ./gradlew assembleDebug"
    ;;
  *",ios,"*)
    echo "test: xcodebuild test -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:<Target>"
    echo "analyze: xcodebuild build -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO  # note: scheme từ xcodebuild -list"
    echo "build: xcodebuild build -scheme <Scheme> -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO"
    ;;
  *",react-native,"*)
    echo "test: npx jest"
    echo "analyze: npx tsc --noEmit && npx eslint ."
    echo "build: npx react-native run-android --mode=debug"
    ;;
esac
