# HP LaserJet 1020 / 1020 Plus on Apple Silicon Macs

Print to an HP LaserJet 1020 or 1020 Plus from a modern Mac (M1, M2, M3, M4…), **without using Terminal**.

> **Test version.** It works on the maintainer's Mac and printer (one MacBook Air + one LaserJet 1020 Plus). It is **not signed or notarized by Apple** yet, so macOS shows a warning the first time — the steps below show exactly what to click. See [Known limitations](#known-limitations).

---

## Quick start

```
1. Download .pkg  →  2. Double-click  →  3. Open Anyway (only if blocked)  →  4. Print
                     firmware is set up automatically during installation
```

**Before you start:** connect the printer by USB (a USB hub is fine) and switch it on.

1. **Download** `HP-LaserJet-1020-Plus-macOS-arm64-unsigned.pkg` from the [Releases page](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/releases). *Optional:* also the `.sha256` file to [check the download](#optional-check-the-download).
2. **Double-click the `.pkg`** and follow the installer.
3. **If macOS says "Apple could not verify … free of malware":** click **Done** (not Move to Trash), then open **System Settings → Privacy & Security**, scroll down, click **Open Anyway** next to the installer's name, and enter your password. Then run the installer again.
4. **Firmware is set up automatically** at the end of the installation (needs internet). You don't need to do anything.
   - Only if that was not possible (for example no internet), the **HP LaserJet Firmware Setup** app opens by itself and asks **Set Up Now?** → follow it. See [Get the firmware file](#get-the-firmware-file).
5. **Optional — check alignment once:** Applications → **HP LaserJet Firmware Setup** → **Print Alignment Test Page**. If the frame is not centred, follow [Page is shifted or cut off](#page-is-shifted-or-cut-off).

Now print normally from any app and pick the printer **HP_LaserJet_1020_Plus_Candidate**, paper **A4**.

**Something wrong?** Open the app → **Check Status**. It tells you in plain words what is working and what is not. Then see [Troubleshooting](#troubleshooting).

### Updating from an older test version

The installer does not overwrite an older installation. First remove it: **HP LaserJet Firmware Setup → Uninstall Driver**, then install the new `.pkg` and run **Set Up Firmware** again.

### Uninstall

Open **HP LaserJet Firmware Setup → Uninstall Driver** → choose the printer → **Remove**. This removes the printer queue, the firmware service and the driver files. Other printers and older HP drivers are left alone. Then drag the app to the Trash.

### Optional: check the download

This proves the `.pkg` was not damaged or changed. In the folder where you downloaded both files, this command must print `OK` (Terminal is only needed for this optional step):

```bash
cd ~/Downloads && shasum -a 256 -c HP-LaserJet-1020-Plus-macOS-arm64-unsigned.pkg.sha256
```

---

## Get the firmware file

The printer needs HP's firmware file `sihp1020.dl` every time it is switched on. The app checks the file's SHA-256 fingerprint before installing it, so a wrong or damaged file is always refused, whichever way you get it:

| Way | How |
|---|---|
| **A. Release download** | Download `sihp1020.dl` from the [firmware release](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/releases/tag/firmware-hp1020), then choose **Select an existing firmware file**. |
| **B. Automatic** (default) | Happens by itself during installation. Or in the app: **Download and verify firmware automatically**. Downloads the same file from the project's release (needs internet). |
| **C. Your own copy** | From an old HP / `hp-legacy-mac` driver installation, or from Linux foo2zjs: `/usr/share/foo2zjs/firmware/sihp1020.dl`. Choose **Select an existing firmware file**. |

Accepted file: `sihp1020.dl`, SHA-256 `c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01`. Other `sihp1020` files on the internet are often a **different firmware build** and will be refused (this is on purpose — only the tested file is accepted).

> HP firmware, copyright HP, provided for owners of this printer; removed on request.

### Why firmware?

The LaserJet 1020 **forgets its firmware every time it is switched off**. After **Set Up Firmware**, a small background service on your Mac notices when the printer is switched on or plugged in and sends the firmware automatically. The installer sets this up automatically, so it is **one time only** — afterwards just switch the printer on and print, like any normal printer. If you print while the printer is off, the job waits and prints once it is switched on.

---

## Troubleshooting

First open **HP LaserJet Firmware Setup → Check Status**. It shows ✅/❌ for: driver installed · printer queue present · printer detected on USB · firmware installed · auto-reload service running.

### "Apple could not verify … is free of malware"

Expected, because the installer is not signed by Apple yet. Click **Done**, then **System Settings → Privacy & Security → Open Anyway**, enter your password, and open the installer again. Never turn off Gatekeeper or SIP. If macOS says the file **is damaged** or **contains malware** (stronger wording), stop and [report it](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/issues/new?template=printer-problem.yml).

### "The installation failed"

Usually an older version is still installed. Run **HP LaserJet Firmware Setup → Uninstall Driver**, then install again. Also make sure the printer is connected and switched on during installation — the installer needs to see it on USB.

### "Firmware download was not completed"

The download source could not be reached (for example, a network or firewall blocks it) or the file was refused. Nothing was installed. In the same message, click **Select a File Now** and pick a `sihp1020.dl` you got from [Get the firmware file](#get-the-firmware-file) (way A or C).

### Page is shifted or cut off

Symptom: extra blank space on one side, text cut off on the other side, even with A4 selected everywhere.

1. Load plain A4 paper. Open the app → **Print Alignment Test Page**.
2. With a ruler, measure the gap from each paper edge to the thick frame line: **A** = left, **B** = right, **C** = top, **D** = bottom. On a perfect print all four are 10 mm.
3. Horizontal correction = **(B − A) ÷ 2** mm. Vertical correction = **(D − C) ÷ 2** mm.
   Example: A = 13, B = 7 → −3 mm (moves the print left).
4. App → **Adjust Print Position** → enter *current value + correction* → **Save** → **Print Test Page Again**.

Allowed range: −10 to +4 mm. The setting applies from the next page; no reinstall needed. New installs start at −3.0 mm horizontal (an estimate that still needs confirming on more printers).

### Printer connected through a USB hub

Works (tested with a hub). If **Check Status** says "Printer not detected on USB", try a different port or connect directly, and check the printer's power.

### It printed once, but not after switching the printer off and on

Firmware was probably never set up (the first page can work because another driver had loaded it). Run **Set Up Firmware**, then **Check Status**: "Auto-reload service running" must be ✅.

### Still stuck?

[Open a "Printer problem" issue](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/issues/new?template=printer-problem.yml) and paste the **Check Status** text. Please don't include serial numbers or personal information.

---

## Known limitations

- **Unsigned and not notarized.** macOS warns on first install (see above). Signing is on the [roadmap](ROADMAP.md).
- **Tested on one Mac + one printer only:** MacBook Air (Apple Silicon) + HP LaserJet 1020 Plus, connected through a USB hub, A4 paper. Other models (1018, 1022, P100x) are not supported yet.
- **Alignment:** the default −3 mm horizontal correction is an estimate. Calibrate with the test page.
- **Firmware reload after a power cycle** uses a CUPS "raw" print queue. CUPS has marked raw queues as deprecated; they work on current macOS but **may stop working in a future macOS version**.
- **Firmware download source:** quirinux.org (used by Linux foo2zjs) is not used, because its file is a different firmware build than the tested one and would always be refused. See [docs/FIRMWARE-WORKFLOW.md](docs/FIRMWARE-WORKFLOW.md).
- Only A4 and Letter paper sizes are offered for alignment correction.

---

## For maintainers

Everything below is for people building or reviewing the project.

- Build status and evidence: [BUILD-STATUS.md](BUILD-STATUS.md) · Tester guide: [TESTING.md](TESTING.md) · [Roadmap](ROADMAP.md)
- [Security notes](docs/SECURITY.md) · [Firmware workflow](docs/FIRMWARE-WORKFLOW.md) · [Release checklist](docs/RELEASE-CHECKLIST.md) · [Build and signing](docs/BUILD-AND-SIGNING.md) · [Upstreams](UPSTREAMS.md)

### How it works

```
App (PDF) → CUPS → hp-legacy-mac-plus filter → foo2zjs-wrapper -z1 -P -L0 -p9 -r1200x600
                                                 -u/-l from queue offset, -dFIXEDMEDIA -dPDFFitPage
          → Ghostscript (bundled) → foo2zjs → USB printer
Power-on → LaunchDaemon notices USB → sends sihp1020.dl through a raw queue → resumes the print queue
```

- Version lives in [`VERSION`](VERSION); the package version and release tag (`v` + VERSION) must match.
- Print offset: `HORIZONTAL_OFFSET_MM` / `VERTICAL_OFFSET_MM` in `/Library/Printers/hp-legacy-mac-plus/queues/<queue>.conf`, converted to foo2zjs crop values by [`src/hp1020-clip`](src/hp1020-clip).
- Calibration page source: [`calibration/a4-alignment-test.ps`](calibration/a4-alignment-test.ps).

### Build

On an Apple Silicon Mac with Xcode Command Line Tools, Homebrew and Git (the script may `brew install` ghostscript, jbigkit, gnu-sed, dylibbundler, bc):

```sh
sh build/build-bundle.sh
sh scripts/test-source.sh
sh scripts/check-bundle.sh dist/bundle
sh scripts/smoke-driver-pipeline.sh dist/bundle
sh packaging/build-release.sh
```

GitHub Actions ("Build macOS candidate") runs the same steps on an Apple Silicon runner for every pull request and can be started manually. HP firmware is never committed to git or placed inside the `.pkg`.

This is an independent community project, not affiliated with or endorsed by HP. Driver: [OpenPrinting foo2zjs](https://github.com/OpenPrinting/foo2zjs) (GPL) and Ghostscript.
