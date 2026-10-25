# Firmware workflow (automatic acquisition option; review required before release)

The HP LaserJet 1020 family requires firmware upload after printer power-on. This project does not commit or redistribute HP's proprietary firmware binary. The GUI offers two methods:

1. **Download and verify firmware automatically.** The app retrieves `sihp1020.tar.gz` from `https://www.quirinux.org/printers/`, the HTTPS mirror referenced by OpenPrinting's `foo2zjs/getweb` helper; it streams only `sihp1020.img` to a private temporary directory, runs the bundled OpenPrinting `arm2hpdl` converter, and checks that the resulting `sihp1020.dl` has SHA-256 `c14fdf0af84d1df40545eef7c7d4e2e07dd58fe933e14cc7c29697209e87cd01`. This requires internet access and relies on a community mirror rather than an official HP download endpoint.
2. **Select an existing local file.** The same SHA-256 validation runs before installation. The project does not upload the selected file.

The downloader runs as the logged-in user and does not require administrator privileges. The privileged setup helper independently rechecks the checksum before copying the firmware into a root-owned local directory. It then configures a LaunchDaemon to upload the firmware through a separate raw queue when USB is detected or re-detected. The monitor is designed to pause the normal queue while firmware is uploaded and require CUPS to confirm completion before resuming it.

## Security checks

- HTTPS is required, and redirects are restricted to HTTPS.
- The helper streams only the expected archive member rather than extracting arbitrary archive paths.
- It installs nothing unless the converted download matches the known SHA-256.
- The temporary downloaded file is removed after the GUI completes setup.
- No firmware binary is committed to the repository or embedded in the public installer.

## Important limitations

- A matching hash protects against a different or corrupted payload; it does not certify the mirror itself or grant redistribution rights.
- The mirror can change, go offline, or stop serving the file. If download or checksum validation fails, the app stops and offers no bypass.
- The firmware setup app, downloader, LaunchDaemon, CUPS behavior, recovery path, and failure modes have not yet been physically validated on a current macOS and must be tested before general distribution.
