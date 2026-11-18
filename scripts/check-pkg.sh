#!/bin/sh
# Inspect a built .pkg WITHOUT installing it: no firmware inside, expected files present.
set -eu
PKG=${1:?usage: check-pkg.sh <package.pkg>}
LIST=$(mktemp)
trap 'rm -f "$LIST"' EXIT HUP INT TERM
/usr/sbin/pkgutil --payload-files "$PKG" > "$LIST"
if grep -Ei '(^|/)sihp[0-9a-z]*\.(dl|img)$|\.dl$' "$LIST" >/dev/null; then
  echo "check-pkg: ERROR: firmware found inside the package" >&2; exit 1
fi
for must in 'Library/Printers/hp-legacy-mac-package/install.sh' 'Applications/HP LaserJet Firmware Setup.app/Contents/Resources/uninstall.sh'; do
  grep -Fq "$must" "$LIST" || { echo "check-pkg: ERROR: missing $must" >&2; exit 1; }
done
echo "check-pkg: no firmware in package; expected files present ($(wc -l < "$LIST" | tr -d ' ') entries)."
