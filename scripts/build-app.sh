#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
BUILD_ARGS=(-c release --disable-sandbox)
if [[ "${WINDOWSNAP_UNIVERSAL:-0}" == "1" ]]; then
    BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
APP="$PWD/dist/WindowSnap.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/WindowSnap" "$APP/Contents/MacOS/WindowSnap"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign "${WINDOWSNAP_SIGN_IDENTITY:--}" "$APP"
codesign --verify --strict "$APP"
printf 'Built: %s\n' "$APP"
