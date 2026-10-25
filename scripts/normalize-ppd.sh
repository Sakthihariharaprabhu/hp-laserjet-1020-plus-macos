#!/bin/sh
# Normalize the HP LaserJet 1020 PPD to A4 defaults for this India-focused package.
set -eu
INPUT=${1:?usage: normalize-ppd.sh input.ppd output.ppd}
OUTPUT=${2:?usage: normalize-ppd.sh input.ppd output.ppd}
[ -f "$INPUT" ] || { echo "normalize-ppd: input PPD not found" >&2; exit 1; }
sed \
  -e 's/^\*DefaultPageSize: Letter$/\*DefaultPageSize: A4/' \
  -e 's/^\*DefaultPageRegion: Letter$/\*DefaultPageRegion: A4/' \
  -e 's/^\*DefaultImageableArea: Letter$/\*DefaultImageableArea: A4/' \
  -e 's/^\*DefaultPaperDimension: Letter$/\*DefaultPaperDimension: A4/' \
  "$INPUT" > "$OUTPUT"
for directive in DefaultPageSize DefaultPageRegion DefaultImageableArea DefaultPaperDimension; do
  grep -q "^\\*$directive: A4$" "$OUTPUT" || {
    echo "normalize-ppd: expected A4 default missing: $directive" >&2; exit 1;
  }
done
grep -q '^\*ImageableArea A4/A4: "11.34 11.34 583.66 830.66"$' "$OUTPUT" || {
  echo 'normalize-ppd: unexpected A4 imageable area; refusing to guess printer margins' >&2; exit 1;
}
grep -q '^\*PaperDimension A4/A4: "595 842"$' "$OUTPUT" || {
  echo 'normalize-ppd: unexpected A4 dimensions' >&2; exit 1;
}
