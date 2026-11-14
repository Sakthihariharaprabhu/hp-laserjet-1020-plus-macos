# Roadmap

Ideas for later. Nothing here is being built yet.

## More printer models — needs testers

The same foo2zjs driver family covers more HP models. Each needs its own firmware file, its own reviewed SHA-256 and a physical test before it is offered.

| Model | Firmware file | Status |
|---|---|---|
| HP LaserJet 1018 | `sihp1018.dl` | Needs testers |
| HP LaserJet 1022 | to be confirmed (may not need a firmware upload) | Needs testers |
| HP LaserJet P1005 | `sihpP1005.dl` | Needs testers |
| HP LaserJet P1006 | `sihpP1006.dl` | Needs testers |
| HP LaserJet P1007 / P1008 | `sihpP1005.dl` / `sihpP1006.dl` (to be confirmed) | Needs testers |
| HP LaserJet P1505 | `sihpP1505.dl` | Needs testers |

If you own one of these and want to help, open an issue with the "Printer problem" template and say which model you have.

## Signing and notarization

If the project gets real users: sign the package and app with an Apple Developer ID and notarize them, so macOS no longer shows the "could not verify" warning. The build script already supports this when the certificates exist (see [docs/BUILD-AND-SIGNING.md](docs/BUILD-AND-SIGNING.md)).

## Other ideas

- Replace the deprecated CUPS raw queue used for firmware upload with a direct USB upload, before macOS removes raw queue support.
- In-place upgrades (today an older version must be uninstalled first).
- Accept the 2005-03-09 firmware build (served by quirinux.org) as a second checksum, only after it has been physically tested.
