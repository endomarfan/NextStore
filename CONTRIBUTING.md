# Contributing to NextStore

By contributing to this project, you agree to the Developer's Certificate of Origin found in [CERTIFICATE-OF-ORIGIN.md](CERTIFICATE-OF-ORIGIN.md).

## Branches

- `develop` is the development branch. Open pull requests against it.
- `main` is the stable branch. It only moves on release.

## Versioning

NextStore follows [SemVer](https://semver.org):

- PATCH: fixes only.
- MINOR: new features.
- MAJOR: changes that break things for users (data migration, dropped iOS versions).

Stable releases are tagged `vX.Y.Z` on `main`, and the tag must match `MARKETING_VERSION` in `Build.xcconfig`.

## Releases

There are three channels:

- **Stable**: everyday use. Tagged `vX.Y.Z`, shown as "Latest" on the Releases page.
- **Beta**: testing upcoming fixes. Numbered pre-releases `vX.Y.Z-beta.N`, titled "NextStore X.Y.Z Beta N".
- **Nightly**: checking one specific fix; may be broken. A single rolling pre-release "NextStore Nightly", rebuilt after every change to `develop`.

To cut a beta: Actions → Beta → Run workflow on `develop`, with optional highlights (markdown shown at the top of the release notes).

To promote a beta: Actions → Release → Run workflow with the beta tag (for example `v1.0.0-beta.3`). It rebuilds that exact commit as `X.Y.Z`, tags it, fast-forwards `main`, and publishes the release. Afterwards bump `MARKETING_VERSION` on `develop` (PATCH by default).

Every merged fix is published in Nightly. A numbered beta bundles fixes that were checked on Nightly; while unreleased fixes exist, a beta follows within two weeks. A beta that passes the device checklist is promoted to stable.

## AI-assisted contributions

AI tools and AI coding agents are welcome. AI-written changes are held to the same bar as any other change: they are reviewed line by line, must pass CI, and changes to sign-in, pairing, VPN, install or refresh must be tested on a real device before they reach a beta. Whoever opens the pull request is responsible for its content.

### Rules for AI coding agents

1. **One problem per pull request.** Make the smallest change that fully solves it. No drive-by refactors, renames or reformatting, especially in sign-in, anisette, code signing, pairing and networking code.
2. **Understand before changing.** Read the whole code path you touch. Base the change on evidence (a log, an issue, a measured server response, an upstream commit) and link it in the pull request. Write down assumptions you could not check.
3. **Test the logic.** Put decision logic in a testable unit (for example `Packages/NextStoreKit`) with a test that fails without the fix. Never weaken, skip or delete tests or CI checks to get a green build.
4. **Say exactly what was verified.** The pull request states what was tested (unit tests, CI build, simulator, device with model and iOS version) and what was not. Never claim a device test that did not happen.
5. **Protect users' data and working setups.** Migrations run once (a `MaintenanceManager` pass), change only what is broken, and log every change. Do not reset sign-in data, certificates, pairing files or app data unless the fix requires it, and say so in the pull request.
6. **No secrets, ever.** Never commit, log or paste Apple IDs, passwords, verification codes, anisette data (`adi.pb`), certificates, private keys, pairing files or device UDIDs.
7. **Dependencies are pinned.** Every package and submodule points at an exact revision. Do not add a dependency when the platform or a few lines of code do the job; explain every new one.
8. **No guessed endpoints.** Do not add servers, URLs or Apple endpoints that are not documented in the code, the linked evidence or the pull request.
9. **Leave upstream alone.** Never open issues or pull requests, or comment, on SideStore's repositories. Code taken from upstream is cherry-picked with its original author and commit referenced.
10. **Write it down in detail.** Pull requests explain what changed, why, how it was tested, what was not tested, and the risks. Commit messages explain why, in English, with a Conventional Commit prefix (`feat`, `fix`, `ci`, `build`, `docs`, `chore`): release notes are grouped by it.
11. **Match the code around you.** Follow `.editorconfig` and the style of the surrounding code; use Swift Concurrency (`async`/`await`, actors) for new code.

## Testing

Changes to sign-in, pairing, VPN, install or refresh must include device test notes in the pull request (device model and iOS version, what you tried, what happened).

## Setup

1. Clone the repository: `git clone https://github.com/NextStoreApp/NextStore.git --recurse-submodules`
2. Copy `CodeSigning.xcconfig.sample` to `CodeSigning.xcconfig` and fill in the values.
3. **(Development only)** Change the value for `ALTDeviceID` in the Info.plist to your device's UDID, otherwise apps will not be resigned (or installed) for the proper device. Do not commit it.
4. Open `AltStore.xcodeproj` in Xcode (15 or newer; releases are built with Xcode 27.2).

## Building an IPA

```sh
make build fakesign ipa
```

- Default configuration is `Release`. For debug builds: `export BUILD_CONFIG=Debug`.
- To use a custom bundle ID suffix: `export BUNDLE_ID_SUFFIX=XYZ0123456`.
- Output: `SideStore.ipa`.

When building from Xcode, `BUNDLE_ID_SUFFIX` defaults to the value of `DEVELOPMENT_TEAM`. This can be customized in `CodeSigning.xcconfig`.

> **Warning**
>
> The binary created will contain paths to Xcode's DerivedData, which include your username. If you want to keep your username private, let GitHub Actions build the IPA instead.
