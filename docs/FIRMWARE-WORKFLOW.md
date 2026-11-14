# Firmware workflow

The HP LaserJet 1020 family loses its firmware at every power-off and needs `sihp1020.dl` uploaded after power-on. HP's firmware is **never committed to git and never placed inside the `.pkg`**. It is published as a separate asset on the GitHub release [`firmware-hp1020`](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/releases/tag/firmware-hp1020).

> HP firmware, copyright HP, provided for owners of this printer; removed on request.

## The one accepted file

| | |
|---|---|
| File | `sihp1020.dl` (126,151 bytes, header date 2004-11) |
| SHA-256 | `c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01` |
| Evidence | Physically used with an HP LaserJet 1020 Plus by the maintainer |

The same SHA-256 is pinned in `fetch-firmware.sh`, `setup-firmware.sh` (privileged re-check), `firmware-watch.sh` (re-check before every upload) and `status.sh`.

## Ways to get it (GUI app → Set Up Firmware)

1. **Download and verify automatically.** `fetch-firmware.sh` tries each source in its `SOURCES` list in order, with a 30 s connect timeout, 3 min limit and one retry per source. Every download must match the SHA-256; anything else is rejected and nothing is installed. If all sources fail, the app shows what happened for each source and offers **Select a File Now** or **Open Instructions** (the README firmware section).
2. **Select an existing file** — downloaded from the release, from an old HP / hp-legacy-mac installation, or from Linux foo2zjs (`/usr/share/foo2zjs/firmware/sihp1020.dl`). Same checksum check.

### Download sources (checked 2026-11-14)

| Source | Result | Used? |
|---|---|---|
| This project's release `firmware-hp1020` (`.dl`) | Identical file (verified after upload) | **Yes** — only works once the repository is public |
| `https://www.quirinux.org/printers/sihp1020.tar.gz` (OpenPrinting `getweb`) | Timed out from the maintainer's network. An archived copy (Wayback Machine, 2026-11-05) converts with the pinned `arm2hpdl` to a **different firmware build**: header date 2005-03-09, 128,431 bytes, SHA-256 `133b21fe0cb24bfe53e2eff2f00a82cce4beb970749049661ade7a6801f22663` | **No** — it can never pass the checksum, so per the "identical file only" rule it is not listed |
| Wayback Machine copy of the above | Same different build | No |
| `foo2zjs.rkkda.com` (original foo2zjs site) | Domain no longer resolves | No |
| Other GitHub copies (e.g. Orthodox2000/hp-laserjet-1020-linux, koenkooi/foo2zjs `sihp1020.img`) | Do not match the accepted checksum | No — untrusted until physically tested |

The 2005-03-09 build is probably also valid 1020 firmware, but it has not been tested. Accepting it would mean adding a second reviewed checksum after a physical test (see [ROADMAP](../ROADMAP.md)).

## What Set Up Firmware does

1. The downloader runs as the logged-in user (no admin rights) in a private temporary folder.
2. `setup-firmware.sh` runs as root (password prompt), re-checks the checksum, copies the file to `/Library/Printers/hp-legacy-mac-plus/firmware/`, creates a raw queue `<queue>_Firmware` and a LaunchDaemon.
3. `firmware-watch.sh` (LaunchDaemon) polls USB every 5 s. When the printer appears, it pauses the normal queue, sends the firmware through the raw queue, waits for CUPS to report the job **completed**, then resumes the normal queue. If the job does not complete, the queue stays paused (safe default) and the event is logged to `/var/log/hp-legacy-mac-plus-firmware.log`.

## CUPS raw queue — deprecated

The firmware upload uses a CUPS **raw** queue (`lpadmin -m raw`). CUPS has deprecated raw queues (and printer drivers in general). They still work on current macOS, but **a future macOS release may remove them**, which would break the automatic firmware reload. The likely replacement is uploading directly to the USB device; see [ROADMAP](../ROADMAP.md).

## Limits

- A matching hash proves the bytes are the reviewed bytes; it does not establish any right to use or redistribute HP firmware.
- The release download only works while the repository is public and the asset exists.
- Power-cycle reload has not yet been physically tested on 0.2.0.
