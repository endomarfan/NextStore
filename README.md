<div align="center">

# NextStore

**Sideload apps on your iPhone with just your Apple ID — no computer needed after setup.**

A stability-focused, independent fork of [SideStore](https://github.com/SideStore/SideStore).

[![Latest release](https://img.shields.io/github/v/release/NextStoreApp/NextStore?include_prereleases&sort=semver&label=latest&color=7b3fe4)](https://github.com/NextStoreApp/NextStore/releases)
[![Nightly build](https://img.shields.io/github/actions/workflow/status/NextStoreApp/NextStore/nightly.yml?branch=develop&label=nightly)](https://github.com/NextStoreApp/NextStore/actions/workflows/nightly.yml)
[![License: AGPL v3](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](LICENSE)

</div>

NextStore installs IPA files on your device, signs them with your personal development certificate, and refreshes them in the background before their 7-day signature expires. It uses a [local VPN loopback](https://github.com/jkcoxson/em_proxy) through [LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN), so after the first install it works without a computer.

The app is still named **SideStore** and keeps the bundle ID `com.SideStore.SideStore`, so it installs over an existing SideStore and keeps your apps and settings. NextStore is not affiliated with the SideStore team — please report problems [here](https://github.com/NextStoreApp/NextStore/issues), not upstream.

## Why this fork

- **Releases you can rely on**: numbered betas, and a stable release as soon as a beta passes device testing.
- **Stability first**: Apple ID sign-in, 2FA, pairing, VPN, installing and refreshing are fixed before anything new is added.
- **Reproducible builds**: every dependency is pinned to an exact revision and every IPA is built by GitHub Actions.

## Downloads

| Channel | For | Where |
|---|---|---|
| Stable | Everyday use | The release marked "Latest" on the [Releases](https://github.com/NextStoreApp/NextStore/releases) page |
| Beta | Testing upcoming fixes | Numbered pre-releases named "NextStore X.Y.Z Beta N" |
| Nightly | Checking one specific fix; may be broken | Pre-release named "NextStore Nightly" |

### Installing

1. Download **SideStore.ipa** from a release.
2. Install it with [iLoader](https://iloader.app) (Windows, macOS, Linux). Installing over SideStore keeps your apps and settings.
3. Install [LocalDevVPN](https://apps.apple.com/app/localdevvpn/id6755608044) from the App Store and turn it on when you install or refresh apps.

## Requirements

- Xcode 27.2
- iOS 15+ (tested on iOS 27)

## Building

```sh
make build fakesign ipa
```

This creates `SideStore.ipa`. Prebuilt IPAs are published on the [Releases](https://github.com/NextStoreApp/NextStore/releases) page.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for more details.

## Project Overview

### SideStore
SideStore is a regular, sandboxed iOS application. The AltStore app target contains the vast majority of its functionality, including all the logic for downloading and updating apps.

### EM Proxy
[EM Proxy](https://github.com/jkcoxson/em_proxy) powers untethered app installation. By leveraging a custom-built App Store app with additional entitlements ([LocalDevVPN](https://github.com/jkcoxson/LocalDevVPN)) to create the VPN tunnel, it allows the app to take advantage of [Jitterbug](https://github.com/osy/Jitterbug)'s loopback method without requiring a paid developer account.

### Minimuxer
[Minimuxer](https://github.com/jkcoxson/minimuxer) is a lockdown muxer that can run inside iOS's sandbox. It replicates Apple's usbmuxd protocol on macOS to "discover" devices to interface with LocalDevVPN on-device.

## Licensing

This project is licensed under the **AGPLv3 license**.
