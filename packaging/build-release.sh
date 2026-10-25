#!/bin/sh
# Build an Apple Silicon installer package on macOS. Signing/notarization is optional for CI previews.
set -eu
umask 077
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
[ "$(uname -s)" = Darwin ] || { echo 'Release packaging requires macOS.' >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || { echo 'Only arm64 release packaging is supported.' >&2; exit 1; }
BUNDLE="$ROOT/dist/bundle"
[ -d "$BUNDLE" ] || { echo 'Build the driver bundle first.' >&2; exit 1; }
sh "$ROOT/scripts/check-bundle.sh" "$BUNDLE"
if [ -n "${NOTARY_PROFILE:-}" ] && { [ -z "${DEVELOPER_ID_APPLICATION:-}" ] || [ -z "${DEVELOPER_ID_INSTALLER:-}" ]; }; then
  echo 'Notarization requires both Developer ID Application and Developer ID Installer identities.' >&2
  exit 1
fi
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  for binary in "$BUNDLE"/libs/* "$BUNDLE"/bin/gs "$BUNDLE"/bin/foo2zjs "$BUNDLE"/bin/gsed "$BUNDLE"/bin/dc; do
    [ -f "$binary" ] || continue
    /usr/bin/file "$binary" | /usr/bin/grep -q 'Mach-O' || continue
    /usr/bin/codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$binary"
  done
fi
WORK=$(mktemp -d "${TMPDIR:-/tmp}/hp1020-pkg.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
STAGE="$WORK/root"
mkdir -p "$STAGE/Library/Printers/hp-legacy-mac-package/dist" "$STAGE/Library/Printers/hp-legacy-mac-package/scripts" "$STAGE/Applications" "$WORK/scripts" "$WORK/app/Contents/Resources/firmware"
cp -R "$BUNDLE" "$STAGE/Library/Printers/hp-legacy-mac-package/dist/bundle"
cp "$ROOT/install.sh" "$STAGE/Library/Printers/hp-legacy-mac-package/install.sh"
cp "$ROOT/uninstall.sh" "$STAGE/Library/Printers/hp-legacy-mac-package/uninstall.sh"
cp "$ROOT/scripts/normalize-ppd.sh" "$STAGE/Library/Printers/hp-legacy-mac-package/scripts/normalize-ppd.sh"
cp "$ROOT/firmware/setup-firmware.applescript" "$WORK/setup-firmware.applescript"
cp "$ROOT/firmware/setup-firmware.sh" "$WORK/app/Contents/Resources/firmware/setup-firmware.sh"
cp "$ROOT/firmware/firmware-watch.sh" "$WORK/app/Contents/Resources/firmware/firmware-watch.sh"
cp "$ROOT/uninstall.sh" "$WORK/app/Contents/Resources/uninstall.sh"
/usr/bin/osacompile -o "$WORK/app/HP LaserJet Firmware Setup.app" "$WORK/setup-firmware.applescript"
APP="$WORK/app/HP LaserJet Firmware Setup.app"
mkdir -p "$APP/Contents/Resources/firmware"
cp "$WORK/app/Contents/Resources/firmware/"* "$APP/Contents/Resources/firmware/"
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  /usr/bin/codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
fi
cp -R "$APP" "$STAGE/Applications/HP LaserJet Firmware Setup.app"
cp "$ROOT/packaging/postinstall" "$WORK/scripts/postinstall"
chmod 755 "$WORK/scripts/postinstall"
mkdir -p "$ROOT/dist"
PKG="$ROOT/dist/HP-LaserJet-1020-Plus-macOS-arm64-unsigned.pkg"
/usr/bin/pkgbuild --root "$STAGE" --scripts "$WORK/scripts" --identifier com.hp-legacy-mac.hp1020plus --version 0.2.0 --install-location / "$PKG"
if [ -n "${DEVELOPER_ID_INSTALLER:-}" ]; then
  SIGNED="$ROOT/dist/HP-LaserJet-1020-Plus-macOS-arm64.pkg"
  /usr/bin/productsign --sign "$DEVELOPER_ID_INSTALLER" "$PKG" "$SIGNED"
  rm -f "$PKG"
  PKG="$SIGNED"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    /usr/bin/xcrun notarytool submit "$PKG" --keychain-profile "$NOTARY_PROFILE" --wait
    /usr/bin/xcrun stapler staple "$PKG"
  else echo 'Package signed, but not notarized. Gatekeeper may still warn.' >&2; fi
else echo 'UNSIGNED PREVIEW: not suitable for general distribution.' >&2; fi
/usr/bin/shasum -a 256 "$PKG" > "$PKG.sha256"
echo "Package created: $PKG"
