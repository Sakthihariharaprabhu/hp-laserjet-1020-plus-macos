#!/bin/sh
# Fast static checks; deliberately does not claim to validate binaries or printing.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for file in install.sh uninstall.sh src/cups-filter build/build-bundle.sh scripts/check-bundle.sh scripts/check-macho-deps.sh scripts/collect-source-archives.sh scripts/normalize-ppd.sh firmware/setup-firmware.sh firmware/firmware-watch.sh; do
  sh -n "$ROOT/$file"
done

grep -q '^FOO2ZJS_COMMIT=80499ed5bf6caa2963ad337e37cfda78a80aab1e
# Candidate must be installed alongside, never over, the original legacy driver.
grep -q '^BASE="/Library/Printers/hp-legacy-mac-plus"$' "$ROOT/install.sh"
grep -q '^FILTER="/usr/libexec/cups/filter/hp-legacy-mac-plus"$' "$ROOT/install.sh"
grep -q '^BASE=/Library/Printers/hp-legacy-mac-plus$' "$ROOT/src/cups-filter"
grep -Fq "grep -q '^\\*ModelName:'" "$ROOT/install.sh"
grep -Fq "grep -v '^\\*cupsFilter'" "$ROOT/install.sh"
if grep -Fq '/Library/Printers/hp-legacy-mac"' "$ROOT/install.sh"; then
  echo "Candidate installer must not overwrite the legacy driver path." >&2
  exit 1
fi

# Exercise the PPD normalizer using a small synthetic PPD.
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

echo "Static source checks passed (not a build or print test)."
 "$ROOT/build/build-bundle.sh"

# Regression checks for packaged GUI recovery path.
grep -Fq 'cp "$ROOT/uninstall.sh" "$APP/Contents/Resources/uninstall.sh"' "$ROOT/packaging/build-release.sh"
grep -Fq 'set actionChoices to {"Set Up Firmware", "Uninstall Candidate Driver"}' "$ROOT/firmware/setup-firmware.applescript"

# Candidate must be installed alongside, never over, the original legacy driver.
grep -q '^BASE="/Library/Printers/hp-legacy-mac-plus"$' "$ROOT/install.sh"
grep -q '^FILTER="/usr/libexec/cups/filter/hp-legacy-mac-plus"$' "$ROOT/install.sh"
grep -q '^BASE=/Library/Printers/hp-legacy-mac-plus$' "$ROOT/src/cups-filter"
grep -Fq "grep -q '^\\*ModelName:'" "$ROOT/install.sh"
grep -Fq "grep -v '^\\*cupsFilter'" "$ROOT/install.sh"
if grep -Fq '/Library/Printers/hp-legacy-mac"' "$ROOT/install.sh"; then
  echo "Candidate installer must not overwrite the legacy driver path." >&2
  exit 1
fi

# Exercise the PPD normalizer using a small synthetic PPD.
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

echo "Static source checks passed (not a build or print test)."
