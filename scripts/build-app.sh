#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swift build -c release --product GentleNight
app="dist/Gentle Night.app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/GentleNight "$app/Contents/MacOS/GentleNight"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>GentleNight</string>
<key>CFBundleIdentifier</key><string>io.github.li1fang.gentle-night</string>
<key>CFBundleName</key><string>Gentle Night</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
plutil -lint "$app/Contents/Info.plist"
printf 'Built %s\n' "$app"
