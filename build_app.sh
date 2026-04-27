#!/bin/bash
set -e

APP_NAME="WeatherWidget"
BUNDLE_ID="com.samcooke.WeatherWidget"
VERSION="1.10.2"
BUILD_NUMBER="1102"
SIGN_ID="Developer ID Application: SAMUEL ROBERT COOK (56GYTHWZCC)"
NOTARIZE_PROFILE="notarytool-creds"
SPARKLE_ACCOUNT="com.samcooke.WeatherWidget"
SPARKLE_PUBLIC_KEY="1Q0tDyjW02VRZ4Q/fiE7ixKqbRI5bN1xUmd2yFYw1o4="
APPCAST_URL="https://github.com/sam-cookr/WeatherWidget/releases/latest/download/appcast.xml"
DOWNLOAD_URL="https://github.com/sam-cookr/WeatherWidget/releases/download/v$VERSION/WeatherWidget.dmg"

# ── Build ──────────────────────────────────────────────────────────────────
echo "==> Building $APP_NAME $VERSION (release)..."
swift build -c release
RELEASE_DIR=$(swift build -c release --show-bin-path 2>/dev/null)

# ── Icon ───────────────────────────────────────────────────────────────────
echo "==> Generating icon..."
swift scripts/generate_icon.swift
mkdir -p icon.iconset
sips -z 16   16   icon.png --out icon.iconset/icon_16x16.png    2>/dev/null
sips -z 32   32   icon.png --out icon.iconset/icon_16x16@2x.png 2>/dev/null
sips -z 32   32   icon.png --out icon.iconset/icon_32x32.png    2>/dev/null
sips -z 64   64   icon.png --out icon.iconset/icon_32x32@2x.png 2>/dev/null
sips -z 128  128  icon.png --out icon.iconset/icon_128x128.png  2>/dev/null
sips -z 256  256  icon.png --out icon.iconset/icon_128x128@2x.png 2>/dev/null
sips -z 256  256  icon.png --out icon.iconset/icon_256x256.png  2>/dev/null
sips -z 512  512  icon.png --out icon.iconset/icon_256x256@2x.png 2>/dev/null
sips -z 512  512  icon.png --out icon.iconset/icon_512x512.png  2>/dev/null
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png 2>/dev/null
iconutil -c icns icon.iconset
rm -rf icon.iconset icon.png

# ── App bundle ─────────────────────────────────────────────────────────────
echo "==> Creating $APP_NAME.app bundle..."
APP_DIR="$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/Frameworks"

cp "$RELEASE_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"
if [ -d "$RELEASE_DIR/Sparkle.framework" ]; then
    ditto "$RELEASE_DIR/Sparkle.framework" "$APP_DIR/Contents/Frameworks/Sparkle.framework"
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true
fi
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
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUFeedURL</key>
    <string>$APPCAST_URL</string>
    <key>SUPublicEDKey</key>
    <string>$SPARKLE_PUBLIC_KEY</string>
</dict>
</plist>
EOF

# ── Code sign ──────────────────────────────────────────────────────────────
echo "==> Code signing (Developer ID)..."
codesign --force --deep --options runtime \
    --sign "$SIGN_ID" \
    --identifier "$BUNDLE_ID" \
    "$APP_DIR"

# ── DMG ────────────────────────────────────────────────────────────────────
echo "==> Generating DMG background..."
swift scripts/generate_dmg_background.swift

echo "==> Creating $APP_NAME.dmg..."

RW_DMG="/tmp/WeatherWidget-rw-$$.dmg"
VOLUME="/Volumes/$APP_NAME"

# Detach any leftover volume from a previous failed run
hdiutil detach "$VOLUME" -quiet 2>/dev/null || true
rm -f "$RW_DMG"

# Cleanup on exit (success or failure)
trap 'hdiutil detach "$VOLUME" -quiet 2>/dev/null; rm -f "$RW_DMG" dmg_background.png' EXIT

# Create a fresh read-write HFS+ image
hdiutil create -volname "$APP_NAME" -size 60m -fs "HFS+" -type UDIF "$RW_DMG"

# Mount read-write
hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" > /dev/null

# Populate
ditto "$APP_DIR"    "$VOLUME/$APP_DIR"
ln -s /Applications "$VOLUME/Applications"
mkdir               "$VOLUME/.background"
cp dmg_background.png "$VOLUME/.background/background.png"

# Style: background, icon size/positions, window bounds
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 760, 430}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" to {140, 155}
        set position of item "Applications"   to {420, 155}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$VOLUME" -quiet
trap - EXIT   # clear trap; manual cleanup below

# Convert to compressed, read-only DMG
DMG_NAME="$APP_NAME.dmg"
rm -f "$DMG_NAME"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"

# Cleanup
rm -f "$RW_DMG" dmg_background.png

# ── Notarize + staple ──────────────────────────────────────────────────────
echo "==> Code signing $DMG_NAME..."
codesign --force --sign "$SIGN_ID" "$DMG_NAME"

echo "==> Submitting $DMG_NAME to Apple notary service (this may take a minute)..."
xcrun notarytool submit "$DMG_NAME" \
    --keychain-profile "$NOTARIZE_PROFILE" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_NAME"

echo "==> Generating Sparkle appcast..."
SPARKLE_SIGN_OUTPUT=$(.build/artifacts/sparkle/Sparkle/bin/sign_update \
    --account "$SPARKLE_ACCOUNT" \
    "$DMG_NAME")
SPARKLE_SIGNATURE=$(printf '%s\n' "$SPARKLE_SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
SPARKLE_LENGTH=$(printf '%s\n' "$SPARKLE_SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')
PUB_DATE=$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")

cat > appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>WeatherWidget Updates</title>
        <description>Latest WeatherWidget releases.</description>
        <language>en</language>
        <item>
            <title>WeatherWidget $VERSION</title>
            <link>https://github.com/sam-cookr/WeatherWidget/releases/tag/v$VERSION</link>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:releaseNotesLink>https://github.com/sam-cookr/WeatherWidget/releases/tag/v$VERSION</sparkle:releaseNotesLink>
            <pubDate>$PUB_DATE</pubDate>
            <enclosure url="$DOWNLOAD_URL" length="$SPARKLE_LENGTH" type="application/x-apple-diskimage" sparkle:edSignature="$SPARKLE_SIGNATURE" />
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
EOF

echo ""
echo "Done!"
echo "  App bundle : $APP_DIR"
echo "  Disk image : $DMG_NAME (notarized + stapled)"
echo "  Appcast    : appcast.xml"
echo ""
echo "To install: open $DMG_NAME and drag $APP_NAME to Applications."
