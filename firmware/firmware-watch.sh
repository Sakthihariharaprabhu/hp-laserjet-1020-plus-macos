#!/bin/sh
# Root LaunchDaemon: re-upload locally verified firmware when the printer reappears on USB.
set -eu
umask 077
[ "$(id -u)" -eq 0 ] || exit 1
[ "$#" -eq 4 ] || exit 1
QUEUE=$1
RAW_QUEUE=$2
DEVICE_URI=$3
FIRMWARE=$4
BACKEND=/usr/libexec/cups/backend/usb
STATE_DIR="/var/db/hp-legacy-mac-plus/$QUEUE"
STATE="$STATE_DIR/usb-present"
PAUSED_MARKER="$STATE_DIR/main-queue-paused-by-helper"
LOG_TAG=hp-legacy-mac-plus-firmware

case "$QUEUE:$RAW_QUEUE" in *[!A-Za-z0-9_.:-]*) exit 1 ;; esac
case "$DEVICE_URI" in usb://*) ;; *) exit 1 ;; esac
BASE=/Library/Printers/hp-legacy-mac-plus
MODEL_CONF="$BASE/models/hp1020.conf"
EXPECTED=$(/bin/sh "$BASE/bin/model-get" "$MODEL_CONF" FIRMWARE_SHA256) || exit 1
FIRMWARE_FILE=$(/bin/sh "$BASE/bin/model-get" "$MODEL_CONF" FIRMWARE_FILE) || exit 1
[ "$FIRMWARE" = "$BASE/firmware/$FIRMWARE_FILE" ] || exit 1
[ -f "$FIRMWARE" ] && [ ! -L "$FIRMWARE" ] || exit 1
ACTUAL=$(/usr/bin/shasum -a 256 "$FIRMWARE" | /usr/bin/awk '{print $1}')
[ "$ACTUAL" = "$EXPECTED" ] || { /usr/bin/logger -t "$LOG_TAG" 'Firmware checksum mismatch; refusing upload.'; exit 1; }

is_present() { "$BACKEND" 2>/dev/null | /usr/bin/awk -v uri="$DEVICE_URI" '$2 == uri {found=1} END {exit !found}'; }

upload_firmware() {
  was_enabled=1
  if /usr/bin/lpstat -p "$QUEUE" 2>/dev/null | /usr/bin/grep -qi 'disabled'; then
    if [ -f "$PAUSED_MARKER" ]; then was_enabled=1; else was_enabled=0; fi
  fi
  if [ "$was_enabled" -eq 1 ]; then /usr/sbin/cupsdisable "$QUEUE" || return 1; : > "$PAUSED_MARKER"; fi
  /usr/bin/logger -t "$LOG_TAG" "Uploading firmware to $QUEUE after USB detection."
  request=$(/usr/bin/lp -d "$RAW_QUEUE" -o raw "$FIRMWARE" 2>&1) || { /usr/bin/logger -t "$LOG_TAG" "Firmware job could not be queued: $request"; return 1; }
  job=$(printf '%s\n' "$request" | /usr/bin/sed -n 's/.*request id is \([^ ]*\).*/\1/p')
  [ -n "$job" ] || { /usr/bin/logger -t "$LOG_TAG" 'Could not identify firmware job; leaving main queue paused for safety.'; return 1; }
  tries=0
  while /usr/bin/lpstat -o "$RAW_QUEUE" 2>/dev/null | /usr/bin/grep -F "$job" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [ "$tries" -ge 90 ] || ! is_present; then /usr/bin/logger -t "$LOG_TAG" 'Firmware upload timed out or printer disconnected; leaving main queue paused.'; return 1; fi
    /bin/sleep 1
  done
  # A disappearing queue entry is not proof of successful delivery. Only resume
  # the print queue if CUPS records this exact job as completed.
  completed=$(/usr/bin/lpstat -W completed -o "$RAW_QUEUE" 2>/dev/null | /usr/bin/grep -F "$job" || true)
  [ -n "$completed" ] || { /usr/bin/logger -t "$LOG_TAG" 'Firmware job left the queue without a completion record; leaving main queue paused.'; return 1; }
  if [ "$was_enabled" -eq 1 ]; then /usr/sbin/cupsenable "$QUEUE" || return 1; /bin/rm -f "$PAUSED_MARKER"; fi
  /usr/bin/logger -t "$LOG_TAG" "Firmware job completed for $QUEUE."
  return 0
}

/bin/mkdir -p "$STATE_DIR"
/bin/chmod 700 "$STATE_DIR"

# launchd starts this script when an HP USB device appears (and once at boot).
# It does its job once and exits: no background loop, no polling.
LOCK="$STATE_DIR/run.lock"
if ! /bin/mkdir "$LOCK" 2>/dev/null; then
  # A previous run may have died; a lock older than 5 minutes is stale.
  if [ -n "$(/usr/bin/find "$LOCK" -maxdepth 0 -mmin +5 2>/dev/null)" ]; then /bin/rmdir "$LOCK" 2>/dev/null || true; fi
  /bin/mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap '/bin/rmdir "$LOCK" 2>/dev/null || true' EXIT HUP INT TERM

# The USB event can arrive before CUPS lists the device: wait briefly.
tries=0
while ! is_present; do
  tries=$((tries + 1))
  [ "$tries" -lt 20 ] || { printf absent > "$STATE"; exit 0; }
  /bin/sleep 1
done

# After the firmware loads, the printer re-appears on USB and fires this event
# again. Skip if the firmware was sent in the last 40 seconds.
NOW=$(/bin/date +%s)
LAST=$(/bin/cat "$STATE_DIR/last-upload" 2>/dev/null || echo 0)
case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
if [ $((NOW - LAST)) -lt 40 ]; then exit 0; fi

if upload_firmware; then
  /bin/date +%s > "$STATE_DIR/last-upload"
  printf present > "$STATE"
else
  printf failed > "$STATE"
  exit 1
fi
