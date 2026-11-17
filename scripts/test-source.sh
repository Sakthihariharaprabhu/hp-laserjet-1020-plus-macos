#!/bin/sh
# shellcheck disable=SC2016  # patterns below are literal source text, not expansions
# Fast static checks; deliberately does not claim to validate binaries or printing.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

for file in install.sh uninstall.sh src/cups-filter build/build-bundle.sh \
  scripts/check-bundle.sh scripts/check-macho-deps.sh scripts/collect-source-archives.sh \
  scripts/normalize-ppd.sh firmware/setup-firmware.sh firmware/fetch-firmware.sh firmware/firmware-watch.sh \
  firmware/status.sh firmware/set-offset.sh src/hp1020-clip \
  scripts/smoke-driver-pipeline.sh packaging/postinstall packaging/build-release.sh; do
  sh -n "$ROOT/$file"
done

grep -q '^FOO2ZJS_COMMIT=80499ed5bf6caa2963ad337e37cfda78a80aab1e$' "$ROOT/build/build-bundle.sh"

# Regression checks for the GUI uninstall path. The package's postinstall deletes
# its temporary payload, so the uninstaller must be embedded in the compiled app.
grep -Fq 'cp "$ROOT/uninstall.sh" "$APP/Contents/Resources/uninstall.sh"' "$ROOT/packaging/build-release.sh"
for action in '"Set Up Firmware"' '"Check Status"' '"Print Alignment Test Page"' '"Adjust Print Position"' '"Uninstall Driver"'; do
  grep -Fq "$action" "$ROOT/firmware/setup-firmware.applescript" || { echo "App is missing action $action" >&2; exit 1; }
done
grep -Fq "Download and verify firmware automatically" "$ROOT/firmware/setup-firmware.applescript"
grep -Fq "Select a File Now" "$ROOT/firmware/setup-firmware.applescript"
grep -Fq -- "--retry 1" "$ROOT/firmware/fetch-firmware.sh"
grep -Fq -- "--connect-timeout 30" "$ROOT/firmware/fetch-firmware.sh"
[ -s "$ROOT/calibration/a4-alignment-test.pdf" ] || { echo "Calibration PDF is missing." >&2; exit 1; }
grep -Fq 'cp "$ROOT/calibration/a4-alignment-test.pdf"' "$ROOT/packaging/build-release.sh"

# Installer sets up firmware automatically, and never fails the install because of it.
grep -Fq 'fetch-firmware.sh' "$ROOT/packaging/postinstall"
grep -Fq 'open_app_for_user' "$ROOT/packaging/postinstall"
[ "$(tail -n 1 "$ROOT/packaging/postinstall")" = "exit 0" ] || { echo "postinstall must end with exit 0." >&2; exit 1; }
grep -Fq 'Set Up Now' "$ROOT/firmware/setup-firmware.applescript"

# Version: one source of truth.
grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$' "$ROOT/VERSION" || { echo "VERSION is malformed." >&2; exit 1; }
grep -Fq -- '--version "$VERSION"' "$ROOT/packaging/build-release.sh"
if grep -Eq -- '--version [0-9]' "$ROOT/packaging/build-release.sh"; then echo "Package version must come from VERSION." >&2; exit 1; fi
# Checksum sidecar must contain only the file name.
grep -Fq 'shasum -a 256 "$(basename "$PKG")"' "$ROOT/packaging/build-release.sh"

# Print-position helper: 0 mm must reproduce the wrapper's own default crop exactly.
CLIP="$ROOT/src/hp1020-clip"
[ "$(sh "$CLIP" args 1200 0 0)" = "-u 192x96 -l 192x96" ] || { echo "hp1020-clip default mismatch (1200 dpi)." >&2; exit 1; }
[ "$(sh "$CLIP" args 600 0 0)" = "-u 96x96 -l 96x96" ] || { echo "hp1020-clip default mismatch (600 dpi)." >&2; exit 1; }
[ "$(sh "$CLIP" args 1200 -3 0)" = "-u 334x96 -l 50x96" ] || { echo "hp1020-clip -3 mm mismatch." >&2; exit 1; }
[ "$(sh "$CLIP" args 1200 -10 -10)" = "-u 664x332 -l 0x0" ] || { echo "hp1020-clip -10 mm mismatch." >&2; exit 1; }
for bad in 5 -11 abc 1.234 '' '+1' '1;rm' '$(id)'; do
  if sh "$CLIP" check "$bad" 2>/dev/null; then echo "hp1020-clip accepted invalid value '$bad'." >&2; exit 1; fi
done
for good in 0 -3 -3.0 -2.5 4 -10 1.25; do
  sh "$CLIP" check "$good" || { echo "hp1020-clip rejected valid value '$good'." >&2; exit 1; }
done
grep -Fq 'HORIZONTAL_OFFSET_MM' "$ROOT/src/cups-filter"
grep -Fq -- '-dFIXEDMEDIA' "$ROOT/src/cups-filter"
grep -Fq 'HORIZONTAL_OFFSET_MM=%s' "$ROOT/install.sh"
grep -Fq "EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01" "$ROOT/firmware/fetch-firmware.sh"
grep -Fq "make arm2hpdl" "$ROOT/build/build-bundle.sh"
grep -Fq 'cp "$ROOT/firmware/fetch-firmware.sh" "$WORK/app/Contents/Resources/firmware/fetch-firmware.sh"' "$ROOT/packaging/build-release.sh"
grep -Fq 'find "$APP" -type d -exec chmod 755' "$ROOT/packaging/build-release.sh"
grep -Fq 'find "$APP" -type f -exec chmod 644' "$ROOT/packaging/build-release.sh"
grep -Fq 'chmod 755 "$APP/Contents/Resources/uninstall.sh"' "$ROOT/packaging/build-release.sh"
grep -Fq 'find "$APP/Contents/MacOS" -type f -exec chmod 755' "$ROOT/packaging/build-release.sh"
grep -Fq 'find "$STAGE" -type d -exec chmod 755' "$ROOT/packaging/build-release.sh"
grep -Fq '/usr/bin/ditto "$APP" "$STAGE/Applications/HP LaserJet Firmware Setup.app"' "$ROOT/packaging/build-release.sh"
grep -Fq '/usr/bin/pkgbuild --ownership recommended' "$ROOT/packaging/build-release.sh"

# Candidate must be installed alongside, never over, the original legacy driver.
grep -Fq 'BASE="/Library/Printers/hp-legacy-mac-plus"' "$ROOT/install.sh"
grep -Fq 'FILTER="/usr/libexec/cups/filter/hp-legacy-mac-plus"' "$ROOT/install.sh"
grep -Fq 'BASE=/Library/Printers/hp-legacy-mac-plus' "$ROOT/src/cups-filter"
if grep -Fq '/Library/Printers/hp-legacy-mac"' "$ROOT/install.sh"; then
  echo "Candidate installer must not overwrite the legacy driver path." >&2
  exit 1
fi

# Exercise the PPD normalizer and assert that it sets A4 defaults.
PPD_IN=$(mktemp)
PPD_OUT=$(mktemp)
trap 'rm -f "$PPD_IN" "$PPD_OUT"' EXIT HUP INT TERM
cat > "$PPD_IN" <<'PPD'
*DefaultPageSize: Letter
*DefaultPageRegion: Letter
*DefaultImageableArea: Letter
*DefaultPaperDimension: Letter
*ImageableArea A4/A4: "11.34 11.34 583.66 830.66"
*PaperDimension A4/A4: "595 842"
PPD
sh "$ROOT/scripts/normalize-ppd.sh" "$PPD_IN" "$PPD_OUT"
grep -Fq '*DefaultPageSize: A4' "$PPD_OUT"
grep -Fq '*DefaultPageRegion: A4' "$PPD_OUT"
grep -Fq '*DefaultImageableArea: A4' "$PPD_OUT"
grep -Fq '*DefaultPaperDimension: A4' "$PPD_OUT"

if grep -Eq '^[[:space:]]*(eval|source)[[:space:]]' "$ROOT/src/cups-filter"; then
  echo "Filter must not evaluate or source configuration." >&2
  exit 1
fi
if grep -Eq 'curl|wget|https?://' "$ROOT/install.sh"; then
  echo "Installer must not fetch remote content." >&2
  exit 1
fi
if grep -Eq 'chmod[[:space:]]+0?700[[:space:]]+/usr/libexec/cups/backend/usb|csrutil|spctl[[:space:]]+--master-disable' "$ROOT/install.sh"; then
  echo "Installer must not weaken system security settings." >&2
  exit 1
fi
if find "$ROOT" -type f -iname 'sihp1020.dl' | grep . >/dev/null 2>&1; then
  echo "Firmware must not be committed." >&2
  exit 1
fi
grep -q 'EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01' "$ROOT/firmware/setup-firmware.sh"
grep -q 'EXPECTED=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01' "$ROOT/firmware/firmware-watch.sh"

if grep -Fq "printf '%s\\\\n'" "$ROOT/build/build-bundle.sh" || grep -Fq "%s\\\\n' \"\$ARCH\"" "$ROOT/build/build-bundle.sh"; then
  echo "Build manifest must use real line breaks, not escaped literal backslash-n text." >&2
  exit 1
fi
if grep -Fq '\\n' "$ROOT/scripts/collect-source-archives.sh"; then
  echo "Source archive manifest must use real line breaks, not escaped literal backslash-n text." >&2
  exit 1
fi
echo "Static source checks passed (not a build or print test)."
