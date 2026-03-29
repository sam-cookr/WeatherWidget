#!/bin/bash
set -e

APP_NAME="WeatherWidget"
BUNDLE_ID="com.samcooke.WeatherWidget"
VERSION="1.1"

echo "==> Building $APP_NAME $VERSION (release)..."
swift build -c release
RELEASE_DIR=$(swift build -c release --show-bin-path)

echo "==> Generating icon..."
swift generate_icon.swift
mkdir -p icon.iconset
sips -z 16   16   icon.png --out icon.iconset/icon_16x16.png
sips -z 32   32   icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32   32   icon.png --out icon.iconset/icon_32x32.png
sips -z 64   64   icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128  128  icon.png --out icon.iconset/icon_128x128.png
sips -z 256  256  icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256  256  icon.png --out icon.iconset/icon_256x256.png
sips -z 512  512  icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512  512  icon.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png
iconutil -c icns icon.iconset
rm -rf icon.iconset icon.png

echo "==> Creating $APP_NAME.app bundle..."
APP_DIR="$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$RELEASE_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"
cp icon.icns "$APP_DIR/Contents/Resources/"
rm icon.icns

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Creating $APP_NAME.dmg..."
STAGING=$(mktemp -d)
cp -r "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

DMG_NAME="$APP_NAME.dmg"
rm -f "$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_NAME"

rm -rf "$STAGING"

echo ""
echo "Done!"
echo "  App bundle : $APP_DIR"
echo "  Disk image : $DMG_NAME"
echo ""
echo "To install: open $DMG_NAME and drag $APP_NAME to Applications."
