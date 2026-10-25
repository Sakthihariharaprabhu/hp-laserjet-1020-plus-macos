# Firmware workflow (review required before release)

The HP LaserJet 1020 family requires a firmware upload after printer power-on. This project does not redistribute or download HP firmware. The first-run GUI helper asks the user to select a local `sihp1020.dl` file and checks its SHA-256 against the known file reviewed during development (`c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01`). It copies only that verified file into a root-owned local directory.

After setup, a LaunchDaemon monitors the USB backend. On detection/re-detection it temporarily pauses the normal print queue, sends the firmware through a separate raw queue, waits for the raw job to leave the queue and requires CUPS to record that exact job as completed before re-enabling the normal queue. If completion cannot be confirmed, the normal queue remains paused for safety. If the firmware job fails or times out, the normal queue remains paused rather than silently accepting print jobs that are likely to fail. The helper logs to `/var/log/hp-legacy-mac-plus-firmware.log`.

## Important limitations

- This automation is source-reviewed but not yet validated against a physical HP LaserJet 1020 Plus on current macOS. In particular, USB disappearance on power-cycle, raw queue behavior, CUPS queue pausing, and firmware job completion must be physically tested before release.
- The helper only accepts the known checksum. If a legitimate firmware file with a different hash is needed, do not disable the check; review and update the trusted checksum through a documented source first.
- The setup app requests administrator authorization because it installs a root-owned firmware file and a LaunchDaemon. It never fetches firmware from the network.
- The helper must not be considered release-ready until launchd plist linting, CUPS tests, reconnect tests, and a security review pass on macOS.
