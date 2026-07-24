# Changelog

Public release notes for `finogeeks/findesk-std` desktop SDK artifacts.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions match
`Geeksfino/findesk` `package.json` `version` for the published tag.

## [Unreleased]

## [2.1.19] - 2026-07-24

### Changed

- Pin `aioncoreVersion` → `v0.1.49-findesk-core.1` (wave 7/8 stack: aionrs 0.2.6,
  ACP/bootstrap ports).
- Pin `finclawVersion` → `v0.10.4`.
- Pin `finsafeVersion` → `v0.9.27`.

## [2.1.18] - 2026-07-21

### Fixed

- White-label packaging: merge brand electron-builder overlay into the base
  config so `extraResources` (aioncore / finclaw / finsafe) are not dropped.
- White-label runtime: tenant-scoped Electron `userData` / `package.json`
  identity (`productName` / `appId`) so installs no longer nest under FinDesk.

### Changed

- Pin `finclawVersion` → `v0.10.2`.
- Pin `finsafeVersion` → `v0.9.20`.

## [2.1.17] - 2026-07-21

### Changed

- Pin `aioncoreVersion` → `v0.1.43-findesk-core.7` (complete `findesk-services`
  assets including **findesk-meeting** on all release matrix triples).
- Pack bakes `aioncore` + `findesk-services` for `darwin-arm64`, `darwin-x64`,
  `linux-x64`, and `win32-x64` so white-label customers do not need Geeksfino
  tokens at `dist` time for those platforms.

## [2.1.16] - 2026-07-21

### Changed

- SDK tarball now **bakes** `aioncore` + complete `findesk-services`
  (compliance, trade, **meeting**) under `resources/bundled-*` for common
  desktop triples so white-label `dist` does not need private Geeksfino access.
- Re-publish of `findesk-desktop-sdk-2.1.16` assets (integrity digest changes —
  update `findesk.lock.json`).

### Added

- First public `findesk-desktop-sdk-2.1.16` release assets on `finogeeks/findesk-std`.
- Lock snippet + integrity for online pin from white-label distribution repos.

