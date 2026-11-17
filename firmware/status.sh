#!/bin/sh
# Plain-language status report for the GUI app ("Check status").
# Runs as the logged-in user; reads only, changes nothing.
# Usage: status.sh [queue]
set -u
BASE=/Library/Printers/hp-legacy-mac-plus
FILTER=/usr/libexec/cups/filter/hp-legacy-mac-plus
FIRMWARE="$BASE/firmware/sihp1020.dl"
EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01
OK='✅'
NO='❌'
MAYBE='⚠️'

QUEUE=${1:-}
if [ -z "$QUEUE" ]; then
  QUEUE=$(/usr/bin/lpstat -p 2>/dev/null | /usr/bin/sed -n 's/^printer \([^ ]*\).*/\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' | /usr/bin/head -n 1)
fi
case "$QUEUE" in *[!A-Za-z0-9_.-]*) QUEUE= ;; esac

# 1. Driver files
if [ -x "$FILTER" ] && [ -x "$BASE/bin/gs" ] && [ -x "$BASE/bin/foo2zjs" ]; then
  echo "$OK Driver installed"
else
  echo "$NO Driver not installed — open the .pkg installer again."
fi

# 2. Printer queue
if [ -n "$QUEUE" ] && /usr/bin/lpstat -p "$QUEUE" >/dev/null 2>&1; then
  state=$(/usr/bin/lpstat -p "$QUEUE" 2>/dev/null | /usr/bin/head -n 1)
  case "$state" in
    *disabled*) echo "$MAYBE Printer queue present but paused ($QUEUE). It resumes by itself after firmware loads; if it stays paused, turn the printer off and on." ;;
    *) echo "$OK Printer queue present ($QUEUE)" ;;
  esac
else
  echo "$NO Printer queue missing — connect the printer by USB, then run the .pkg installer again."
fi

# 3. Printer on USB (no admin rights needed: read the USB device tree)
if /usr/sbin/ioreg -p IOUSB -l -w0 2>/dev/null | /usr/bin/grep -Eiq 'LaserJet 10(18|20|22)'; then
  echo "$OK Printer detected on USB"
else
  echo "$NO Printer not detected on USB — check the cable and that the printer is switched on. (USB hubs are fine.)"
fi

# 4. Firmware file
if [ -f "$FIRMWARE" ]; then
  actual=$(/usr/bin/shasum -a 256 "$FIRMWARE" 2>/dev/null | /usr/bin/awk '{print $1}')
  if [ "$actual" = "$EXPECTED_SHA256" ]; then
    echo "$OK Firmware installed (checksum verified)"
  else
    echo "$NO Firmware file is damaged or the wrong version — run Set Up Firmware again."
  fi
else
  echo "$NO Firmware not installed — choose Set Up Firmware."
fi

# 5. Auto-reload service
if [ -n "$QUEUE" ]; then
  LABEL="com.hp-legacy-mac-plus.firmware-watch.$QUEUE"
  if [ -f "/Library/LaunchDaemons/$LABEL.plist" ]; then
    info=$(/bin/launchctl print "system/$LABEL" 2>/dev/null || true)
    case "$info" in
      *"state = running"*) echo "$OK Auto-reload service running (loads firmware each time the printer is switched on)" ;;
      "") echo "$MAYBE Auto-reload service installed (macOS did not let this check confirm it is running; it normally is)" ;;
      *) echo "$NO Auto-reload service installed but not running — choose Set Up Firmware again." ;;
    esac
  else
    echo "$NO Auto-reload service not set up — choose Set Up Firmware."
  fi
fi

# Extra: last firmware event and current print-position setting
if [ -r /var/log/hp-legacy-mac-plus-firmware.log ]; then
  last=$(/usr/bin/tail -n 1 /var/log/hp-legacy-mac-plus-firmware.log 2>/dev/null)
  [ -z "$last" ] || echo "Last firmware event: $last"
fi
if [ -n "$QUEUE" ] && [ -r "$BASE/queues/$QUEUE.conf" ]; then
  h=$(/usr/bin/sed -n 's/^HORIZONTAL_OFFSET_MM=//p' "$BASE/queues/$QUEUE.conf")
  v=$(/usr/bin/sed -n 's/^VERTICAL_OFFSET_MM=//p' "$BASE/queues/$QUEUE.conf")
  echo "Print position: horizontal ${h:-0} mm, vertical ${v:-0} mm"
fi
if [ -r "$BASE/BUILD-MANIFEST.txt" ]; then
  ver=$(/usr/bin/sed -n 's/^Project version: //p' "$BASE/BUILD-MANIFEST.txt")
  [ -z "$ver" ] || echo "Driver version: $ver"
fi
exit 0
