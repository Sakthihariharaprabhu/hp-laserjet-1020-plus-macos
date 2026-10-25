#!/bin/sh
set -eu
BUNDLE="${1:-dist/bundle}"
fail() { echo "bundle-check: ERROR: $*" >&2; exit 1; }
[ -d "$BUNDLE" ] || fail "bundle directory is absent: $BUNDLE"
for f in bin/gs bin/gsed bin/dc bin/foo2zjs bin/foo2zjs-wrapper bin/foo2zjs-pstops bin/arm2hpdl cups-filter firmware-watch.sh ppd/HP-LaserJet_1020.ppd.gz; do
  [ -f "$BUNDLE/$f" ] || fail "missing $f"
done
[ -x "$BUNDLE/bin/gs" ] || fail "bin/gs is not executable"
[ -x "$BUNDLE/bin/gsed" ] || fail "bin/gsed is not executable"
[ -x "$BUNDLE/bin/dc" ] || fail "bin/dc is not executable"
[ -x "$BUNDLE/bin/foo2zjs" ] || fail "bin/foo2zjs is not executable"
[ -x "$BUNDLE/bin/foo2zjs-wrapper" ] || fail "bin/foo2zjs-wrapper is not executable"
[ -x "$BUNDLE/bin/foo2zjs-pstops" ] || fail "bin/foo2zjs-pstops is not executable"
[ -x "$BUNDLE/bin/arm2hpdl" ] || fail "bin/arm2hpdl is not executable"
[ -x "$BUNDLE/cups-filter" ] || fail "cups-filter is not executable"
[ -x "$BUNDLE/firmware-watch.sh" ] || fail "firmware-watch.sh is not executable"
if find "$BUNDLE" -type l -print | grep . >/dev/null 2>&1; then fail "symbolic links are not permitted"; fi
if find "$BUNDLE" -type f -perm -111 -print | grep -E '(^|/)(install|uninstall)\\.sh$' >/dev/null 2>&1; then
  fail "installer scripts should not be nested inside the driver payload"
fi
if find "$BUNDLE" -type f -print | grep -Ei 'sihp1020\\.dl|/firmware(\\.|$)|\\.dl$' >/dev/null 2>&1; then
  fail "firmware must not be redistributed in this package"
fi
if ! gunzip -t "$BUNDLE/ppd/HP-LaserJet_1020.ppd.gz" >/dev/null 2>&1; then fail "PPD gzip is corrupt"; fi
PPD_TMP=$(mktemp)
trap 'rm -f "$PPD_TMP"' EXIT HUP INT TERM
gunzip -c "$BUNDLE/ppd/HP-LaserJet_1020.ppd.gz" > "$PPD_TMP"
for directive in DefaultPageSize DefaultPageRegion DefaultImageableArea DefaultPaperDimension; do
  grep -q "^\\*$directive: A4$" "$PPD_TMP" || fail "PPD default is not A4: $directive"
done
echo "bundle-check: structure and A4 defaults passed. This does not prove print compatibility or binary safety."
