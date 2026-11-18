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

run_case() { # name input wrapper-args...
  name=$1; input=$2; shift 2
  "$BUNDLE/bin/foo2zjs-wrapper" "$@" -b "$BUNDLE/bin/gs" < "$input" > "$WORK/$name.zjs"
  [ -s "$WORK/$name.zjs" ] || { echo "Driver pipeline produced an empty output stream ($name)." >&2; exit 1; }
  size=$(wc -c < "$WORK/$name.zjs" | tr -d ' ')
  [ "$size" -gt 1000 ] || { echo "Driver pipeline output is unexpectedly small ($name: $size bytes)." >&2; exit 1; }
  printf 'Pipeline case %s: %s bytes of ZjStream data.\n' "$name" "$size"
  SIZE=$size
}
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CLIP="$BUNDLE/bin/hp1020-clip"
[ -x "$CLIP" ] || CLIP="$ROOT/src/hp1020-clip"
# 1. Original arguments (wrapper default crop).
run_case plain "$WORK/smoke.ps" -z1 -P -L0 -p9 -r1200x600
# 2. Exactly what the CUPS filter now sends: computed crop for -3 mm, fixed A4 media, fit-to-page.
CLIP_ARGS=$(sh "$CLIP" args 1200 -3.0 0)
# shellcheck disable=SC2086
run_case filter-args "$WORK/smoke.ps" -z1 -P -L0 -p9 -r1200x600 $CLIP_ARGS -g -dFIXEDMEDIA -g -dPDFFitPage
# 3. The A4 calibration PDF at 600 dpi with a vertical correction too.
if [ -f "$ROOT/calibration/a4-alignment-test.pdf" ]; then
  CLIP_ARGS=$(sh "$CLIP" args 600 -10 -2)
  # shellcheck disable=SC2086
  run_case calibration-pdf "$ROOT/calibration/a4-alignment-test.pdf" -z1 -P -L0 -p9 -r600x600 $CLIP_ARGS -g -dFIXEDMEDIA -g -dPDFFitPage
fi
printf 'Driver pipeline smoke test passed (last case %s bytes).\n' "$SIZE"
