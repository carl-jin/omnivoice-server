#!/usr/bin/env bash
# Build the macOS one-dir bundle with PyInstaller and wrap it in a .dmg.
#
# Run from the repo root inside a venv that has the project + build deps:
#   pip install . pyinstaller
#   pip install torch==2.8.0 torchaudio==2.8.0
#   bash packaging/build_macos.sh
#
# Output: dist/OmniVoice-Server-macos-arm64.dmg
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="$(python -c 'import omnivoice_server; print(omnivoice_server.__version__)')"
ARCH="$(uname -m)"
DMG_NAME="OmniVoice-Server-${VERSION}-macos-${ARCH}.dmg"
VOL_NAME="OmniVoice Server"
STAGE="build/dmg-stage"

echo "==> PyInstaller freeze (onedir)"
pyinstaller packaging/omnivoice-server.spec --noconfirm --distpath dist --workpath build/pyi

echo "==> Ad-hoc codesign (lets the binary run locally without a paid cert)"
codesign --force --deep --sign - "dist/omnivoice-server/omnivoice-server" || \
  echo "   (ad-hoc sign failed; binary may still run, Gatekeeper may complain)"

echo "==> Staging dmg contents"
rm -rf "$STAGE"
mkdir -p "$STAGE/$VOL_NAME"
cp -R "dist/omnivoice-server" "$STAGE/$VOL_NAME/omnivoice-server"
cp "packaging/macos/Start OmniVoice Server.command" "$STAGE/$VOL_NAME/"
cp "packaging/macos/README.txt" "$STAGE/$VOL_NAME/"
chmod +x "$STAGE/$VOL_NAME/Start OmniVoice Server.command"
ln -s /Applications "$STAGE/Applications"

echo "==> Building dmg: $DMG_NAME"
rm -f "dist/$DMG_NAME"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "dist/$DMG_NAME"

echo "==> Done: dist/$DMG_NAME"
du -h "dist/$DMG_NAME"
