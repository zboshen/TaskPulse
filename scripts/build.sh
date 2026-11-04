#!/bin/zsh
set -eu
cd "${0:A:h:h}"
APP="$PWD/dist/TaskPulse.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for ARCH in arm64 x86_64; do
  xcrun swiftc -O -swift-version 5 -target "$ARCH-apple-macosx15.0" Sources/*.swift -o "$PWD/dist/TaskPulse-$ARCH" -framework AppKit -framework SwiftUI -framework ServiceManagement -lsqlite3
done
lipo -create "$PWD/dist/TaskPulse-arm64" "$PWD/dist/TaskPulse-x86_64" -output "$APP/Contents/MacOS/TaskPulse"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>TaskPulse</string>
<key>CFBundleIdentifier</key><string>site.momentu.taskpulse</string>
<key>CFBundleName</key><string>TaskPulse</string>
<key>CFBundleDisplayName</key><string>TaskPulse</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string><string>zh-Hant</string></array>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleVersion</key><string>4</string>
<key>CFBundleShortVersionString</key><string>0.3.1</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
cp -R Resources/* "$APP/Contents/Resources/"
cp assets/AppIcon.icns "$APP/Contents/Resources/"
cp LICENSE "$APP/Contents/Resources/"
cp LICENSE-Codenotch "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
print "Built: $APP"
