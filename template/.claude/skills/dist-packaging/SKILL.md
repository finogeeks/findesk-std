---
name: dist-packaging
description: |
  Doctor, materialize, start, and package a FinDesk white-label distribution from
  this distribution repo (no FinDesk monorepo required). Use when pinning the
  desktop SDK, building installers, fixing Unknown distribution, or explaining
  where cache/app/user-data live.
---

# Distribution packaging

Read [docs/getting-started.md](../../../docs/getting-started.md) and
[docs/packaging.md](../../../docs/packaging.md) first.

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

Scripts set `FINDESK_DIST_REPO` and `FINDESK_WHITE_LABEL=1`. `dist.sh` **materializes
before** packaging — do not skip that.

## Checklist

```
- [ ] Lock pin valid (artifact exists or HTTPS URL reachable)
- [ ] pack/tenant.json brand + configHome set
- [ ] bun run doctor OK
- [ ] bun run materialize wrote .materialized/<id>.brand.json under resolved SDK
- [ ] bun run dist completed
- [ ] App boots with window title from brand (not Unknown distribution)
```

## Hard rules

1. Never tell customers to clone Geeksfino/findesk for day-to-day packaging.
2. Never package a private distribution id without a materialized brand file.
3. Leave `AIONCORE_PREFER_LOCAL` unset/`0` unless you are a FinDesk engineer with a local core build.
4. For public `finogeeks/findesk-std` pins, integrity match is enough — do not invent Geeksfino `GH_TOKEN` requirements.

## Failure playbook

| Error | Fix |
| ----- | --- |
| `Unknown distribution: "…"` | Rematerialize; rebuild with `bun run dist` (not a stale app) |
| Integrity mismatch | Re-download tarball; fix lock digest |
| Missing brand descriptor (builder throw) | `bun run materialize` then retry dist |
| Private HTTPS 401 | Set `FINDESK_ARTIFACT_TOKEN` |

## Paths

See [docs/local-paths.md](../../../docs/local-paths.md).
