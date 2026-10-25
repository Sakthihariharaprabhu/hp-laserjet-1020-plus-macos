#!/bin/sh
# Fail closed on non-system absolute Mach-O dependencies in a packaged driver.
set -eu
ROOT=${1:?usage: check-macho-deps.sh bundle-directory}
command -v otool >/dev/null 2>&1 || { echo 'check-macho-deps: otool is required (run on macOS).' >&2; exit 1; }
command -v file >/dev/null 2>&1 || { echo 'check-macho-deps: file is required.' >&2; exit 1; }
found=0
while IFS= read -r binary; do
  [ -f "$binary" ] || continue
  file "$binary" | grep -q 'Mach-O' || continue
  found=1
  while IFS= read -r dep; do
    case "$dep" in
      /System/Library/*|/usr/lib/*) ;;
      @executable_path/*|@loader_path/*) ;;
      *)
        echo "check-macho-deps: unsupported dependency in $binary: $dep" >&2
        exit 1
        ;;
    esac
  done <<DEPS
$(otool -L "$binary" | sed '1d; s/^[[:space:]]*//; s/ (compatibility version.*$//')
DEPS
done <<FILES
$(find "$ROOT/bin" "$ROOT/libs" -type f -print)
FILES
[ "$found" -eq 1 ] || { echo 'check-macho-deps: no Mach-O files found.' >&2; exit 1; }
echo 'check-macho-deps: no unexpected absolute runtime dependencies found.'
