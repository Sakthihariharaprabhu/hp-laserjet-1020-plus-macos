# Security and supply-chain notes

## Scope

This project installs a CUPS filter and local driver bundle under `/Library/Printers/hp-legacy-mac-plus`. The installer and firmware monitor require administrator/root privileges and must be reviewed as privileged code before use.

## Decisions made

- Upstream `foo2zjs` source is pinned to commit `80499ed5bf6caa2963ad337e37cfda78a80aab1e`, not a moving branch.
- The build refuses to overwrite an existing `dist/bundle` directory and removes only its own partial output after a failed build.
- The build does not fetch or include HP firmware.
- The CUPS filter does not source queue configuration or execute a PPD-derived command.
- The installer does not change SIP, Gatekeeper, or permissions on Apple's USB backend.
- Queue names are validated before they are used in paths or commands.
- Firmware setup validates a known SHA-256 before copying the file to a root-owned path; the monitor rechecks the checksum before every upload.
- The monitor uses a separate raw queue and pauses the normal queue during the firmware upload to reduce the chance of a print job racing ahead of firmware initialization.
- A failed firmware job leaves the normal queue paused rather than silently claiming success.

## Open risks / unresolved items

1. **Source has changed after the last native build.** GitHub Actions built a prior ARM64 revision, but the current isolation and firmware fixes require a fresh run before the resulting package can be tested.
2. **Third-party license compliance:** Ghostscript and other redistributed dependencies need review of exact source archives, Homebrew formula patches, notices, and license obligations before binary distribution.
3. **Firmware monitor untested:** verify that USB backend visibility changes on printer power-cycle; test raw queue support, queue pause/resume, job completion detection, and recovery from a failed upload on the target macOS version.
4. **Installer rollback:** failure-injection testing is required on a disposable Mac, including pre-existing driver directory, filter, and queue creation failure.
5. **CUPS filter contract:** validate PDF/PS input handling, wrapper arguments, Ghostscript resources, and output ZjStream bytes against the exact built version.
6. **Device matching:** USB backend output varies; confirm detection selects the intended HP LaserJet 1020 device and refuses ambiguous multiple-device matches.
7. **Signing and notarization:** no Developer ID identity or Apple notary profile is available in this environment. Unsigned builds are not for ordinary-user distribution.
8. **Physical tests:** none have been completed on the target Mac/printer pair by this build environment.

Never publish a claim of compatibility until the test matrix is complete. A clean shell syntax check is not proof of safety or functionality.
