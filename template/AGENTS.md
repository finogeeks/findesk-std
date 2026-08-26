# AGENTS.md — distribution repo

Guidance for AI assistants working in a **FinDesk white-label distribution repo**.

## Product model

This repo owns brand (`pack/`), optional private plugins (`plugins/`), and the
SDK pin (`findesk.lock.json`). Packaging uses the resolved **desktop SDK** —
not a sibling FinDesk monorepo.

## Skill router

| Task | Skill |
| ---- | ----- |
| Pin SDK, doctor, materialize, start, dist / installers | [`dist-packaging`](.claude/skills/dist-packaging/SKILL.md) |
| Add or change a private plugin under `plugins/` | [`dist-private-plugin`](.claude/skills/dist-private-plugin/SKILL.md) |

Upstream: treat [`finogeeks/findesk-std`](https://github.com/finogeeks/findesk-std) as the
SDK source of truth. Daily Actions workflow opens `upstream:findesk-std` issues when the
lock is behind — see [docs/upstream-sdk.md](docs/upstream-sdk.md). Do not monitor
Geeksfino/findesk-core from distribution repos.

Cursor resolves the same files via [`.cursor/skills`](.cursor/skills) (symlink).

## Rules

1. Prefer `bun run doctor|materialize|start|dist` from this repo root (scripts set `FINDESK_DIST_REPO`).
2. Always `materialize` before `dist` — brand must exist as `__FINDESK_BRAND__` or the packaged app fails with `Unknown distribution`.
3. Do not require `Geeksfino/findesk` or `findesk-core` checkouts for customer workflows.
4. Private plugins use `@findesk-private/*` + `findesk.pluginId` in `package.json`; enable ids in `pack/tenant.json`.
5. Read [docs/](docs/) before inventing new packaging steps.

## Human docs

Start at [README.md](README.md) → [docs/getting-started.md](docs/getting-started.md) →
[docs/hub-urls.md](docs/hub-urls.md) (optional hubs) →
[docs/telemetry.md](docs/telemetry.md) (optional Sentry / OTLP) →
[docs/plugin-tools.md](docs/plugin-tools.md) (plugin MCP / Guid attach).
