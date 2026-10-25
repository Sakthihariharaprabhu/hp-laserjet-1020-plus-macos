# Build status — engineering candidate

Date: 2026-10-25

## Confirmed

- GitHub Actions produced a native Apple Silicon ARM64 unsigned installer package in run 5.
- The downloaded artifact ZIP checksum matched GitHub's published artifact digest.
- The package contains ARM64 Mach-O driver binaries and a GUI firmware setup app.
- The previous package was inspected by extracting its package payload.
- Review found issues in the earlier package: it targeted the same installed driver/filter paths as the legacy installation, had fragile PPD checks/config parsing, and treated a disappearing firmware job as success.
- Source changes have been committed to isolate the candidate paths, correct PPD parsing, harden firmware completion handling, and update GitHub Actions to Node.js 24-compatible action versions.

## Critical artifact status

The previously built artifact is stale relative to the reviewed source fixes. **Do not install the earlier artifact.** A new native build and package inspection are required before any user test.

## Remaining blockers before green light

- Confirm the updated GitHub Actions workflow runs successfully and the Node.js 20 warning is gone.
- Inspect the newly built package payload and verify its checksums.
- Verify the new installer only creates the isolated candidate queue and never modifies the legacy driver's paths.
- Re-run static shell checks and bundle checks against the exact current source.
- Confirm firmware watcher completion/failure behavior and that queue recovery is understandable to a nontechnical user.
- Review package license notices/source archives for private testing and ensure firmware remains excluded.
- Physical print test on macOS 26.6.2 (Apple Silicon), including firmware setup, USB reconnect/power cycle, A4 alignment, and recovery/uninstall.

## Important

This remains an engineering candidate, not a release. No physical test has been performed on the user's Mac. The user should not install any artifact until a fresh build is reviewed and an explicit green light is given.
