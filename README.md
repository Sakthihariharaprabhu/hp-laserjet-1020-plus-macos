# HP LaserJet 1020 Plus for modern macOS (Apple Silicon)

**Engineering candidate — not yet a verified release.** This repository is intended for the HP LaserJet 1020 / 1020 Plus over USB on Apple Silicon Macs, including the macOS 26 family. The driver pipeline is based on OpenPrinting `foo2zjs` and Ghostscript.

The source and installer are being prepared for a real Mac test. They have **not** been tested end-to-end on macOS 26.6.2 in this build environment. Do not treat a successful script check as proof that printing works.

## What is and is not included

- Open-source driver source is fetched at a pinned commit by the build script.
- The build creates a local `dist/bundle` with the 1020 PPD, `foo2zjs` wrapper, Ghostscript, resources and required libraries.
- HP's proprietary `sihp1020.dl` firmware binary is **not stored in the repository or embedded in the installer**. The included GUI setup app can automatically retrieve the source image over HTTPS from the community mirror referenced by OpenPrinting's `foo2zjs`, convert it locally, and install it only if the output matches the reviewed SHA-256. Internet access is required for automatic setup; selecting an existing local firmware file remains available. The mirror is a community source, not HP support.
- The installer refuses to proceed if the built bundle is incomplete.
- No firmware, printer serial number, or personal machine paths are intentionally committed.

## Build requirements (developer step)

On an Apple Silicon Mac: Xcode Command Line Tools, Homebrew, Git, and internet access. The build script installs these Homebrew packages if missing: `ghostscript`, `jbigkit`, `gnu-sed`, `dylibbundler`, and `bc` (for `dc`). Review the script before running it. It builds the driver from the pinned OpenPrinting revision and bundles the Ghostscript runtime so the CUPS sandbox does not depend on Homebrew paths.

```sh
sh build/build-bundle.sh
sh scripts/check-bundle.sh dist/bundle
```

The build script is for maintainers. The packaging script now creates a GUI firmware-setup app and an installer-package candidate. Signing/notarization still requires Developer ID certificates and a configured Apple notary profile; the GUI and installer are not yet validated on macOS.

## Install (engineering candidate only)

The installer requires administrator privileges and creates a separate candidate driver directory and CUPS filter (`hp-legacy-mac-plus`) so it does not overwrite the earlier `hp-legacy-mac` installation. Do not run it until the candidate has passed review and local print testing.

```sh
sudo sh install.sh
```

It creates a queue named `HP_LaserJet_1020_Plus_Candidate` unless `HP_LEGACY_QUEUE` is set. If that name already exists, it exits before changing installed files. It does not automatically send firmware and does not change SIP, Gatekeeper, or system USB backend permissions.

## Firmware after power-on

The HP LaserJet 1020 family needs its firmware uploaded after each printer power-on. This project does not redistribute or download HP firmware. The package includes a double-clickable **HP LaserJet Firmware Setup** app source. It can automatically download and convert the firmware from the upstream community mirror, or accept a local `.dl` file. Both methods validate the reviewed SHA-256 before requesting administrator authorization and configuring a launchd monitor. Automatic acquisition requires internet access. The monitor is designed to send the firmware through a separate raw queue when USB is detected or re-detected, temporarily pausing the normal queue during upload. This workflow is not yet physically tested; do not consider it release-ready until power-cycle, raw-queue, failure, and recovery tests pass. See `docs/FIRMWARE-WORKFLOW.md`.

## Known limitations before release

- No physical print test has been performed by the project maintainer on macOS 26.6.2.
- The build has not yet been executed on a real Apple Silicon Mac in this workspace.
- The current engineering candidate is an unsigned, non-notarized preview. A successful build verifies the source checks and packaging pipeline, not actual print compatibility. Only use a newly generated artifact for a supervised private test after reviewing its digest; do not treat it as a general-distribution release.
- The GUI firmware setup and launchd automation are source-level candidates; CUPS/USB behavior still needs a Mac test.
- Firmware acquisition/use rights and the final non-terminal workflow need review.
- The installer/filter rollback and CUPS interactions require failure-injection tests on a disposable Mac.

See [Security notes](docs/SECURITY.md) and [release checklist](docs/RELEASE-CHECKLIST.md).

## Current engineering status

This repository candidate is source-level work in progress, not a release. The build must run on an Apple Silicon macOS runner; a Linux shell cannot validate macOS framework, CUPS, launchd, or Mach-O runtime behavior. The build workflow is intended to generate an unsigned candidate artifact for review. A public distribution release requires a Developer ID Application signature for the GUI app, a Developer ID Installer signature for the package, and Apple notarization. See `docs/RELEASE-CHECKLIST.md` and `docs/FIRMWARE-WORKFLOW.md`.

The PPD normalizer sets A4 as the default page size, region, imageable area, and paper dimension, while preserving the upstream A4 printable margins. This is intended to prevent Letter/A4 layout mismatches; actual top-edge clipping and bottom whitespace still require a physical print test.

See `docs/BUILD-AND-SIGNING.md` for native build and Developer ID signing requirements.
