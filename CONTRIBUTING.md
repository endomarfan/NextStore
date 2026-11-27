# Contributing to NextStore

By contributing to this project, you agree to the Developer's Certificate of Origin found in [CERTIFICATE-OF-ORIGIN.md](CERTIFICATE-OF-ORIGIN.md).

## Branches

- `develop` is the development branch. Open pull requests against it.
- `main` is the stable branch. It only moves on release.

## Versioning

NextStore follows [SemVer](https://semver.org):

- Pre-releases are published from `develop` as `X.Y.Z-beta.N`.
- PATCH: fixes only.
- MINOR: new features.
- MAJOR: changes that break things for users (data migration, dropped iOS versions).

Stable releases are tagged `vX.Y.Z` on `main`, and the tag must match `MARKETING_VERSION` in `Build.xcconfig`.

## AI-assisted contributions

AI-assisted contributions are allowed. Disclose any AI use in the pull request template. You must be able to explain your change.

## Testing

Changes to sign-in, pairing, VPN, install or refresh must include device test notes in the pull request (device model and iOS version, what you tried, what happened).

## Setup

1. Clone the repository: `git clone https://github.com/endomarfan/NextStore.git --recurse-submodules`
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
