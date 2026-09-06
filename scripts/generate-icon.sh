#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache"
swift scripts/generate-icon.swift
iconutil -c icns .build/WindowSnap.iconset -o Resources/AppIcon.icns
mkdir -p docs/assets
cp Resources/AppIcon.png docs/assets/app-icon.png
