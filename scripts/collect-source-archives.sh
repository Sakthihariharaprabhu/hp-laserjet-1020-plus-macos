#!/bin/sh
# Fetch exact upstream source archives for third-party formulae used in the binary bundle.
set -eu
OUT=${1:?usage: collect-source-archives.sh output-directory}
command -v brew >/dev/null 2>&1 || { echo 'Homebrew is required.' >&2; exit 1; }
command -v ruby >/dev/null 2>&1 || { echo 'Ruby is required to read Homebrew formula metadata.' >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo 'curl is required.' >&2; exit 1; }
mkdir -p "$OUT"
MANIFEST="$OUT/SOURCE-ARCHIVES.txt"
: > "$MANIFEST"
for formula in ghostscript jbigkit gnu-sed dylibbundler bc; do
  info=$(brew info --json=v2 "$formula")
  version=$(printf '%s' "$info" | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts j.fetch("formulae").first.fetch("versions").fetch("stable")')
  url=$(printf '%s' "$info" | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts j.fetch("formulae").first.fetch("urls").fetch("stable").fetch("url")')
  sha=$(printf '%s' "$info" | ruby -rjson -e 'j=JSON.parse(STDIN.read); puts j.fetch("formulae").first.fetch("urls").fetch("stable").fetch("checksum")')
  [ -n "$url" ] && [ -n "$sha" ] || { echo "Missing source URL/checksum for $formula" >&2; exit 1; }
  dest="$OUT/$formula-$version.source-archive"
  formula_file="$OUT/$formula.homebrew-formula.rb"
  brew cat "$formula" > "$formula_file"
  formula_sha=$(shasum -a 256 "$formula_file" | awk '{print $1}')
  printf 'Fetching %s %s source archive\n' "$formula" "$version"
  curl --fail --location --silent --show-error "$url" -o "$dest"
  actual=$(shasum -a 256 "$dest" | awk '{print $1}')
  [ "$actual" = "$sha" ] || { echo "Checksum mismatch for $formula source archive" >&2; exit 1; }
  printf '%s %s\n  URL: %s\n  Source SHA-256: %s\n  Source file: %s\n  Homebrew formula: %s (SHA-256 %s)\n\n' "$formula" "$version" "$url" "$sha" "$(basename "$dest")" "$(basename "$formula_file")" "$formula_sha" >> "$MANIFEST"
done
printf '%s\n' 'The source archives above are the exact Homebrew stable source archives selected for this build. Review each archive license and dependency notices before redistribution.' >> "$MANIFEST"
