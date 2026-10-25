#!/bin/sh
# Download and verify HP LaserJet 1020 firmware for the user; print its temporary file path.
# HP firmware is not redistributed in this repository or embedded in the installer.
# The source archive URL is the one used by OpenPrinting foo2zjs/getweb for model 1020.
set -eu
umask 077

EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01
FIRMWARE_URL="https://www.quirinux.org/printers/sihp1020.tar.gz"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ARM2HPDL="$HERE/arm2hpdl"

fail() { printf 'HP LaserJet firmware download failed: %s\n' "$*" >&2; exit 1; }
[ "$#" -eq 0 ] || fail 'this helper takes no arguments.'
[ -x "$ARM2HPDL" ] || fail 'the bundled firmware converter is missing.'
for tool in /usr/bin/curl /usr/bin/tar /usr/bin/shasum /usr/bin/awk /usr/bin/grep /usr/bin/mktemp; do
  [ -x "$tool" ] || fail "required system tool is missing: $tool"
done

TMPROOT=${TMPDIR:-/tmp}
WORK=$(/usr/bin/mktemp -d "$TMPROOT/hp1020-firmware.XXXXXX")
/bin/chmod 700 "$WORK"
cleanup_on_error() {
  result=$?
  if [ "$result" -ne 0 ]; then /bin/rm -rf "$WORK"; fi
}
trap cleanup_on_error EXIT
trap 'exit 1' HUP INT TERM

ARCHIVE="$WORK/sihp1020.tar.gz"
IMG="$WORK/sihp1020.img"
DL="$WORK/sihp1020.dl"

/usr/bin/curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 15 --max-time 90 \
  --output "$ARCHIVE" "$FIRMWARE_URL" || fail 'could not retrieve the firmware archive over HTTPS.'
[ -s "$ARCHIVE" ] || fail 'the downloaded archive is empty.'

# Do not extract archive paths. Stream only one exact expected member to a temporary file.
MEMBERS=$(/usr/bin/tar -tzf "$ARCHIVE") || fail 'the firmware archive is not a valid gzip tar archive.'
MATCHES=$(printf '%s\n' "$MEMBERS" | /usr/bin/grep -E '^(\./)?sihp1020\.img$' || true)
COUNT=$(printf '%s\n' "$MATCHES" | /usr/bin/awk 'NF { n++ } END { print n+0 }')
[ "$COUNT" -eq 1 ] || fail 'the archive does not contain exactly one expected sihp1020.img entry.'
MEMBER=$(printf '%s\n' "$MATCHES" | /usr/bin/awk 'NF { print; exit }')
/usr/bin/tar -xzOf "$ARCHIVE" "$MEMBER" > "$IMG" || fail 'could not read sihp1020.img from the archive.'
[ -s "$IMG" ] || fail 'the firmware image is empty.'

"$ARM2HPDL" "$IMG" > "$DL" || fail 'could not convert the firmware image to HP download format.'
ACTUAL=$(/usr/bin/shasum -a 256 "$DL" | /usr/bin/awk '{print $1}')
[ "$ACTUAL" = "$EXPECTED_SHA256" ] || fail 'the converted firmware checksum does not match the reviewed file; nothing was installed.'
/bin/chmod 644 "$DL"
printf '%s\n' "$DL"
# Leave the private temporary directory available until the GUI invokes the privileged
# installer helper. The GUI deletes the whole temporary directory after either outcome.
