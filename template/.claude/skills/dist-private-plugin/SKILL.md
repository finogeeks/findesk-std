---
name: dist-private-plugin
description: |
  Author or change a private FinDesk plugin under plugins/ in a white-label
  distribution repo. Use when scaffolding @findesk-private packages, wiring
  findesk.pluginId / activateExport, enabling ids in pack/tenant.json, adding
  an optional plugin BFF, or using host.plugins storage/files/sidecars and
  ctx.tools.provide / provideEndpoint for MCP (plugin tool surface).
  Distro attach maps live in pack/tenant.json agentSeed — see docs/plugin-tools.md.
---

# Private plugin (distribution repo)

Read [docs/plugin-system.md](../../../docs/plugin-system.md),
[docs/plugin-developer-guide.md](../../../docs/plugin-developer-guide.md),
[docs/private-plugins.md](../../../docs/private-plugins.md), and
[docs/plugin-tools.md](../../../docs/plugin-tools.md) first.
Packaging skill: [`dist-packaging`](../dist-packaging/SKILL.md).

## Mental model

```text
plugins/<name>/     →  TypeScript source (@findesk-private/*)
pack/tenant.json    →  plugins.enable + plugins.private (ids only)
materialize/start   →  SDK discovers FINDESK_DIST_REPO/plugins
host.plugins.*      →  scoped storage / files / sidecars (no FinDesk PR)
ctx.tools.provide / provideEndpoint → declare Guid/agent MCP (distro must attach)
```

Do **not** put plugin source under `pack/`.

## Workflow

```
- [ ] 1. Choose plugin id (e.g. acme.reports) + folder plugins/<kebab>/
- [ ] 2. Scaffold package.json with findesk.pluginId + activateExport
- [ ] 3. Implement activate*Plugin via registerSurfacePlugin from @findesk/sdk
- [ ] 4. If privileged local IO needed: use host.plugins.* (see below) — never ipcRenderer
- [ ] 5. If supervised binary needed: declare findesk.sidecars[] (+ optional localArtifact)
- [ ] 6. Add id to pack/tenant.json plugins.enable (+ private[])
- [ ] 7. If Guid should see tools: agentSeed.sessionMcpAttachments (catalog MCP name, not plugin id)
- [ ] 8. bun run materialize && bun run start (prepare fails closed if sidecar missing)
- [ ] 9. Confirm nav/route; then bun run dist if shipping
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

## Platform privileges (`host.plugins`)

Use when the plugin needs:

| Need | API |
| ---- | --- |
| Plugin-owned dirs under userData | `host.plugins.storage` |
| Pick / import / list / open / reveal / remove files | `host.plugins.files` |
| Supervised local binary | `host.plugins.sidecars` |
| Guid/agent Streamable HTTP MCP (sidecar or BFF) | `ctx.tools.provideEndpoint` |
| In-process tools (Shape B) | `ctx.tools.provide` |

**Hard rules**

- Pass **this plugin’s** `pluginId` on every call; cross-plugin paths fail closed.
- Do **not** use Electron `ipcRenderer` or request new FinDesk-main IPC for these cases.
- Optional BFF is for domain HTTP — it does not replace storage/sidecar/mcp privileges.
- Pin a desktop SDK that exports `FinDeskHost.plugins` (**≥ 2.1.27**) and `ctx.tools` (plugin tool surface) before shipping privileged / MCP plugins.

```typescript
ctx.effect(() =>
  ctx.tools.provideEndpoint({
    sidecarId: 'worker',
    name: 'acme-reports',
    tools: [{ name: 'list_reports', description: 'List reports', intent: 'read' }],
  })
);
```

Raw `host.plugins.mcp.upsertHttp` still exists for Guid/product-seed; **plugins should not call it**.
Attach catalog names in `pack/tenant.json` `agentSeed` — declare ≠ Guid attach. See [docs/plugin-tools.md](../../../docs/plugin-tools.md).

### Sidecar prepare (`findesk.sidecars[]`)

Declare binaries on `package.json` with `versionPin`, `bin`/`args`, `healthPath`, and either
`localArtifact` (vendored under `plugins/<name>/sidecars/`) or `download` (GitHub release).
Host substitutes `${dataRoot}` / `${port}` / `${moduleRoot}` / `${finclawHome}` and injects
`FINCLAW_LLM_*`. `start` / `dist` write
`resources/bundled-plugin-sidecars/<pluginId>/<sidecarId>/<platform-arch>/` and fail if
prepare cannot complete.

Full examples: [docs/private-plugins.md](../../../docs/private-plugins.md) § Platform privileges.

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

Guid attach is a second opt-in (catalog MCP name, not plugin id):

```json
"agentSeed": {
  "sessionMcpAttachments": {
    "secretary": ["acme-reports"]
  }
}
```

## Out of scope here

- First-party plugins inside the desktop SDK (`packages/plugins` in FinDesk).
- Shell chrome (sidebar layout) — enable a shell baseline in the distribution JSON; do not reinvent chrome inside a surface plugin unless that is the product intent.
- Baking finclaw/finsafe into the SDK — those pins live in FinDesk `package.json` and ship inside the desktop SDK tarball; distros only pin the SDK.
