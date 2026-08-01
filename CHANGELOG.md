# Changelog

Public release notes for `finogeeks/findesk-std` desktop SDK artifacts.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions match
`Geeksfino/findesk` `package.json` `version` for the published tag.

## [Unreleased]

## [2.1.21] - 2026-08-01

### Changed

- Pin `aioncoreVersion` → `v0.1.51-findesk-core.1` (OpenCode sandbox FS allowlist,
  Hub/BYOK model wiring, Windows FinSAFE empty deny_read / narrow policy paths,
  DingTalk delivery hardening, FinClaw channel assistant regression alignment).

### Added

- Distribution template: daily **findesk-std upstream watch** workflow +
  `scripts/watch-findesk-std.sh` — opens `upstream:findesk-std` issues when the
  lock pin lags the latest public SDK (no auto bump).
- Maintainer train: `scripts/stack/detect-core-drift.sh` + `core-drift-watch.yml`
  (see Geeksfino/findesk `findesk-docs/contributing/core-sdk-release-train.md`).

## [2.1.20] - 2026-08-01

### Fixed

- White-label `prepareAioncore`: reuse SDK-baked binaries even when an empty
  `managed-resources/` leftover is present; avoid wiping the bake and hitting
  private `Geeksfino/findesk-core` download URLs that 404 without `GH_TOKEN`.
- Private release download fallback now tries the GitHub Releases API
  (`Accept: application/octet-stream`) after `gh`, with clearer auth errors.
- White-label missing-binary errors point at SDK cache / `FINDESK_PLATFORM`
  instead of implying a public GitHub download.

### Changed

- Pin `aioncoreVersion` → `v0.1.50-findesk-core.1`.
- Pin `finclawVersion` → `v0.10.7`.
- Pin `finsafeVersion` → `v0.9.29` (Windows AppContainer warm-launch ACL/ProjFS
  fast paths; pairs with Geeksfino/findesk-core#104 narrow Windows policy paths).

### Desktop (included since 2.1.19)

- Runtime install reliability, Hub model display name, Windows FinSAFE empty
  deny_read RT mode, Models picker for weak ACP / Hermes, cloud subagent wake
  via AG-UI, FinSAFE session posture settings, and related desktop fixes.

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

