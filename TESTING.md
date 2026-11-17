# Supervised test instructions

## Results so far (14 Nov 2026)

One tester, one configuration: MacBook Air (Apple Silicon), HP LaserJet 1020 Plus via a USB hub, A4 paper, package `v0.1.0-test.1`.

- Package checksum matched; contents reviewed (arm64 only, bundled libraries, no Homebrew dependencies).
- macOS showed "Apple could not verify … free of malware" (expected for unsigned); **Privacy & Security → Open Anyway** worked; installed OK.
- A page printed. **Alignment problem:** blank space on the left, content cut on the right (A4 chosen in Page Setup and the print dialog). Same with the older hp-legacy-mac driver.
- Automatic firmware download failed (timeout to quirinux.org). "Select an existing firmware file" with the tested `sihp1020.dl` is the working path.
- Power-cycle firmware reload: not yet tested.

For 0.2.0 please test: **Set Up Firmware** (automatic and file), **Check Status**, **Print Alignment Test Page** + **Adjust Print Position**, and printing after switching the printer off and on.

This is an experimental driver candidate. A successful CI build is not proof that the installer or printer works. Only test if you understand that troubleshooting may be required and the Mac can be recovered if the test fails.

## Before installing

1. Confirm the Mac is Apple Silicon and note the exact macOS version/build.
2. Confirm the printer is an HP LaserJet 1020 or 1020 Plus connected by USB (direct or through a hub — note which).
3. Make sure the existing/legacy driver still works or record its current state. The candidate is designed to use separate paths, but that isolation still needs real-machine validation.
4. Download only the `.pkg` attached to the project's explicitly labelled GitHub test pre-release. Do not use a ZIP of the repository source as an installer, and do not use old Actions artifacts.
5. Verify the package with the attached `.sha256` sidecar before opening it.

## macOS security warnings

The package is unsigned and not notarized, so macOS may block it. Do not disable Gatekeeper, SIP or other security protections. If the dialog says the package contains malware, is damaged, or will damage the computer, stop and send the maintainer a screenshot of the exact message. If it only says the developer cannot be verified, stop and ask the maintainer before deciding whether to proceed.

## Test sequence

Record the result of each step, including any error text:

- Install the candidate package and record any macOS installer messages.
- Open **HP LaserJet Firmware Setup** and record which option was used. If automatic firmware retrieval fails or the checksum does not match, do not bypass validation.
- Confirm the candidate queue appears. Do not remove or overwrite the legacy printer queue.
- Print a one-page plain-text document, then a PDF, a multi-page document and a page containing an image.
- Check that the page content is upright, complete and aligned on A4 paper. Use **Print Alignment Test Page** and report the four gaps (A left, B right, C top, D bottom) and the offset you ended up with.
- Open **Check Status** and copy its text into your report.
- Turn the printer off and on, then test another print to check firmware reinitialization.
- If something fails, stop rather than repeatedly reinstalling or changing unrelated macOS settings. Record the exact dialog, error and stage of the process.

## Feedback template

- Mac model / Apple Silicon chip:
- macOS version and build:
- Printer model:
- USB connection direct or hub:
- Existing driver installed before test:
- Installer result:
- Firmware setup method and result:
- Test print results (text / PDF / multi-page / image):
- A4 alignment:
- Print after printer power cycle:
- Exact warnings/errors:
- Uninstall result:
- Additional notes:

Use the GitHub issue template **Printer problem** — it contains these same fields.

Do not share serial numbers, account credentials, private paths or other personal information in public issue reports. The maintainer should treat all successful reports as reports from a specific configuration, not proof of universal compatibility.
