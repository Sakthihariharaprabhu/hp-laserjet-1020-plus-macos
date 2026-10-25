# HP LaserJet 1020 Plus for modern macOS (Apple Silicon)

> **Experimental test candidate — not a verified release.** Automated build checks pass, but the installer, firmware workflow, USB/CUPS behavior, and physical printing have not yet been validated end-to-end on a real target Mac and printer.

This project explores USB printing support for the HP LaserJet 1020 / 1020 Plus on Apple Silicon Macs, including macOS 26, using OpenPrinting `foo2zjs` and Ghostscript.

## Current test status

GitHub Actions run [#21](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/actions/runs/40209197664) completed successfully on `main` for source commit `2f7666359e2a127e7bb82bd8612181d2fc098bdf`. It built an ARM64 candidate and passed source/bundle checks and a native conversion-pipeline smoke test. Those checks **do not prove** that macOS will install the package or that a real printer will print correctly.

Use the [test instructions](TESTING.md) before attempting a supervised test. The current package is unsigned and not notarized. Do not disable Gatekeeper, SIP, or system security protections. If macOS reports that the package contains malware, is damaged, or will damage the computer, stop and record the exact warning. If it says only that the developer cannot be verified, review the source and ask the maintainer before deciding what to do.

## What is included

- OpenPrinting driver source fetched at a pinned commit during the build.
- A locally built bundle containing the 1020-family PPD, `foo2zjs` wrapper, Ghostscript resources and required libraries.
- A separate candidate install path and CUPS filter (`hp-legacy-mac-plus`) intended not to overwrite the earlier `hp-legacy-mac` installation.
- A GUI firmware setup app source, with automatic retrieval/conversion from the community mirror referenced by OpenPrinting's `foo2zjs` helper **or** selection of a local `.dl` firmware file. Both paths check the converted firmware against a reviewed SHA-256 before installation.

HP's proprietary `sihp1020.dl` binary is not committed to this repository or embedded in the installer. Automatic firmware retrieval uses a third-party community mirror, not an official HP download endpoint. A matching checksum establishes that the output matches the expected bytes; it does not establish the mirror's trustworthiness or grant legal rights to use/redistribute firmware. Internet access is needed for the automatic path.

## For maintainers: build requirements

On an Apple Silicon Mac, install Xcode Command Line Tools, Homebrew and Git. The build script may install Homebrew packages if missing: `ghostscript`, `jbigkit`, `gnu-sed`, `dylibbundler`, and `bc` (for `dc`). Review the scripts before running them.

```sh
sh build/build-bundle.sh
sh scripts/check-bundle.sh dist/bundle
sh scripts/test-source.sh
sh scripts/smoke-driver-pipeline.sh dist/bundle
```

GitHub Actions runs on an Apple Silicon macOS runner and publishes an unsigned candidate artifact. The successful pipeline is build/static/runtime-smoke evidence only, not physical-printer validation.

## Installation and firmware notes

Do not use the source checkout's `sudo sh install.sh` command as a casual end-user installation instruction. It is a source-level/manual install path for reviewers. For a test, use only a clearly identified package attached to a GitHub test pre-release after checking its release notes and checksum; do not use an old Actions artifact.

The candidate normally creates a queue named `HP_LaserJet_1020_Plus_Candidate` unless `HP_LEGACY_QUEUE` is set. If that name already exists, the installer should exit rather than change installed files. The firmware setup and LaunchDaemon/raw-queue workflow is not yet physically tested and may require troubleshooting.

## Known limitations before general distribution

- No end-to-end physical print test has been completed on macOS 26.6.2 (build 25G83) with an Apple Silicon Mac and HP LaserJet 1020 Plus.
- The unsigned, non-notarized candidate is not suitable for broad distribution to ordinary users.
- Firmware acquisition/use rights, signing/notarization, dependency-license compliance, installer rollback, CUPS behavior, USB device matching and failure recovery still require review/testing.
- Paper geometry is configured for A4 by default; actual margins and clipping need a physical test.

See [test instructions](TESTING.md), [security notes](docs/SECURITY.md), [firmware workflow](docs/FIRMWARE-WORKFLOW.md), [release checklist](docs/RELEASE-CHECKLIST.md), [build status](BUILD-STATUS.md), and [test release notes template](docs/TEST-RELEASE-NOTES.md).
