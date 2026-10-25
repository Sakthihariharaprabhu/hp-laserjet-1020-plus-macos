# Security and supply-chain notes

## Scope

This project installs a CUPS filter and a local driver bundle under `/Library/Printers/hp-legacy-mac-plus`. The installer, GUI firmware helper and firmware monitor include privileged operations. Review them before use, and test only on a machine that can tolerate troubleshooting or rollback.

## Decisions made in the current candidate

- Upstream `foo2zjs` source is pinned to commit `80499ed5bf6caa2963ad337e37cfda78a80aab1e`, not a moving branch.
- The build refuses to overwrite an existing `dist/bundle` directory and removes only its own partial output after a failed build.
- HP's firmware binary is not committed or embedded in the installer.
- The CUPS filter does not source queue configuration or execute a PPD-derived command.
- The installer does not change SIP, Gatekeeper, or permissions on Apple's USB backend.
- Queue names are validated before use in paths or commands.
- Firmware setup validates a known SHA-256 before copying the firmware to a root-owned path; the monitor rechecks the checksum before every upload.
- The monitor uses a separate raw queue and pauses the normal queue during firmware upload to reduce the chance that a print job starts before firmware initialization.
- A failed firmware job should not be silently reported as success.

## Current verification

GitHub Actions run [#21](https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos/actions/runs/40209197664) completed successfully for source commit `2f7666359e2a127e7bb82bd8612181d2fc098bdf` on `main`. It built the ARM64 candidate and passed source/bundle checks and a conversion-pipeline smoke test.

This is not a security audit or an end-to-end Mac/printer test. The package is unsigned and not notarized; do not disable Gatekeeper, SIP, or other platform protections to install it. If macOS reports malware, damage, or a risk that the package will damage the computer, stop.

## Open risks / unresolved items

1. **Physical behavior is unverified.** Confirm USB detection, printing, firmware setup after power cycle, raw-queue behavior, queue pause/resume and recovery on the target macOS version.
2. **Third-party licensing:** Ghostscript and other redistributed dependencies need review of exact source archives, Homebrew formula patches, notices and license obligations before binary distribution.
3. **Firmware source and rights:** automatic acquisition uses a community mirror referenced by OpenPrinting, not an official HP endpoint. A matching SHA-256 does not certify the mirror or establish rights to download/use/redistribute firmware.
4. **Installer rollback:** test failure injection on a disposable Mac, including pre-existing driver/filter paths and queue-creation failures.
5. **CUPS filter contract:** validate PDF/PS input handling, wrapper arguments, Ghostscript resources and output ZjStream bytes against the exact built version.
6. **Device matching:** verify USB backend output selects the intended HP LaserJet 1020 device and refuses ambiguous multiple-device matches.
7. **Signing and notarization:** no Developer ID identity or Apple notary profile is configured in this project; the candidate artifact is unsigned and non-notarized.
8. **Physical print tests:** test text, PDF, multi-page and image-containing documents; A4 margins/clipping; disconnect/reconnect; paper-out; cancelled jobs; reboot; uninstall/reinstall; and recovery from failed firmware upload.

Do not publish a compatibility claim beyond configurations actually tested. Static shell checks and a conversion-pipeline smoke test are not proof that installation or physical printing works.
