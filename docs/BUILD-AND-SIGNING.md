# Build and signing

## Build environment

The driver must be built on an Apple Silicon macOS runner because Ghostscript, `foo2zjs`, GNU sed, `dc`, and their dynamic libraries must be built/relocated and checked as macOS ARM64 binaries. The pinned upstream source revision is `80499ed5bf6caa2963ad337e37cfda78a80aab1e` (OpenPrinting/foo2zjs). Its commit exists on GitHub; it is not signed upstream, so the build pins the exact commit and verifies the checkout hash rather than trusting a moving branch.

The build script installs build dependencies with Homebrew, builds the ZJS converter and wrapper, bundles Ghostscript resources and dynamic libraries, rewrites the PPD defaults to A4, and checks for leftover Homebrew Cellar references. The resulting bundle still needs native runtime and physical-print validation.

## Signed ordinary-user installer

A release distributed outside the Mac App Store needs a Developer ID Application certificate for executable code and a Developer ID Installer certificate for the `.pkg`. Apple recommends notarization; a successful notarization ticket can be stapled to the package. See Apple's [Developer ID certificate guidance](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) and [notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

`packaging/build-release.sh` can sign and notarize only when those identities are available in the macOS keychain and the `NOTARY_PROFILE` points to a configured `notarytool` credential profile. It deliberately does not fake a signature or disable Gatekeeper. Without those credentials, it emits an explicitly unsigned preview, not a public release.

Do not place certificate private keys, Apple ID passwords, app-specific passwords, or notary credentials in the repository. If using GitHub Actions, store secrets in GitHub Actions secrets and import the signing certificate into a temporary keychain within the workflow. The repository should remain private until the owner approves publication.
