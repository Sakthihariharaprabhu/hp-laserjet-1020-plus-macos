# Build status — engineering test candidate

Last checked: 2026-10-25

## Latest confirmed CI build

- Workflow run: [#21 — Build macOS candidate](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/actions/runs/40209197664)
- Branch: `main`
- Source commit built: `2f7666359e2a127e7bb82bd8612181d2fc098bdf`
- Result: **success**
- Artifact: `hp-laserjet-1020-plus-macos-arm64-candidate`
- Artifact ID: `12604783804`
- Artifact ZIP SHA-256: `237b441377a433d22001d81c432c82734aab0b68b53299787ccbd8a86bffe9c4`
- Artifact expiry: 2026-11-08 15:56 UTC

## What the successful run establishes

- The workflow ran on an Apple Silicon ARM64 macOS runner.
- The pinned driver bundle was built.
- Static/source checks and bundle checks passed.
- The bundled Ghostscript-to-`foo2zjs` conversion pipeline generated a non-empty test stream.
- An unsigned candidate installer package and checksum sidecar were uploaded as a workflow artifact.

## What it does not establish

- The installer has not been validated end-to-end on a physical Mac.
- Printing to a physical HP LaserJet 1020 / 1020 Plus has not been confirmed.
- Firmware acquisition, firmware upload after power cycle, LaunchDaemon behavior, USB/CUPS queue management and recovery paths have not been physically validated.
- The package is not signed or notarized and is not ready for general distribution.

The artifact ZIP checksum above applies to the downloaded **Actions ZIP**, not to the individual `.pkg`. Use the sidecar `.sha256` inside the artifact to verify the package itself.

## Current decision

**Engineering test candidate only.** Do not describe it as a stable driver or confirmed macOS 26-compatible release. See [test instructions](TESTING.md), [security notes](docs/SECURITY.md), and the [release checklist](docs/RELEASE-CHECKLIST.md).
