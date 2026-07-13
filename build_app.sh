#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_DIR="$ROOT_DIR/FolderManifest.app"

cd "$ROOT_DIR"
xcodebuild -quiet -project FolderManifest.xcodeproj -scheme FolderManifest -configuration Release -derivedDataPath .xcode-derived CODE_SIGNING_ALLOWED=NO build

rm -rf "$APP_DIR"
ditto "$ROOT_DIR/.xcode-derived/Build/Products/Release/FolderManifest.app" "$APP_DIR"

codesign --force --deep --sign - "$APP_DIR"
echo "已生成：$APP_DIR"
