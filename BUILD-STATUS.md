# Build status — engineering candidate

Date: 2026-10-25

## Checks completed in this workspace

- Shell syntax checks passed for the installer, uninstaller, CUPS filter, build scripts, packaging scripts, and firmware helper scripts.
- Static source checks passed.
- A synthetic bundle passed structural checks, including A4 defaults and required Ghostscript resource directory structure.
- The exact upstream `foo2zjs` commit `80499ed5bf6caa2963ad337e37cfda78a80aab1e` was confirmed to exist through GitHub metadata.
- The build script correctly refuses to build in this Linux workspace instead of pretending to produce macOS binaries.

## Not yet completed

- Native Apple Silicon compilation of the actual upstream source.
- Runtime dependency inspection with macOS `otool` on real Mach-O binaries.
- Actual Homebrew source archive collection and license audit.
- Building the `.pkg` on macOS.
- Developer ID signing and Apple notarization.
- GUI firmware setup, launchd plist, USB reconnect, raw queue, failure recovery, and uninstall tests on macOS.
- Physical print testing, including A4 top/bottom alignment.

## Important

This archive contains source and build tooling only. It does not contain a built driver bundle, a signed installer, or HP firmware. Do not install it as a printer driver. The next useful validation step is to push the reviewed source to the private repository (only after explicit owner approval), run the macOS ARM64 build workflow, inspect its artifacts/logs, and fix any native build failures before preparing the signed release.
