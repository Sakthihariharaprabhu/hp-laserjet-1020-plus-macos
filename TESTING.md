# Supervised test instructions

This is an experimental driver candidate. A successful CI build is not proof that the installer or printer works. Only test if you understand that troubleshooting may be required and the Mac can be recovered if the test fails.

## Before installing

1. Confirm the Mac is Apple Silicon and note the exact macOS version/build.
2. Confirm the printer is an HP LaserJet 1020 or 1020 Plus connected directly by USB.
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
- Check that the page content is upright, complete and aligned on A4 paper; report clipping or unusual whitespace.
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

Do not share serial numbers, account credentials, private paths or other personal information in public issue reports. The maintainer should treat all successful reports as reports from a specific configuration, not proof of universal compatibility.
