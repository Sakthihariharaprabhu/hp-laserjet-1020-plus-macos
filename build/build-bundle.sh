#!/bin/sh
# Build a local ARM64 bundle from a pinned upstream foo2zjs source revision.
# This script downloads source code; it does not download or package HP firmware.
set -eu
umask 077

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ARCH=$(uname -m)
[ "$(uname -s)" = Darwin ] || { echo "Build requires macOS." >&2; exit 1; }
[ "$ARCH" = arm64 ] || { echo "Only Apple Silicon arm64 is supported by this build." >&2; exit 1; }
command -v brew >/dev/null 2>&1 || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git is required." >&2; exit 1; }

# Immutable commit inspected for this project. Do not replace with a moving branch.
FOO2ZJS_COMMIT=80499ed5bf6caa2963ad337e37cfda78a80aab1e
BREW=$(brew --prefix)
for formula in ghostscript jbigkit gnu-sed dylibbundler bc; do
  brew list "$formula" >/dev/null 2>&1 || brew install "$formula"
done
GS="$BREW/bin/gs"
GSED="$BREW/bin/gsed"
DC="$BREW/bin/dc"
[ -x "$DC" ] || DC="$(command -v dc || true)"
[ -n "$DC" ] && [ -x "$DC" ] || { echo "GNU dc not found; required for custom paper sizes." >&2; exit 1; }
[ -x "$GS" ] || { echo "Ghostscript not found at $GS" >&2; exit 1; }
[ -x "$GSED" ] || { echo "GNU sed not found at $GSED" >&2; exit 1; }

B="$ROOT/dist/bundle"
[ ! -e "$B" ] || { echo "Refusing to overwrite existing $B; move it aside first." >&2; exit 1; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/hp1020-build.XXXXXX")
BUILD_STARTED=0
BUILD_SUCCEEDED=0
cleanup() {
  rc=$?
  rm -rf "$WORK"
  if [ "$BUILD_STARTED" -eq 1 ] && [ "$BUILD_SUCCEEDED" -eq 0 ]; then rm -rf "$B"; fi
  return "$rc"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
mkdir -p "$ROOT/dist" "$ROOT/dist/source-code"

printf '%s\n' "Fetching OpenPrinting/foo2zjs at $FOO2ZJS_COMMIT"
git clone --filter=blob:none https://github.com/OpenPrinting/foo2zjs.git "$WORK/foo2zjs"
git -C "$WORK/foo2zjs" fetch --depth 1 origin "$FOO2ZJS_COMMIT"
git -C "$WORK/foo2zjs" checkout --detach "$FOO2ZJS_COMMIT"
ACTUAL=$(git -C "$WORK/foo2zjs" rev-parse HEAD)
[ "$ACTUAL" = "$FOO2ZJS_COMMIT" ] || { echo "Source revision mismatch." >&2; exit 1; }
git -C "$WORK/foo2zjs" archive --format=tar.gz --prefix="foo2zjs-$FOO2ZJS_COMMIT/" "$FOO2ZJS_COMMIT" > "$ROOT/dist/source-code/foo2zjs-$FOO2ZJS_COMMIT.tar.gz"

cd "$WORK/foo2zjs"
CF="-O2 -Wall -I$BREW/include"
LF="-L$BREW/lib"
make foo2zjs CFLAGS="$CF" LDFLAGS="$LF"
make foo2zjs-wrapper

# Build in a fresh output directory. The preflight above ensures this path was absent.
mkdir -p "$B/bin" "$B/libs" "$B/share" "$B/ppd"
BUILD_STARTED=1
cp foo2zjs "$B/bin/foo2zjs"
cp foo2zjs-wrapper "$B/bin/foo2zjs-wrapper"
cp foo2zjs-pstops.sh "$B/bin/foo2zjs-pstops"
cp "$GS" "$B/bin/gs"
cp "$GSED" "$B/bin/gsed"
cp "$DC" "$B/bin/dc"
sh "$ROOT/scripts/normalize-ppd.sh" PPD/HP-LaserJet_1020.ppd "$WORK/HP-LaserJet_1020.ppd"
gzip -n -c "$WORK/HP-LaserJet_1020.ppd" > "$B/ppd/HP-LaserJet_1020.ppd.gz"
cp -RL "$BREW/share/ghostscript" "$B/share/ghostscript"
( cd "$B" && dylibbundler -of -b -x ./bin/gs -d ./libs/ -p @executable_path/../libs/ )
( cd "$B" && dylibbundler -of -b -x ./bin/foo2zjs -d ./libs/ -p @executable_path/../libs/ )
( cd "$B" && dylibbundler -of -b -x ./bin/gsed -d ./libs/ -p @executable_path/../libs/ )
( cd "$B" && dylibbundler -of -b -x ./bin/dc -d ./libs/ -p @executable_path/../libs/ )
cp "$ROOT/src/cups-filter" "$B/cups-filter"
cp "$ROOT/firmware/firmware-watch.sh" "$B/firmware-watch.sh"
# Normalize runtime-readable resources: the build uses a private umask.
find "$B" -type d -exec chmod 755 {} \;
find "$B" -type f -exec chmod 644 {} \;
chmod 755 "$B/bin/gs" "$B/bin/gsed" "$B/bin/dc" "$B/bin/foo2zjs" "$B/bin/foo2zjs-wrapper" "$B/bin/foo2zjs-pstops" "$B/cups-filter" "$B/firmware-watch.sh"
cp "$WORK/foo2zjs/COPYING" "$B/COPYING.foo2zjs"
printf '%s\\n' "$FOO2ZJS_COMMIT" > "$B/FOO2ZJS_COMMIT"
{ printf 'Build architecture: %s\\n' "$ARCH"; printf 'foo2zjs commit: %s\\n' "$FOO2ZJS_COMMIT"; brew list --versions ghostscript jbigkit gnu-sed dylibbundler bc; } > "$B/BUILD-MANIFEST.txt"

# Structural checks run before creating an archive.
sh "$ROOT/scripts/check-bundle.sh" "$B"
"$B/bin/gs" --version >/dev/null
"$B/bin/gsed" --version >/dev/null 2>&1 || true
"$B/bin/dc" -e '1 1 + p' | grep -qx 2
# Fail if any bundled Mach-O retains a non-system absolute dependency.
sh "$ROOT/scripts/check-macho-deps.sh" "$B"
sh "$ROOT/scripts/collect-source-archives.sh" "$ROOT/dist/source-code/third-party"
( cd "$ROOT/dist" && tar -czf hp-laserjet-1020-plus-macos-arm64-bundle.tar.gz bundle )
BUILD_SUCCEEDED=1
echo "Bundle built: $ROOT/dist/hp-laserjet-1020-plus-macos-arm64-bundle.tar.gz"
echo "This is not a functional release until CUPS and physical print tests pass."
