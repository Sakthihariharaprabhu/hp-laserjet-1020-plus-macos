# Release checklist

## Build and supply chain
- [ ] Run the pinned build on a clean Apple Silicon Mac.
- [ ] Verify exact `foo2zjs` source commit and record SHA-256 hashes.
- [ ] Verify the exact source archives and checksums for Ghostscript, JBIG-KIT, GNU sed, GNU bc/dc, and dylibbundler.
- [ ] Include license notices and corresponding source archives/build scripts for all redistributed components.
- [ ] Generate an SBOM and checksum manifest.
- [ ] Verify no firmware or personal machine paths/serials are included.
- [ ] Verify `otool -L` has no Homebrew Cellar references and all non-system dependencies are bundled.

## Security
- [ ] Shell lint and static analysis pass.
- [ ] Installer rollback tested with failure injected at each mutating step.
- [ ] Existing queue conflict exits without modifying files.
- [ ] Ambiguous USB matches fail closed.
- [ ] Queue config permissions are root-owned and not writable by normal users.
- [ ] Uninstaller leaves unrelated queues and files untouched, including cleanup of the firmware LaunchDaemon/raw queue for the selected queue.
- [ ] Independent review of privileged scripts completed.

## Functional validation
- [ ] Install on macOS 26.6.2 (build 25G83), Apple Silicon arm64.
- [ ] USB model/URI detection validated for HP LaserJet 1020 Plus.
- [ ] Firmware setup app accepts only the reviewed local firmware checksum and never downloads firmware.
- [ ] Firmware upload works after each power cycle using a user-supplied authorized firmware file.
- [ ] Raw queue serialization, queue pause/resume, and timeout behavior are tested on the target macOS release.
- [ ] Print a text document, a PDF, multi-page content, and image-containing content.
- [ ] Check A4 geometry and margins; verify Letter if supported.
- [ ] Test disconnected USB, paper-out, cancelled job, and firmware-not-loaded behavior.
- [ ] Reboot, power-cycle, and reconnect tests pass.
- [ ] Install/uninstall/reinstall tested; existing installation rollback proven.
- [ ] Physical test reports and known limitations published.

## Release
- [ ] End-user GUI or signed installer package is ready.
- [ ] Developer ID signing/notarization completed if distributing a package.
- [ ] Version, source commit, checksums, and reproducible build instructions recorded.
- [ ] Explicit compatibility claim limited to configurations actually tested.
