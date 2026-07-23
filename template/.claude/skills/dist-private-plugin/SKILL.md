---
name: dist-private-plugin
description: |
  Author or change a private FinDesk plugin under plugins/ in a white-label
  distribution repo. Use when scaffolding @findesk-private packages, wiring
  findesk.pluginId / activateExport, enabling ids in pack/tenant.json, or adding
  an optional plugin BFF.
---

# Private plugin (distribution repo)

Read [docs/private-plugins.md](../../../docs/private-plugins.md) first.
Packaging skill: [`dist-packaging`](../dist-packaging/SKILL.md).

## Mental model

```text
plugins/<name>/     →  TypeScript source (@findesk-private/*)
pack/tenant.json    →  plugins.enable + plugins.private (ids only)
materialize/start   →  SDK discovers FINDESK_DIST_REPO/plugins
```

Do **not** put plugin source under `pack/`.

## Workflow

```
- [ ] 1. Choose plugin id (e.g. acme.reports) + folder plugins/<kebab>/
- [ ] 2. Scaffold package.json with findesk.pluginId + activateExport
- [ ] 3. Implement activate*Plugin via registerSurfacePlugin from @findesk/sdk
- [ ] 4. Add id to pack/tenant.json plugins.enable (+ private[])
- [ ] 5. bun run materialize && bun run start
- [ ] 6. Confirm nav/route; then bun run dist if shipping
```

## Naming

| Item | Convention | Example |
| ---- | ---------- | ------- |
| Package | `@findesk-private/<kebab>` | `@findesk-private/acme-reports` |
| Plugin id | `<tenant>.<kebab>` | `acme.reports` |
| Folder | `plugins/<kebab>/` | `plugins/acme-reports/` |
| Activator | `activate<Pascal>Plugin` | `activateAcmeReportsPlugin` |

## package.json (minimum)

```json
{
  "name": "@findesk-private/acme-reports",
  "private": true,
  "type": "module",
  "findesk": {
    "pluginId": "acme.reports",
    "activateExport": "activateAcmeReportsPlugin",
    "frontend": "src/index.ts"
  },
  "exports": { ".": "./src/index.ts" },
  "peerDependencies": {
    "@findesk/sdk": "*",
    "@arco-design/web-react": "^2.0.0",
    "react": "^18.0.0 || ^19.0.0"
  }
}
```

Optional BFF: `backend`, `backendExport`, `backendId`, export `./backend`.

## UI rules

- Host API via `@findesk/sdk` only.
- Interactive controls: Arco Design; avoid raw HTML form controls.
- Unique `route` across plugins in this distribution.
- Fixtures first; add `backend/` only when the UI needs a local HTTP surface.

## Enable

```json
"plugins": {
  "enable": ["acme.reports"],
  "private": ["acme.reports"]
}
```

## Out of scope here

- First-party plugins inside the desktop SDK (`packages/plugins` in FinDesk).
- Shell chrome (sidebar layout) — enable a shell baseline in the distribution JSON; do not reinvent chrome inside a surface plugin unless that is the product intent.
