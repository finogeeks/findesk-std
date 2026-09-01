# Plugin developer guide

[中文](./plugin-developer-guide.zh-CN.md)

Step-by-step guide for a **private** plugin in this distribution repo. Overview:
[plugin-system.md](./plugin-system.md). Package fields:
[private-plugins.md](./private-plugins.md). MCP contract:
[plugin-tools.md](./plugin-tools.md).

Pin a desktop SDK that exports `FinDeskHost.plugins` (**≥ 2.1.27**) and
`ctx.tools` (plugin tool surface). Then:

```bash
bun run materialize
bun run start
```

## 1. Choose a shape

| You are building | Shape |
| --- | --- |
| One screen (list, form, dashboard) | UI only — `registerSurfacePlugin` |
| UI + local HTTP | UI + BFF (`backend/`) |
| UI + supervised binary | UI + `findesk.sidecars[]` |
| Agents must call into the plugin | MCP via `ctx.tools` (A / A′ / B) + pack attach |

Chrome (sidebar layout) belongs to the **shell**, not a surface plugin. Split
one plugin per nav item / bounded context.

## 2. Name and scaffold

| Item | Convention | Example |
| --- | --- | --- |
| Folder | `plugins/<kebab>/` | `plugins/acme-reports/` |
| Package | `@findesk-private/<kebab>` | `@findesk-private/acme-reports` |
| Plugin id | `<tenant>.<kebab>` | `acme.reports` |
| Route | Unique in this SKU | `/acme/reports` |

Minimum tree:

```text
plugins/acme-reports/
├── package.json
├── src/
│   ├── index.ts      # FinDeskPlugin export (or 1.0 activator)
│   ├── ids.ts
│   └── ReportsPage.tsx
├── backend/          # optional BFF
└── sidecars/         # optional localArtifact override (often gitignored)
```

`package.json` (minimum):

```json
{
  "name": "@findesk-private/acme-reports",
  "private": true,
  "type": "module",
  "findesk": {
    "pluginId": "acme.reports",
    "activateExport": "acmeReportsPlugin",
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

Set `activateExport` to the **single** export the loader should call.

## 3. UI

- Host APIs via **`@findesk/sdk` only** — no `ipcRenderer`, no `window.electronAPI`.
- Interactive controls: **Arco Design**. Avoid raw `<button>` / `<input>`.
- Icons: `@icon-park/react` when the SDK surface uses it.
- Colors: semantic tokens / CSS variables — no hardcoded hex.
- User-visible strings: i18n keys when locale modules are available; otherwise
  a `label` fallback is acceptable on private plugins.
- Unique `route` across plugins in this distribution.
- Fixtures first; add `backend/` only when the UI needs loopback HTTP.

## 4. Export a 2.0 plugin (recommended)

Prefer `FinDeskPlugin` whenever you touch storage, sidecars, or MCP so disable
tears them down.

```typescript
import type { FinDeskPlugin } from '@findesk/sdk';
import { registerSurfacePlugin } from '@findesk/sdk';
import { MY_PLUGIN_ID, MY_ROUTE } from './ids.js';
import ReportsPage from './ReportsPage.js';

export const acmeReportsPlugin: FinDeskPlugin = {
  name: MY_PLUGIN_ID,
  apply(ctx) {
    ctx.effect(() =>
      registerSurfacePlugin(ctx.host, {
        id: MY_PLUGIN_ID,
        nav: {
          labelKey: 'opc.nav.acmeReports',
          label: 'Reports',
          icon: '◇',
          group: 'primary',
          order: 90,
          target: MY_ROUTE,
        },
        view: { route: MY_ROUTE, order: 90, lazy: ReportsPage },
      })
    );
  },
};
```

UI-only 1.0 activators (`export function activateX(host) { … }`) still work.
Do not export both a 2.0 object and a 1.0 function as `activateExport`.

Privileged IO (always pass **this** `pluginId`):

```typescript
await ctx.host.plugins.storage.ensureDir(MY_PLUGIN_ID, 'data');
const paths = await ctx.host.plugins.files.pickOpen({
  multiSelections: true,
  filters: [{ name: 'Documents', extensions: ['pdf', 'md'] }],
});
```

## 5. Enable in the pack

```json
"plugins": {
  "enable": ["acme.reports"],
  "disableOptional": [],
  "private": ["acme.reports"]
}
```

Then `bun run materialize && bun run start`. Confirm the nav item and route.

## 6. Optional BFF

When the UI needs local HTTP:

- Add `backend/index.ts` and `findesk.backend` / `backendExport` /
  `backendId` on `package.json` (and `exports["./backend"]`).
- Keep protocol types in the plugin package.
- Domain REST is not a substitute for `host.plugins.storage` / sidecars / MCP.

If Guid should call the BFF as MCP, the BFF must speak **MCP JSON-RPC** on
`/plugins/<backendId>/mcp` (raw body). REST `/mcp/tools` + `/mcp/call` is
not the contract. Then `provideEndpoint({ backend: true, backendId, name, tools })`.

## 7. Optional sidecar

Declare `findesk.sidecars[]` with `versionPin`, `bin` / `args`, `healthPath`,
and either `download` (GitHub release) or `localArtifact`. The host substitutes
`${moduleRoot}` / `${dataRoot}` / `${port}` / `${finclawHome}` and injects
`FINCLAW_LLM_*`.

`bun run start` / `bun run dist` prepare binaries into
`resources/bundled-plugin-sidecars/<pluginId>/<sidecarId>/<platform-arch>/`
and **fail** if prepare cannot complete.

A sidecar may exec only binaries inside its own `moduleRoot` (plus the
host-provided finclaw dir) — no `PATH` lookups, no `/usr/bin/…`.

## 8. MCP for Guid and agents

**Declare** inside `ctx.effect`. **Attach** in the pack. Default is off.

```typescript
ctx.effect(() =>
  ctx.tools.provideEndpoint({
    sidecarId: 'worker',
    name: 'acme-reports',
    tools: [{ name: 'list_reports', description: 'List reports', intent: 'read' }],
  })
);
```

In-process (Shape B): `ctx.tools.provide({ name, description, intent, inputSchema, execute })`.
On the wire the name is qualified (`acme_reports__list_widgets`).

`intent`: `read` (agents may call) · `human` (agents get 403) · `destructive`
(hidden unless `allowDestructiveTools` lists the **qualified** name).

Pack attach (catalog MCP **name**, not `acme.reports`):

```json
"agentSeed": {
  "sessionMcpAttachments": {
    "secretary": ["acme-reports"]
  },
  "sessionMcpSidecarEnsure": {
    "acme-reports": { "pluginId": "acme.reports", "sidecarId": "worker" }
  }
}
```

Guid is the local home chat (`/guid`). Attaching here is how agents in that
composer see the tools. Full tables: [plugin-tools.md](./plugin-tools.md).

## 9. Doctor and ship

```bash
bun run doctor
bun run materialize
bun run start
bun run dist -- --mac --arm64 --pack-only
```

Doctor prints a **capability** table of declared tools (it does not execute
them). Distro plugins are extra rows — audit them, then attach by catalog name.

## Checklist

- [ ] Unique plugin id and route
- [ ] `@findesk/sdk` only for host APIs
- [ ] 2.0 export if storage / sidecar / MCP
- [ ] `plugins.enable` + `plugins.private`
- [ ] MCP via `ctx.tools`, not `upsertHttp`
- [ ] Catalog name documented; `sessionMcpAttachments` if Guid should see it
- [ ] Sidecar Shape A: `sessionMcpSidecarEnsure` if Guid must start the binary
- [ ] `bun run doctor` looks right

## Anti-patterns

- Putting TypeScript under `pack/`
- Rebuilding shell chrome inside a surface plugin
- Vendoring first-party `core.*` source
- Calling `host.plugins.mcp.upsertHttp` from the plugin
- Assuming declare ⇒ Guid attach
- New Electron IPC for files / process / MCP
