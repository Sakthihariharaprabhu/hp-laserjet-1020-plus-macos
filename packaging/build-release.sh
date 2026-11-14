#!/bin/sh
# Build an Apple Silicon installer package on macOS. Signing/notarization is optional for CI previews.
set -eu
umask 077
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
[ "$(uname -s)" = Darwin ] || { echo 'Release packaging requires macOS.' >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || { echo 'Only arm64 release packaging is supported.' >&2; exit 1; }
BUNDLE="$ROOT/dist/bundle"
VERSION=$(sed -n '1p' "$ROOT/VERSION")
case "$VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "VERSION file is missing or malformed: '$VERSION'" >&2; exit 1 ;;
esac
# If CI builds a tag, the tag must be exactly v<VERSION> so the release name and package version match.
if [ -n "${GITHUB_REF_TYPE:-}" ] && [ "$GITHUB_REF_TYPE" = tag ] && [ "${GITHUB_REF_NAME:-}" != "v$VERSION" ]; then
  echo "Tag ${GITHUB_REF_NAME:-} does not match VERSION v$VERSION." >&2; exit 1
fi
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
cp "$ROOT/firmware/fetch-firmware.sh" "$WORK/app/Contents/Resources/firmware/fetch-firmware.sh"
cp "$ROOT/firmware/firmware-watch.sh" "$WORK/app/Contents/Resources/firmware/firmware-watch.sh"
cp "$ROOT/firmware/status.sh" "$WORK/app/Contents/Resources/firmware/status.sh"
cp "$ROOT/firmware/set-offset.sh" "$WORK/app/Contents/Resources/firmware/set-offset.sh"
cp "$ROOT/src/hp1020-clip" "$WORK/app/Contents/Resources/firmware/hp1020-clip"
cp "$BUNDLE/bin/arm2hpdl" "$WORK/app/Contents/Resources/firmware/arm2hpdl"
/usr/bin/osacompile -o "$WORK/app/HP LaserJet Firmware Setup.app" "$WORK/setup-firmware.applescript"
APP="$WORK/app/HP LaserJet Firmware Setup.app"
mkdir -p "$APP/Contents/Resources/firmware"
cp "$WORK/app/Contents/Resources/firmware/"* "$APP/Contents/Resources/firmware/"
# The uninstaller must live inside the actual compiled app bundle; the package postinstall removes its staging tree.
cp "$ROOT/uninstall.sh" "$APP/Contents/Resources/uninstall.sh"
cp "$ROOT/calibration/a4-alignment-test.pdf" "$APP/Contents/Resources/a4-alignment-test.pdf"
printf '%s\n' "$VERSION" > "$APP/Contents/Resources/VERSION"
# Normalize the GUI app's permissions before signing; umask 077 otherwise makes
# the applet and metadata owner-only and prevents a normal user from launching it.
find "$APP" -type d -exec chmod 755 {} \;
find "$APP" -type f -exec chmod 644 {} \;
find "$APP/Contents/MacOS" -type f -exec chmod 755 {} \;
chmod 755 "$APP/Contents/Resources/uninstall.sh"
chmod 755 "$APP/Contents/Resources/firmware/arm2hpdl"
[ -s "$APP/Contents/Resources/a4-alignment-test.pdf" ] || { echo 'Calibration page is missing from the app.' >&2; exit 1; }
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  /usr/bin/codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP/Contents/Resources/firmware/arm2hpdl"
  /usr/bin/codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP"
fi
/usr/bin/ditto "$APP" "$STAGE/Applications/HP LaserJet Firmware Setup.app"
cp "$ROOT/packaging/postinstall" "$WORK/scripts/postinstall"
chmod 755 "$WORK/scripts/postinstall"
# The staging umask is deliberately private; package install directories must not
# inherit mode 0700. Normalize every payload directory, but preserve app file modes.
find "$STAGE" -type d -exec chmod 755 {} \;
[ -x "$STAGE/Applications/HP LaserJet Firmware Setup.app/Contents/MacOS/applet" ] || { echo 'Firmware setup applet is not executable.' >&2; exit 1; }
[ -r "$STAGE/Applications/HP LaserJet Firmware Setup.app/Contents/Info.plist" ] || { echo 'Firmware setup app metadata is unreadable.' >&2; exit 1; }
[ -x "$STAGE/Applications/HP LaserJet Firmware Setup.app/Contents/Resources/uninstall.sh" ] || { echo 'GUI uninstaller helper is not executable.' >&2; exit 1; }
mkdir -p "$ROOT/dist"
PKG="$ROOT/dist/HP-LaserJet-1020-Plus-macOS-arm64-unsigned.pkg"
/usr/bin/pkgbuild --ownership recommended --root "$STAGE" --scripts "$WORK/scripts" --identifier com.hp-legacy-mac.hp1020plus --version "$VERSION" --install-location / "$PKG"
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
# Write only the file name (not the build machine's path) so that
# `shasum -a 256 -c <file>.sha256` works on a user's Mac in the download folder.
( cd "$(dirname "$PKG")" && /usr/bin/shasum -a 256 "$(basename "$PKG")" ) > "$PKG.sha256"
grep -q '/' "$PKG.sha256" && { echo 'Checksum sidecar must not contain a path.' >&2; exit 1; }
( cd "$(dirname "$PKG")" && /usr/bin/shasum -a 256 -c "$(basename "$PKG").sha256" )
echo "Package created: $PKG (version $VERSION)"
