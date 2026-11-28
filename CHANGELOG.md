# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Pairing: with both files present and nothing preferred, Remote Pairing is chosen on iOS 17+ (Lockdown below).
- Pairing: a combined pairing file (Remote Pairing + Lockdown, as iLoader writes) is accepted instead of failing with "The pairing file format is ambiguous".
- Pairing: load an existing pairing file at launch even when no protocol is marked preferred (no more prompt on every launch).
- Apple ID sign-in: new anisette defaults (Mac server, Mac OS X client info), automatic client-info normalization, automatic adi.pb re-provisioning when the client identity changes, and Mac-only server failover.

### Changed
- Pairing File Management: Set as Preferred button at the bottom of each card, with a confirmation that warns when the protocol is not recommended for this iOS version.
- Release channels: rolling Nightly, numbered Beta, Stable promoted from a tested beta.
- Forked from SideStore develop @ 4f3d18d9 (2026-11-06).

### Removed
- Upstream agent policy files.
