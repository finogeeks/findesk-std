---
name: dist-packaging
description: |
  Doctor, materialize, start, and package a FinDesk white-label distribution from
  this distribution repo (no FinDesk monorepo required). Use when pinning the
  desktop SDK, building installers, fixing Unknown distribution, explaining
  where cache/app/user-data live, or configuring pack telemetry (Sentry / OTLP).
---

# Distribution packaging

Read [docs/getting-started.md](../../../docs/getting-started.md),
[docs/packaging.md](../../../docs/packaging.md),
[docs/hub-urls.md](../../../docs/hub-urls.md) (optional ChatKit / FinSkills hubs),
and [docs/telemetry.md](../../../docs/telemetry.md) (optional Sentry / OTLP)
first.

## Preconditions

- Working directory = **distribution repo root** (has `catalog.json` + `findesk.lock.json`).
- Bun available. FinDesk / findesk-core source **not** required.
- Lock has `findesk.artifact` + `findesk.integrity` (`sha256-` + 64 hex).

## Commands (always via repo scripts)

```bash
bun run doctor
bun run materialize
bun run start
bun run dist -- --mac --arm64 --pack-only
bun run dist -- --mac --arm64
```

When an `upstream:findesk-std` issue says a newer SDK is available, bump
`findesk.lock.json` from the release lock snippet, then doctor/materialize again.
See [docs/upstream-sdk.md](../../../docs/upstream-sdk.md). Local check:

```bash
bash scripts/watch-findesk-std.sh --dry-run
```

Scripts set `FINDESK_DIST_REPO` and `FINDESK_WHITE_LABEL=1`. `dist.sh` **materializes
before** packaging — do not skip that. Platform `dist` also **auto-prepares plugin
sidecars** (same as `start`) and fails the build if a declared sidecar cannot be
prepared.

CI: `.github/workflows/dist.yml` (manual) builds installers per platform — it fetches
the pinned SDK tarball from the findesk-std release, prepares sidecars (downloading
e.g. `casst.tar.zst` per plugin manifests), materializes, dists, and uploads
artifacts. Builds are unsigned until signing secrets are added.

## Checklist

```
- [ ] Lock pin valid (artifact exists or HTTPS URL reachable)
- [ ] pack/tenant.json brand + configHome set
- [ ] Optional integrations hubs validated (docs/hub-urls.md) when configured
- [ ] Optional telemetry validated (docs/telemetry.md) when `pack/tenant.json` has `telemetry`
- [ ] Optional Guid MCP attach maps validated (docs/plugin-tools.md) when `agentSeed.sessionMcpAttachments` is set
- [ ] bun run doctor OK
- [ ] bun run materialize wrote .materialized/<id>.brand.json under resolved SDK
- [ ] Plugin sidecars prepared (resources/bundled-plugin-sidecars/<pluginId>/... under resolved SDK)
- [ ] bun run dist completed
- [ ] App boots with window title from brand (not Unknown distribution)
```

## Hard rules

1. Never tell customers to clone Geeksfino/findesk for day-to-day packaging.
2. Never package a private distribution id without a materialized brand file.
3. Leave `AIONCORE_PREFER_LOCAL` unset/`0` unless you are a FinDesk engineer with a local core build.
4. For public `finogeeks/findesk-std` pins, integrity match is enough — do not invent Geeksfino `GH_TOKEN` requirements.
5. Never invent production Sentry DSNs; for `self_hosted_sentry` / `dual` never recommend `*.sentry.io`. Customer supplies staging/production DSNs (see docs/telemetry.md).

## Failure playbook

| Error | Fix |
| ----- | --- |
| `Unknown distribution: "…"` | Rematerialize; rebuild with `bun run dist` (not a stale app) |
| Integrity mismatch | Re-download tarball; fix lock digest |
| Missing brand descriptor (builder throw) | `bun run materialize` then retry dist |
| Private HTTPS 401 | Set `FINDESK_ARTIFACT_TOKEN` |
| `aioncore binary not found` / Geeksfino curl 404 | Confirm `$FINDESK_PLATFORM/resources/bundled-aioncore/<plat-arch>/` exists with matching `manifest.json`; unset `FINDESK_PLATFORM` if it points at a monorepo; clear `~/.cache/findesk/platforms/<version>`. Do not tell customers to set Geeksfino `GH_TOKEN` for a normal findesk-std pin. |
| `finsafe binary not configured` / 沙箱不可用（缺少 FinSafe） / `spawn refused by finsafe` blocking `finclaw config set llm.provider` | **SDK gap (fixed in findesk-std ≥ 2.1.26):** older pins bake aioncore only. Confirm `$FINDESK_PLATFORM/resources/bundled-finsafe/<plat-arch>/finsafe` and `…/bundled-finclaw/<plat-arch>/finclaw` exist. **Dev:** `FINDESK_PLATFORM=<findesk monorepo>` after `bun run prepare:findesk` in that monorepo. **Pin-only workaround:** from the extracted SDK root, `FINSAFE_VERSION=<lock pin> node packages/desktop/scripts/findesk/prepareFinsafe.js` and the finclaw twin, then restart. **Proper:** bump `findesk.lock.json` to ≥ 2.1.26. |
| Doctor rejects telemetry DSN | `self_hosted_sentry` / `dual` used `*.sentry.io` — use customer-operated Sentry/Relay (docs/telemetry.md) |
| Packaged app, no Sentry events | Missing materialize/dist; `opt-in` without Settings → Privacy; empty/omitted `telemetry`; or SDK predates Proposal 0026 — see docs/telemetry.md |

## Dev vs pin (FinSAFE / FinClaw)

| Mode | Command | Notes |
| ---- | ------- | ----- |
| Day-to-day iteration | `FINDESK_PLATFORM=/path/to/findesk bun run start` | Run `bun run prepare:findesk` in the monorepo once (or after pin bumps). |
| Customer / lock smoke | `bun run start` (no override) | Needs findesk-std ≥ **2.1.26** for baked finsafe+finclaw when `finsafe: on`. |

## Paths

See [docs/local-paths.md](../../../docs/local-paths.md).
