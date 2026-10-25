# Release checklist

Use this checklist before distributing a package beyond a small, explicitly consenting test group. A green CI run is necessary but not sufficient.

## Build and supply chain

- [ ] Run the pinned build on a clean Apple Silicon macOS runner.
- [ ] Record the exact source commit, workflow run URL and SHA-256 hashes for the release assets.
- [ ] Verify the exact source archives and checksums for Ghostscript, JBIG-KIT, GNU sed, GNU bc/dc and dylibbundler.
- [ ] Include required license notices and corresponding source archives/build scripts for all redistributed components.
- [ ] Generate an SBOM and checksum manifest.
- [ ] Verify no firmware binary, printer serial number, secrets or personal machine paths are included.
- [ ] Verify `otool -L` has no Homebrew Cellar references and all non-system dependencies are bundled.

## Security and installer

- [ ] Shell lint and static analysis pass.
- [ ] Installer rollback is tested with failure injected at each mutating step.
- [ ] A pre-existing candidate queue name exits without modifying installed files.
- [ ] Ambiguous USB matches fail closed.
- [ ] Queue configuration is root-owned and not writable by normal users.
- [ ] Uninstaller leaves unrelated queues and files untouched, including candidate LaunchDaemon/raw-queue cleanup.
- [ ] Privileged scripts have an independent review.
- [ ] Developer ID signing and Apple notarization are completed for ordinary-user distribution; do not ask users to disable Gatekeeper or SIP.

## Firmware workflow

- [ ] GUI accepts a local `.dl` file or retrieves/converts firmware from the documented community mirror.
- [ ] Both paths reject any resulting binary that does not match the reviewed SHA-256.
- [ ] Community-mirror availability, provenance, and firmware download/use rights are reviewed.
- [ ] Firmware upload, raw queue, queue pause/resume, completion detection and recovery are tested after every power cycle.
- [ ] Failed or timed-out firmware upload is clearly reported and recoverable.

## Functional validation

- [ ] Install on macOS 26.6.2 (build 25G83), Apple Silicon arm64.
- [ ] Verify USB model/URI detection for the HP LaserJet 1020 Plus.
- [ ] Print a single-page text document, a PDF, multi-page content and image-containing content.
- [ ] Check A4 geometry, margins, top-edge clipping and bottom whitespace; verify Letter only if supported.
- [ ] Test disconnected USB, paper-out, cancelled job and firmware-not-loaded behavior.
- [ ] Reboot, power-cycle and reconnect tests pass.
- [ ] Install/uninstall/reinstall tested; safe rollback proven.
- [ ] Record the tester's Mac model, macOS version, printer model, results and any logs/warnings.

## Release

- [ ] Test pre-release is clearly labelled as experimental and links to the matching source commit.
- [ ] Attach the `.pkg` and its `.sha256` sidecar; confirm the checksums match the downloaded files.
- [ ] Include known limitations, firmware-source caveat and non-affiliation disclaimer.
- [ ] Developer ID signing/notarization completed before broad distribution.
- [ ] Compatibility claims are restricted to configurations actually tested.
