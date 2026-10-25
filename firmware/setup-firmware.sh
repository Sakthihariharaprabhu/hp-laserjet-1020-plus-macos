#!/bin/sh
# Privileged helper launched by the GUI app; never asks users to open Terminal.
set -eu
umask 077
EXPECTED_SHA256=c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01
BASE=/Library/Printers/hp-legacy-mac
FIRMWARE_DIR="$BASE/firmware"
FIRMWARE="$FIRMWARE_DIR/sihp1020.dl"
WATCH="$BASE/firmware-watch.sh"

fail() { printf 'HP LaserJet firmware setup failed: %s\n' "$*" >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || fail 'administrator permission is required.'
[ "$#" -eq 2 ] || fail 'the GUI must provide a firmware file and printer queue.'
SOURCE=$1
QUEUE=$2
[ -f "$SOURCE" ] && [ -r "$SOURCE" ] || fail 'the selected firmware file cannot be read.'
case "$QUEUE" in ''|*[!A-Za-z0-9_.-]*) fail 'invalid printer queue name.' ;; esac
[ "${#QUEUE}" -le 64 ] || fail 'printer queue name is too long.'
LABEL="com.hp-legacy-mac.firmware-watch.$QUEUE"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
STATE_DIR="/var/db/hp-legacy-mac/$QUEUE"
/usr/bin/lpstat -p "$QUEUE" >/dev/null 2>&1 || fail 'the selected printer queue does not exist.'
DEVICE_URI=$(/usr/bin/lpstat -v "$QUEUE" | /usr/bin/sed -n 's/^device for [^:]*: //p')
case "$DEVICE_URI" in usb://*) ;; *) fail 'the selected queue is not a USB printer queue.' ;; esac
printf '%s' "$DEVICE_URI" | /usr/bin/grep -Eiq 'laserjet(%20|[ +])?1020' || fail 'the selected queue does not appear to target an HP LaserJet 1020.'
ACTUAL=$(/usr/bin/shasum -a 256 "$SOURCE" | /usr/bin/awk '{print $1}')
[ "$ACTUAL" = "$EXPECTED_SHA256" ] || fail 'the selected firmware file does not match the reviewed firmware checksum. No file was installed.'
[ -x "$WATCH" ] || fail 'the firmware monitor is missing from the installed package.'

RAW_QUEUE="${QUEUE}_Firmware"
case "$RAW_QUEUE" in *[!A-Za-z0-9_.-]*) fail 'derived firmware queue name is invalid.' ;; esac
[ "${#RAW_QUEUE}" -le 64 ] || fail 'derived firmware queue name is too long.'

/bin/mkdir -p "$FIRMWARE_DIR" "$STATE_DIR"
/usr/sbin/chown root:wheel "$FIRMWARE_DIR" "$STATE_DIR"
/bin/chmod 755 "$FIRMWARE_DIR"
/bin/chmod 700 "$STATE_DIR"
/usr/bin/install -o root -g wheel -m 644 "$SOURCE" "$FIRMWARE"

if /usr/bin/lpstat -p "$RAW_QUEUE" >/dev/null 2>&1; then /usr/sbin/lpadmin -x "$RAW_QUEUE"; fi
/usr/sbin/lpadmin -p "$RAW_QUEUE" -v "$DEVICE_URI" -m raw -E
/usr/sbin/lpadmin -p "$RAW_QUEUE" -o printer-error-policy=retry-job

xml_escape() { printf '%s' "$1" | /usr/bin/sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
WATCH_XML=$(xml_escape "$WATCH")
QUEUE_XML=$(xml_escape "$QUEUE")
RAW_QUEUE_XML=$(xml_escape "$RAW_QUEUE")
URI_XML=$(xml_escape "$DEVICE_URI")
FIRMWARE_XML=$(xml_escape "$FIRMWARE")
TMP_PLIST=$(mktemp /Library/LaunchDaemons/.hp1020-firmware.XXXXXX)
trap 'rm -f "$TMP_PLIST"' EXIT HUP INT TERM
/usr/bin/printf '%s\n' \
'<?xml version="1.0" encoding="UTF-8"?>' \
'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
'<plist version="1.0"><dict>' \
"<key>Label</key><string>$LABEL</string>" \
'<key>ProgramArguments</key><array>' \
"<string>$WATCH_XML</string>" \
"<string>$QUEUE_XML</string>" \
"<string>$RAW_QUEUE_XML</string>" \
"<string>$URI_XML</string>" \
"<string>$FIRMWARE_XML</string>" \
'</array>' \
'<key>RunAtLoad</key><true/>' \
'<key>KeepAlive</key><true/>' \
'<key>StandardOutPath</key><string>/var/log/hp-legacy-mac-firmware.log</string>' \
'<key>StandardErrorPath</key><string>/var/log/hp-legacy-mac-firmware.log</string>' \
'</dict></plist>' > "$TMP_PLIST"
/usr/sbin/chown root:wheel "$TMP_PLIST"
/bin/chmod 644 "$TMP_PLIST"
/bin/mv "$TMP_PLIST" "$PLIST"
/usr/bin/plutil -lint "$PLIST" >/dev/null
/bin/launchctl bootout system "$PLIST" >/dev/null 2>&1 || true
/bin/launchctl bootstrap system "$PLIST"
/bin/launchctl kickstart -k "system/$LABEL"
printf 'Firmware setup complete. The helper will upload the verified firmware when the USB printer is detected.\n'
