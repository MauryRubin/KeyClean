#!/usr/bin/env bash
# Builds KeyClean, wraps it in an app bundle, signs it ad hoc, and installs it.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/KeyClean.app"
DEST="$HOME/Applications/KeyClean.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/KeyClean"

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/KeyClean"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

pkill -x KeyClean || true
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "Installed $DEST"
echo "Open it with: open \"$DEST\""
