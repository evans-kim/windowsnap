#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
WINDOWSNAP_UNIVERSAL=1 bash scripts/build-app.sh
APP=dist/WindowSnap.app
lipo "$APP/Contents/MacOS/WindowSnap" -verify_arch arm64 x86_64
plutil -lint "$APP/Contents/Info.plist"
codesign --verify --strict "$APP"
# Keep the stable asset name so the website's latest-release download always works.
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/WindowSnap-universal.zip
(cd dist && shasum -a 256 WindowSnap-universal.zip > SHA256SUMS.txt)
printf 'Packaged universal release in dist/\n'
