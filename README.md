# NextStore

NextStore is an independent fork of [SideStore](https://github.com/SideStore/SideStore), which is itself a fork of [AltStore](https://github.com/altstoreio/AltStore). The app is still named SideStore and keeps the bundle ID `com.SideStore.SideStore`. This project is not affiliated with the SideStore team. Please do not report issues from this fork to the upstream project.

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

SideStore is an iOS application that allows you to sideload apps onto your iOS device with just your Apple ID. It resigns apps with your personal development certificate, and then uses a [specially designed VPN](https://github.com/jkcoxson/em_proxy) in order to trick iOS into installing them. It periodically "refreshes" your apps in the background, to keep their normal 7-day development period from expiring.

## Requirements

- Xcode 27.2
- iOS 15+ (tested on iOS 27)

## Building

```sh
make build fakesign ipa
```

This creates `SideStore.ipa`. Prebuilt IPAs are published on the [Releases](https://github.com/endomarfan/NextStore/releases) page.

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
