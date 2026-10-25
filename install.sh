#!/bin/sh
# Security-conscious installer for a locally reviewed HP LaserJet 1020 bundle.
set -eu
umask 077

BASE="/Library/Printers/hp-legacy-mac"
FILTER="/usr/libexec/cups/filter/hp-legacy-mac"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUNDLE="${HP_LEGACY_BUNDLE:-$SCRIPT_DIR/dist/bundle}"
QUEUE="${HP_LEGACY_QUEUE:-HP_LaserJet_1020_Plus}"
PARENT=$(dirname "$BASE")

msg() { printf '%s\n' "HP LaserJet 1020 Plus: $*"; }
die() { printf '%s\n' "HP LaserJet 1020 Plus: ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Please run this installer as an administrator."
[ "$(uname -s)" = "Darwin" ] || die "This installer requires macOS."
[ "$(uname -m)" = "arm64" ] || die "This build target is Apple Silicon only."
[ -d "$BUNDLE" ] || die "The driver bundle is missing. This package is not complete."
[ -x "$BUNDLE/bin/gs" ] || die "Bundle is missing bin/gs."
[ -x "$BUNDLE/bin/gsed" ] || die "Bundle is missing bin/gsed."
[ -x "$BUNDLE/bin/dc" ] || die "Bundle is missing bin/dc."
[ -x "$BUNDLE/bin/foo2zjs" ] || die "Bundle is missing bin/foo2zjs."
[ -x "$BUNDLE/bin/foo2zjs-wrapper" ] || die "Bundle is missing bin/foo2zjs-wrapper."
[ -x "$BUNDLE/bin/foo2zjs-pstops" ] || die "Bundle is missing bin/foo2zjs-pstops."
[ -f "$BUNDLE/ppd/HP-LaserJet_1020.ppd.gz" ] || die "Bundle is missing the HP 1020 PPD."
[ -f "$BUNDLE/cups-filter" ] && [ -x "$BUNDLE/cups-filter" ] || die "Bundle is missing executable cups-filter."
[ -f "$BUNDLE/firmware-watch.sh" ] && [ -x "$BUNDLE/firmware-watch.sh" ] || die "Bundle is missing firmware-watch.sh."

case "$QUEUE" in ''|*[!A-Za-z0-9_.-]*) die "Queue name contains unsupported characters." ;; esac
[ "${#QUEUE}" -le 64 ] || die "Queue name is too long."

# Do all conflict checks before creating/modifying installed files.
if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  die "A printer queue named '$QUEUE' already exists. Nothing was changed. Choose a different queue name."
fi

if find "$BUNDLE" -type l -print | grep . >/dev/null 2>&1; then
  die "The bundle contains symbolic links. Nothing was changed."
fi
for f in "$BUNDLE/bin/gs" "$BUNDLE/bin/gsed" "$BUNDLE/bin/dc" "$BUNDLE/bin/foo2zjs" "$BUNDLE/bin/foo2zjs-wrapper" "$BUNDLE/bin/foo2zjs-pstops" "$BUNDLE/ppd/HP-LaserJet_1020.ppd.gz" "$BUNDLE/cups-filter" "$BUNDLE/firmware-watch.sh"; do
  [ -f "$f" ] || die "Required file is not a regular file: $f"
done

DEVICE_LIST=$(/usr/libexec/cups/backend/usb 2>/dev/null | awk 'tolower($0) ~ /laserjet(%20|[ +])?1020/ { for (i=1;i<=NF;i++) if ($i ~ /^usb:/) print $i }' | sort -u)
DEVICE_COUNT=$(printf '%s\n' "$DEVICE_LIST" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
[ "$DEVICE_COUNT" -ge 1 ] || die "No HP LaserJet 1020 USB printer was detected. Connect and power it on; no files were changed."
[ "$DEVICE_COUNT" -eq 1 ] || die "More than one HP LaserJet 1020 USB printer is connected. Disconnect the printer you do not want to configure and retry; no files were changed."
DEVICE_URI=$(printf '%s\n' "$DEVICE_LIST" | sed -n '1p')

[ -d "$PARENT" ] || die "Expected system printer directory does not exist: $PARENT"
STAGE=$(mktemp -d "$PARENT/.hp1020-stage.XXXXXX")
FILTER_TMP=$(mktemp "$PARENT/.hp1020-filter.XXXXXX")
PPD_TMP=$(mktemp "$PARENT/.hp1020-ppd.XXXXXX")
CONF_TMP=$(mktemp "$PARENT/.hp1020-conf.XXXXXX")
FILTER_BACKUP=""
BASE_BACKUP=""
BASE_EXISTED=0
FILTER_EXISTED=0
QUEUE_CREATED=0
COMMIT=0

cleanup() {
  [ -z "$STAGE" ] || rm -rf "$STAGE"
  rm -f "$FILTER_TMP" "$PPD_TMP" "$CONF_TMP"
  if [ -n "$FILTER_BACKUP" ] && [ -f "$FILTER_BACKUP" ]; then rm -f "$FILTER_BACKUP"; fi
}
rollback() {
  rc=$?
  trap - EXIT HUP INT TERM
  if [ "$rc" -ne 0 ] && [ "$COMMIT" -eq 0 ]; then
    msg "An installation step failed; restoring previous files."
    if [ "$QUEUE_CREATED" -eq 1 ]; then lpadmin -x "$QUEUE" >/dev/null 2>&1 || true; fi
    if [ "$FILTER_EXISTED" -eq 1 ] && [ -n "$FILTER_BACKUP" ] && [ -f "$FILTER_BACKUP" ]; then install -o root -g wheel -m 755 "$FILTER_BACKUP" "$FILTER" 2>/dev/null || true
    elif [ "$FILTER_EXISTED" -eq 0 ]; then rm -f "$FILTER"; fi
    if [ "$BASE_EXISTED" -eq 1 ] && [ -n "$BASE_BACKUP" ] && [ -d "$BASE_BACKUP" ]; then rm -rf "$BASE"; mv "$BASE_BACKUP" "$BASE" 2>/dev/null || true
    elif [ "$BASE_EXISTED" -eq 0 ]; then rm -rf "$BASE"; fi
  fi
  cleanup
  exit "$rc"
}
trap rollback EXIT
trap 'exit 1' HUP INT TERM

if [ -e "$FILTER" ]; then
  [ -f "$FILTER" ] || die "Existing CUPS filter path is not a regular file. Nothing was changed."
  FILTER_EXISTED=1
  FILTER_BACKUP=$(mktemp "$PARENT/.hp1020-filter-backup.XXXXXX")
  cp -p "$FILTER" "$FILTER_BACKUP"
fi
if [ -e "$BASE" ]; then
  [ -d "$BASE" ] || die "Existing driver path is not a directory. Nothing was changed."
  BASE_EXISTED=1
  BASE_BACKUP=$(mktemp -d "$PARENT/.hp1020-base-backup.XXXXXX")
  rmdir "$BASE_BACKUP"
fi

mkdir -p "$STAGE/bundle"
ditto "$BUNDLE" "$STAGE/bundle"
[ -x "$STAGE/bundle/bin/gs" ] || die "Staged Ghostscript failed validation."
[ -x "$STAGE/bundle/bin/gsed" ] || die "Staged GNU sed failed validation."
[ -x "$STAGE/bundle/bin/dc" ] || die "Staged dc failed validation."
[ -x "$STAGE/bundle/bin/foo2zjs-wrapper" ] || die "Staged foo2zjs wrapper failed validation."
[ -x "$STAGE/bundle/bin/foo2zjs-pstops" ] || die "Staged foo2zjs-pstops failed validation."
[ -x "$STAGE/bundle/cups-filter" ] || die "Staged CUPS filter failed validation."
gunzip -c "$STAGE/bundle/ppd/HP-LaserJet_1020.ppd.gz" > "$PPD_TMP"
sh "$SCRIPT_DIR/scripts/normalize-ppd.sh" "$PPD_TMP" "$PPD_TMP.normalized"
mv "$PPD_TMP.normalized" "$PPD_TMP"
grep -q '^\\*ModelName:' "$PPD_TMP" || die "PPD does not contain a ModelName."
grep -v '^\\*cupsFilter' "$PPD_TMP" > "$PPD_TMP.clean"
mv "$PPD_TMP.clean" "$PPD_TMP"
printf '*cupsFilter: "application/vnd.cups-pdf 0 hp-legacy-mac"\n' >> "$PPD_TMP"
cat > "$CONF_TMP" <<'EOF'
DRIVER_ID="hp1020"
COLOR_CAPABLE=0
EOF
install -o root -g wheel -m 755 "$STAGE/bundle/cups-filter" "$FILTER_TMP"

if [ "$BASE_EXISTED" -eq 1 ]; then mv "$BASE" "$BASE_BACKUP"; fi
mkdir -p "$BASE"
ditto "$STAGE/bundle" "$BASE"
chown -R root:wheel "$BASE"
find "$BASE" -type d -exec chmod 755 {} \\\;
find "$BASE" -type f -exec chmod 644 {} \\\;
chmod 755 "$BASE/bin/gs" "$BASE/bin/gsed" "$BASE/bin/dc" "$BASE/bin/foo2zjs" "$BASE/bin/foo2zjs-wrapper" "$BASE/bin/foo2zjs-pstops" "$BASE/cups-filter" "$BASE/firmware-watch.sh"
install -o root -g wheel -m 755 "$FILTER_TMP" "$FILTER"
mkdir -p "$BASE/queues"
install -o root -g wheel -m 644 "$CONF_TMP" "$BASE/queues/$QUEUE.conf"

QUEUE_CREATED=1
lpadmin -p "$QUEUE" -v "$DEVICE_URI" -P "$PPD_TMP" -E -o PageSize=A4 -o printer-error-policy=retry-job
cupsenable "$QUEUE"
cupsaccept "$QUEUE"

COMMIT=1
trap - EXIT HUP INT TERM
cleanup
if [ "$BASE_EXISTED" -eq 1 ]; then msg "Previous driver retained at: $BASE_BACKUP"; fi
[ -z "$FILTER_BACKUP" ] || rm -f "$FILTER_BACKUP"
msg "Printer queue created: $QUEUE"
msg "Firmware is not bundled or downloaded. Use the separate GUI firmware setup workflow when it is included and validated."
msg "This package cannot be called a validated release until the bundled binaries and physical printing are tested."
