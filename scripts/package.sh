#!/bin/zsh
set -eu
cd "${0:A:h:h}"
APP="$PWD/dist/TaskPulse.app"
[[ -d "$APP" ]] || ./scripts/build.sh
mkdir -p dist/dmg-root
# Stage only the redistributable application; never include local task databases.
ditto "$APP" dist/dmg-root/TaskPulse.app
[[ -L dist/dmg-root/Applications ]] || ln -s /Applications dist/dmg-root/Applications
ditto -c -k --sequesterRsrc --keepParent "$APP" dist/TaskPulse.zip
hdiutil create -volname TaskPulse -srcfolder dist/dmg-root -ov -format UDZO dist/TaskPulse.dmg
shasum -a 256 dist/TaskPulse.dmg dist/TaskPulse.zip > dist/SHA256SUMS.txt
