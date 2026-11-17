#!/bin/sh
# Privileged helper launched by the GUI app: change the print-position correction
# (in millimetres) of one managed queue. No rebuild or reinstall is needed; the
# CUPS filter reads the value at the start of every print job.
# Usage: set-offset.sh <queue> <horizontal_mm> <vertical_mm>
set -eu
umask 077
BASE=/Library/Printers/hp-legacy-mac-plus
CLIP="$BASE/bin/hp1020-clip"

fail() { printf 'Print position was not changed: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || fail 'administrator permission is required.'
[ "$#" -eq 3 ] || fail 'the app must provide a queue and two values.'
QUEUE=$1
H_MM=$2
V_MM=$3
case "$QUEUE" in ''|*[!A-Za-z0-9_.-]*) fail 'invalid printer queue name.' ;; esac
[ "${#QUEUE}" -le 64 ] || fail 'printer queue name is too long.'
CONF="$BASE/queues/$QUEUE.conf"
[ -f "$CONF" ] && [ ! -L "$CONF" ] || fail 'this printer queue was not installed by this driver.'
/usr/bin/grep -qx 'DRIVER_ID="hp1020"' "$CONF" || fail 'this printer queue was not installed by this driver.'
[ -f "$CLIP" ] || fail 'the installed driver is too old for this setting. Install the latest package first.'
/bin/sh "$CLIP" check "$H_MM" || fail "the horizontal value '$H_MM' must be a number from -10 to 4 (for example -2.5)."
/bin/sh "$CLIP" check "$V_MM" || fail "the vertical value '$V_MM' must be a number from -10 to 4 (for example 0)."

TMP=$(/usr/bin/mktemp "$BASE/queues/.offset.XXXXXX")
trap '/bin/rm -f "$TMP"' EXIT HUP INT TERM
/usr/bin/printf 'DRIVER_ID="hp1020"\nCOLOR_CAPABLE=0\nHORIZONTAL_OFFSET_MM=%s\nVERTICAL_OFFSET_MM=%s\n' "$H_MM" "$V_MM" > "$TMP"
/usr/sbin/chown root:wheel "$TMP"
/bin/chmod 644 "$TMP"
/bin/mv -f "$TMP" "$CONF"
trap - EXIT HUP INT TERM
printf 'Print position saved: horizontal %s mm, vertical %s mm.\nIt applies to the next page you print.\n' "$H_MM" "$V_MM"
