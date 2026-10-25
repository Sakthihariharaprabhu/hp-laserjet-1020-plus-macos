#!/bin/sh
# Conservative removal: only removes an explicitly named, confirmed candidate queue and its files.
set -eu
umask 077
BASE="/Library/Printers/hp-legacy-mac-plus"
FILTER="/usr/libexec/cups/filter/hp-legacy-mac-plus"

[ "$(id -u)" -eq 0 ] || { echo "Please run as administrator." >&2; exit 1; }
[ "$(uname -s)" = Darwin ] || { echo "macOS is required." >&2; exit 1; }

if [ "$#" -eq 0 ]; then
  printf "This removes the hp-legacy-mac-plus candidate driver files and the queue name you enter.\n"
  printf "It does not remove other printer queues or Apple system components.\n"
  printf "Queue name to remove (blank cancels): "
  IFS= read -r QUEUE
  [ -n "$QUEUE" ] || { echo "Cancelled."; exit 0; }
  printf "Type REMOVE to confirm: "
  IFS= read -r CONFIRM
elif [ "$#" -eq 2 ]; then
  QUEUE=$1
  CONFIRM=$2
else
  echo "Usage: uninstall.sh [candidate-queue REMOVE]" >&2
  exit 2
fi

case "$QUEUE" in ''|*[!A-Za-z0-9_.-]*) echo "Invalid queue name; cancelled." >&2; exit 1 ;; esac
[ "${#QUEUE}" -le 64 ] || { echo "Queue name too long." >&2; exit 1; }
[ "$CONFIRM" = "REMOVE" ] || { echo "Cancelled."; exit 0; }

OWNED_CONF="$BASE/queues/$QUEUE.conf"
OWNED=0
if [ -f "$OWNED_CONF" ] && grep -qx 'DRIVER_ID="hp1020"' "$OWNED_CONF" && grep -qx 'COLOR_CAPABLE=0' "$OWNED_CONF"; then OWNED=1; fi
if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  PPD="/etc/cups/ppd/$QUEUE.ppd"
  if [ -f "$PPD" ] && grep -q 'hp-legacy-mac-plus' "$PPD" && [ "$OWNED" -eq 1 ]; then
    lpadmin -x "$QUEUE"
    rm -f "$OWNED_CONF"
  else
    echo "Queue '$QUEUE' does not have both this driver's PPD and config markers; leaving it untouched." >&2
    exit 1
  fi
elif [ "$OWNED" -eq 1 ]; then
  rm -f "$OWNED_CONF"
fi

LABEL="com.hp-legacy-mac-plus.firmware-watch.$QUEUE"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
if [ -f "$PLIST" ] && command -v plutil >/dev/null 2>&1; then
  WATCH_QUEUE=$(plutil -extract ProgramArguments.1 raw -o - "$PLIST" 2>/dev/null || true)
  if [ "$WATCH_QUEUE" = "$QUEUE" ]; then
    RAW_QUEUE="${QUEUE}_Firmware"
    /bin/launchctl bootout system "$PLIST" >/dev/null 2>&1 || true
    if lpstat -p "$RAW_QUEUE" >/dev/null 2>&1; then lpadmin -x "$RAW_QUEUE"; fi
    rm -f "$PLIST"
    rm -rf "/var/db/hp-legacy-mac-plus/$QUEUE"
  fi
fi

if [ -d "$BASE/queues" ] && [ -z "$(find "$BASE/queues" -type f -name '*.conf' -print -quit)" ]; then rmdir "$BASE/queues" 2>/dev/null || true; fi
if [ -d "$BASE" ] && { [ ! -d "$BASE/queues" ] || [ -z "$(find "$BASE/queues" -type f -name '*.conf' -print -quit)" ]; } &&
   ! find /Library/LaunchDaemons -maxdepth 1 -name 'com.hp-legacy-mac-plus.firmware-watch.*.plist' -print 2>/dev/null | grep . >/dev/null 2>&1; then
  rm -rf "$BASE"
fi
if [ -f "$FILTER" ] && grep -q 'hp-legacy-mac-plus' "$FILTER"; then rm -f "$FILTER"; fi
if [ -f /Library/Printers/hp-legacy-mac-plus/firmware/sihp1020.dl ]; then
  if ! find /Library/LaunchDaemons -maxdepth 1 -name 'com.hp-legacy-mac-plus.firmware-watch.*.plist' -print 2>/dev/null | grep . >/dev/null 2>&1; then rm -rf /Library/Printers/hp-legacy-mac-plus/firmware; fi
fi
echo "Removed only the confirmed hp-legacy-mac-plus candidate queue and associated driver files."
