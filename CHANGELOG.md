# Changelog

Public release notes for `finogeeks/findesk-std` desktop SDK artifacts.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions match
`Geeksfino/findesk` `package.json` `version` for the published tag.

## [Unreleased]

## [2.1.33] - 2026-08-10

### Added

- `host.plugins.capture` (Proposal 0025): opt-in Screen Recording capture for
  plugins, plus sidecar status `authToken` for runtime bearer auth.
- Optional `headers` on `host.plugins.mcp.upsertHttp` so streamable HTTP MCP
  entries can send `Authorization` (Skill Recorder `/mcp`).
- Project hired Persona Store deployments into FinClaw/Hermes per-instance
  runtime homes at admit time (hard-fail + rollback on projection failure).

## [2.1.32] - 2026-08-09

### Changed

- Pin `finclawVersion` → `v0.11.3` (layered tool display / `--details`, MCP
  invocation-policy reconnect hardening).
- Pin `aioncoreVersion` → `v0.1.57-findesk-core.1` (Layer-1 FinClaw display +
  `tool_progress` ingest, ACP activity text on tool-call events, vault-first
  `knowledge_ask` fix, Hermes SOUL fail-closed).

## [2.1.31] - 2026-08-06

### Fixed

- Pin `finclawVersion` → `v0.11.2` (tool-result truncation + Majordomo thrash class).
- Unset bare shell `LLM_*` when spawning FinClaw for Peer Share and plugin
  sidecars so Hub `FINCLAW_LLM_*` wins (`set_env_if_unset` hygiene).
- Pin `aioncoreVersion` → `v0.1.55-findesk-core.1` (same bare-`LLM_*` strip on
  conversation FinClaw serve).

## [2.1.30] - 2026-08-06

### Added

- Security Center & network governance (Proposal 0023): settings UI for egress
  posture (open / controlled / locked), allowlist editing, deny toasts with
  allow-once, audit panel, permission-health recheck, and distribution network
  floor support.

### Changed

- Pin `aioncoreVersion` → `v0.1.54-findesk-core.1` (Security Center APIs +
  spawn-time network policy / egress audit wiring).
- Pin `finsafeVersion` → `v0.9.33` (`FINSAFE_PROXY_AUDIT_LOG` /
  `FINSAFE_PROXY_ALLOWLIST_FILE` passthrough for run/self-confine).

## [2.1.29] - 2026-08-05

### Fixed

- Plugin sidecar `ensure()` no longer deadlocks when Hub LLM auth refreshes
  mid-start (nested `refreshRunningPluginSidecars` → `ensure`). Deferred
  `reensureAfter` re-runs once with the post-Hub `FINCLAW_LLM_*` fingerprint so
  Knowledge Vault / casst stops hanging on "Vault service: …" and does not
  stay on no-credentials after login.
- After a successful Hub LLM provider sync, running plugin sidecars are
  refreshed (same path as access-token refresh).

## [2.1.28] - 2026-08-05

### Changed

- Pin `finclawVersion` → `v0.11.1` and `finsafeVersion` → `v0.9.31` (baked into
  the SDK tarball). Same desktop feature set as 2.1.27 otherwise.

## [2.1.27] - 2026-08-05

### Added

- Distribution-configured ChatKit / FinSkills hub URLs (Proposal 0024): optional
  `integrations` on `pack/tenant.json`, materialize into brand, seed-once into
  Settings, optional `hubUrlsLocked` for org-managed read-only hubs. Distro
  template docs: `docs/hub-urls.md`.
- Peer Share **Path H**: direct peer chat without local relay LLM, streaming UI,
  Guid Peers picker contributions, progress/probe/reconnect contracts
  ([#174](https://github.com/Geeksfino/findesk/pull/174)).

### Fixed

- Peer Share / plugin sidecar LLM env reads `findesk.defaultModel` (and legacy
  `aionrs.defaultModel`) so serve no longer comes up with empty credentials
  after default-model key migration.
- Plugin sidecars stay `ready=false` when LLM resolution fails even if HTTP
  health passes (`llmError` separate from spawn errors).
- Sidecar `ensure()` no longer coalesces onto an in-flight start — Hub LLM
  token sync while the first spawn is in `waitUntilReady` re-evaluates
  `FINCLAW_LLM_*` instead of leaving casst answering empty.
- After a successful Hub LLM access-token sync, running plugin sidecars are
  refreshed so they stop calling Hub with a stale JWT.
- Plugin sidecar prepare re-runs when `versionPin` changes or when
  `localArtifact` is newer than `prepare-manifest.json` (stale SDK cache).

### Changed

- Distribution template (`template/` / `docs/private-plugins.md` +
  `dist-private-plugin` skill): documents `host.plugins.*` and
  `findesk.sidecars[]` so white-label distros can ship privileged plugins
  (storage / files / sidecars / MCP) without reverse-engineering FDE.

## [2.1.26] - 2026-08-05

### Fixed

- Bake public `finsafe` + `finclaw` pins into the desktop SDK tarball for every
  packaged triple. FinSAFE-enabled distributions no longer start without
  `AIONCORE_FINSAFE_BIN` / `AIONCORE_FINCLAW_BIN` on a clean pin (same
  `aioncoreVersion` as 2.1.25).

## [2.1.25] - 2026-08-05

### Fixed

- Renderer start failure from an invalid JSX comment between props on Guid
  (`AgentPillBar` / create-agent runtime refresh). Same `aioncoreVersion` as
  2.1.24 (`v0.1.53-findesk-core.1`).

## [2.1.24] - 2026-08-05

### Changed

- Pin `aioncoreVersion` → `v0.1.53-findesk-core.1`:
  - Sync session MCP servers into FinClaw conversation profiles and
    `runtime_home` config before serve (so vault / Guid-attached tools stay
    available across resume).
  - Self-heal stale ACP session ids on the prompt path after agent
    restart/eviction.
  - Release workflow skips GitHub Release publish when no build artifacts
    uploaded.

## [2.1.23] - 2026-08-05

### Added

- Generic plugin sidecars and plugin platform privileges (proposal 0022); remove
  first-party Knowledge Vault plugin ([#169](https://github.com/Geeksfino/findesk/pull/169)).
- Agent-control delete/provision APIs and My Agents management UX ([#160](https://github.com/Geeksfino/findesk/pull/160)).
- Cron platform phase 1 (desktop), Peer Share inbound env fix, and incremental
  build source-hash fix ([#151](https://github.com/Geeksfino/findesk/pull/151)).

### Changed

- Same `aioncoreVersion` pin as 2.1.22 (`v0.1.52-findesk-core.1`). Pending
  findesk-core branch merges are **not** included in this SDK release.

## [2.1.22] - 2026-08-03

### Changed

- Pin `aioncoreVersion` → `v0.1.52-findesk-core.1` (extension ACP catalog env
  stored as `AgentEnvEntry` sequence so declared env is no longer dropped;
  config-driven runtime allowlist via `AIONCORE_RUNTIME_POLICY_FILE` /
  `runtime-policy.json`).

### Added

- Guid runtime picker: distribution `extraAllowedProviders` from the same
  `runtime-policy.json` as backend admission (shared path resolution with
  unpackaged Electron fallback).
- My Agents / create-modal visual polish (proposal 0020 Phase A): portraits,
  featured-tile imagery, human subtitles, token-based hover/scrim; tenant-pack
  `brand.agentVisuals` → `__FINDESK_BRAND__` with `resolveAgentVisual`
  precedence; Agent Store `iconAsset` enrichment via host `listPersonas`.

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

