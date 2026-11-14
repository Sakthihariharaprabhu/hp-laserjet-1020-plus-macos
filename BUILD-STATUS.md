# Build and test status

Last updated: 2026-11-14 · Version on this branch: see [`VERSION`](VERSION) (`0.2.0-test.1`)

## Summary

| Area | Status |
|---|---|
| CI build (Apple Silicon runner) | Passes — see the latest "Build macOS candidate" run on the pull request |
| Installer `v0.1.0-test.1` on a real Mac | ✅ Installed (after **Open Anyway**) on one MacBook Air, Apple Silicon |
| Package contents review | ✅ All programs arm64, 21 libraries bundled, no Homebrew dependencies, Ghostscript resources present, A4 PPD, filter correct, firmware checksum gate pinned, uninstaller in the app |
| Package checksum | ✅ Matched its `.sha256` (the old sidecar contained the CI runner's path, so `shasum -c` failed — fixed in 0.2.0) |
| Physical printing | ✅ One page printed on an HP LaserJet 1020 Plus via a USB hub |
| A4 alignment | ❌ Extra space on the LEFT, content cut on the RIGHT (also with the older hp-legacy-mac driver). 0.2.0 adds an adjustable offset (default −3.0 mm, an estimate) and a calibration page — **not yet confirmed on paper** |
| Automatic firmware download | ❌ Failed in 0.1.0 (quirinux.org timed out). Also found: quirinux's file is a different firmware build and could never pass the checksum. 0.2.0 downloads from this project's release instead — **not yet tested on a Mac** |
| "Select an existing firmware file" | ✅ Works with the tested file (SHA-256 `c14fdf0a…87cd01`) |
| Firmware reload after power cycle | ⏳ Not yet tested (the maintainer's test Mac did not have firmware setup completed) |
| 0.2.0 app buttons (Check Status, test page, Adjust Print Position) | ⏳ Built and checked in CI; not yet clicked on a real Mac |
| Signing / notarization | ❌ Unsigned, not notarized |

**Tested configurations: one Mac + one printer.** This is not proof that other Macs, macOS versions or printers work.

## What CI checks

- Builds the bundle on an Apple Silicon arm64 runner from pinned foo2zjs source.
- Static checks (`scripts/test-source.sh`): script syntax, version consistency, checksum-sidecar format, print-offset maths, app actions present, no firmware in the repo.
- Bundle structure (`scripts/check-bundle.sh`), including that `BUILD-MANIFEST.txt` has real line breaks.
- Pipeline smoke test: PostScript and the A4 calibration PDF are converted to printer data with the same arguments the filter now uses (offset crop, fixed A4 media, fit-to-page).
- Builds the unsigned `.pkg` and verifies its `.sha256` with `shasum -c`.

CI cannot test USB, CUPS queue behaviour, firmware upload or paper output.
