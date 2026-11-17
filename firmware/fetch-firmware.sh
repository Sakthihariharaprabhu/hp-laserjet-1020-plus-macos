#!/bin/sh
# Download and verify HP LaserJet 1020 firmware for the user; print its temporary file path.
# HP firmware is not stored in git or embedded in the installer.
#
# Sources are tried in order. EVERY download must match the reviewed SHA-256
# below before it is used, so a wrong, damaged or tampered file from any source
# is rejected. Only sources that were checked to serve the identical file are
# listed (see docs/FIRMWARE-WORKFLOW.md).
#
#   Format "dl"  = the ready-to-use sihp1020.dl file
#   Format "tgz" = a .tar.gz containing sihp1020.img (converted with arm2hpdl)
#
# Note: www.quirinux.org/printers/sihp1020.tar.gz (the source used by
# OpenPrinting's getweb) is deliberately NOT listed: its image converts to a
# different firmware build (dated 2005-03-09, SHA-256 133b21fe...) than the
# reviewed and physically tested file (2004-11, c14fdf0a...), so it can never
# pass the checksum gate. See docs/FIRMWARE-WORKFLOW.md.
set -eu
umask 077

EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01
SOURCES='
dl|GitHub Release (this project)|https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/releases/download/firmware-hp1020/sihp1020.dl
'
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ARM2HPDL="$HERE/arm2hpdl"

fail() { printf '%s\n' "$*" >&2; exit 1; }
[ "$#" -eq 0 ] || fail 'This helper takes no arguments.'
for tool in /usr/bin/curl /usr/bin/tar /usr/bin/shasum /usr/bin/awk /usr/bin/grep /usr/bin/mktemp; do
  [ -x "$tool" ] || fail "A required macOS tool is missing: $tool"
done

TMPROOT=${TMPDIR:-/tmp}
WORK=$(/usr/bin/mktemp -d "$TMPROOT/hp1020-firmware.XXXXXX")
/bin/chmod 700 "$WORK"
# shellcheck disable=SC2329  # runs through the EXIT trap
cleanup_on_error() {
  result=$?
  if [ "$result" -ne 0 ]; then /bin/rm -rf "$WORK"; fi
}
trap cleanup_on_error EXIT
trap 'exit 1' HUP INT TERM

DL="$WORK/sihp1020.dl"
REPORT=
note() { REPORT="${REPORT}
- $1: $2"; }

# curl: 30 s to connect, 3 min total, one automatic retry on timeouts/transient errors.
fetch() {
  /usr/bin/curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --connect-timeout 30 --max-time 180 --retry 1 --retry-delay 3 --retry-connrefused \
    --output "$2" "$1" 2>"$WORK/curl.err"
}

curl_reason() {
  err=$(/usr/bin/sed -n '$p' "$WORK/curl.err" 2>/dev/null)
  case "$err" in
    *"(28)"*) echo 'timed out (the site did not answer on this network)' ;;
    *"(6)"*) echo 'site name could not be found (no internet or DNS problem)' ;;
    *"(7)"*) echo 'could not connect' ;;
    *"error: 404"*) echo 'file not found (404) — the source may be private or the file was moved' ;;
    *"error: "[45][0-9][0-9]*) echo "the site refused the request: ${err#curl: }" ;;
    "") echo 'download failed' ;;
    *) echo "${err#curl: }" ;;
  esac
}

try_source() {
  format=$1; name=$2; url=$3
  /bin/rm -f "$DL" "$WORK/archive" "$WORK/sihp1020.img"
  case "$format" in
    dl)
      fetch "$url" "$DL" || { note "$name" "$(curl_reason)"; return 1; }
      ;;
    tgz)
      [ -x "$ARM2HPDL" ] || { note "$name" 'firmware converter missing'; return 1; }
      fetch "$url" "$WORK/archive" || { note "$name" "$(curl_reason)"; return 1; }
      # Never extract archive paths: stream exactly one expected member.
      members=$(/usr/bin/tar -tzf "$WORK/archive" 2>/dev/null) || { note "$name" 'not a valid archive'; return 1; }
      matches=$(printf '%s\n' "$members" | /usr/bin/grep -E '^(\./)?sihp1020\.img$' || true)
      count=$(printf '%s\n' "$matches" | /usr/bin/awk 'NF { n++ } END { print n+0 }')
      [ "$count" -eq 1 ] || { note "$name" 'archive does not contain the expected file'; return 1; }
      member=$(printf '%s\n' "$matches" | /usr/bin/awk 'NF { print; exit }')
      /usr/bin/tar -xzOf "$WORK/archive" "$member" > "$WORK/sihp1020.img" || { note "$name" 'could not read archive'; return 1; }
      "$ARM2HPDL" "$WORK/sihp1020.img" > "$DL" || { note "$name" 'could not convert the firmware image'; return 1; }
      ;;
    *) note "$name" 'unknown source format'; return 1 ;;
  esac
  [ -s "$DL" ] || { note "$name" 'downloaded file is empty'; return 1; }
  actual=$(/usr/bin/shasum -a 256 "$DL" | /usr/bin/awk '{print $1}')
  [ "$actual" = "$EXPECTED_SHA256" ] || { note "$name" 'file did not match the checksum, so it was rejected (nothing installed)'; return 1; }
  return 0
}

COUNT=0
OLDIFS=$IFS
IFS='
'
for line in $SOURCES; do
  [ -n "$line" ] || continue
  IFS='|' read -r format name url <<EOF
$line
EOF
  COUNT=$((COUNT + 1))
  if try_source "$format" "$name" "$url"; then
    IFS=$OLDIFS
    /bin/chmod 644 "$DL"
    printf '%s\n' "$DL"
    # The GUI deletes this private temporary directory after setup either way.
    exit 0
  fi
done
IFS=$OLDIFS

fail "The firmware could not be downloaded automatically. Tried $COUNT source(s):$REPORT

Nothing was installed. What to do: download sihp1020.dl yourself from this project's GitHub Releases page (or use a copy from an old HP driver or Linux foo2zjs), then run Set Up Firmware again and choose \"Select an existing firmware file\". The app checks the file either way."
