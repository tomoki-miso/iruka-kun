#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="IrukaKun"
CONFIGURATION="Release"

# --- バージョン取得 ---
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PROJECT_DIR/IrukaKun/Info.plist")
DMG_NAME="IrukaKun-${VERSION}.dmg"
echo "==> Building iruka-kun v${VERSION}"

# --- XcodeGen ---
echo "==> Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate

# --- xcodebuild ---
echo "==> Building Release..."
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
xcodebuild \
    -project IrukaKun.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/iruka-kun.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Error: iruka-kun.app not found at $APP_PATH"
    exit 1
fi

# --- DMG 作成 ---
echo "==> Creating DMG..."
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

DMG_PATH="$BUILD_DIR/$DMG_NAME"
rm -f "$DMG_PATH"
mkdir -p "$BUILD_DIR"

hdiutil create \
    -volname "iruka-kun" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "==> Done: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
