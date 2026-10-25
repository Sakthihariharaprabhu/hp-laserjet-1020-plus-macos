#!/bin/sh
# Runtime smoke test for the bundled Ghostscript -> foo2zjs pipeline.
# This renders a synthetic page to a temporary printer stream; it does not send
# anything to a real printer and does not claim physical print compatibility.
set -eu
BUNDLE=${1:?usage: smoke-driver-pipeline.sh path-to-bundle}
[ -d "$BUNDLE" ] || { echo "Bundle directory not found: $BUNDLE" >&2; exit 1; }
[ -x "$BUNDLE/bin/gs" ] && [ -x "$BUNDLE/bin/foo2zjs-wrapper" ] || {
  echo "Bundle is missing the Ghostscript executable or foo2zjs wrapper." >&2
  exit 1
}

GS_RESOURCE_ROOT=
if [ -d "$BUNDLE/share/ghostscript/Resource/Init" ] && [ -d "$BUNDLE/share/ghostscript/lib" ]; then
  GS_RESOURCE_ROOT="$BUNDLE/share/ghostscript"
else
  for candidate in "$BUNDLE"/share/ghostscript/*; do
    if [ -d "$candidate/Resource/Init" ] && [ -d "$candidate/lib" ]; then
      GS_RESOURCE_ROOT=$candidate
      break
    fi
  done
fi
[ -n "$GS_RESOURCE_ROOT" ] || { echo "Ghostscript resources are missing." >&2; exit 1; }

export PATH="$BUNDLE/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export GSBIN="$BUNDLE/bin/gs"
export GS_LIB="$GS_RESOURCE_ROOT/Resource/Init:$GS_RESOURCE_ROOT/lib:$GS_RESOURCE_ROOT/Resource/Font:$GS_RESOURCE_ROOT/fonts:$GS_RESOURCE_ROOT/Resource/CMap:$GS_RESOURCE_ROOT/Resource/ColorSpace"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/hp1020-pipeline-smoke.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
cat > "$WORK/smoke.ps" <<'PS'
%!PS-Adobe-3.0
%%Pages: 1
%%Page: 1 1
/Helvetica findfont 18 scalefont setfont
72 720 moveto
(HP LaserJet 1020 driver pipeline smoke test) show
showpage
%%EOF
PS

"$BUNDLE/bin/foo2zjs-wrapper" -z1 -P -L0 -p9 -r1200x600 -b "$BUNDLE/bin/gs" < "$WORK/smoke.ps" > "$WORK/smoke.zjs"
[ -s "$WORK/smoke.zjs" ] || { echo "Driver pipeline produced an empty output stream." >&2; exit 1; }
SIZE=$(wc -c < "$WORK/smoke.zjs" | tr -d ' ')
[ "$SIZE" -gt 128 ] || { echo "Driver pipeline output is unexpectedly small ($SIZE bytes)." >&2; exit 1; }
printf 'Driver pipeline smoke test passed; generated %s bytes of ZjStream data.\n' "$SIZE"
