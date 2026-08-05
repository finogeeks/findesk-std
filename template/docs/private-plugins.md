# Private plugins

Customer-owned plugin **source** lives in this distribution repo under `plugins/`.
The tenant pack (`pack/tenant.json`) only lists **ids / pins** — it does not embed TypeScript.

## Layout

```text
plugins/<kebab-name>/
├── package.json          # @findesk-private/<name>, findesk.pluginId
├── src/
│   ├── index.ts          # activate*Plugin + registerSurfacePlugin
│   ├── ids.ts
│   └── <Name>Page.tsx
├── sidecars/             # optional: vendored sidecar tarballs (localArtifact)
└── backend/              # optional BFF (findesk.backend + backendExport)
    └── index.ts
```

## package.json contract

```json
{
  "name": "@findesk-private/example-demo",
  "private": true,
  "type": "module",
  "findesk": {
    "pluginId": "example.demo",
    "activateExport": "activateExampleDemoPlugin",
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

Optional BFF fields: `backend`, `backendExport`, `backendId`.

Optional supervised binaries: `findesk.sidecars[]` (see [Platform privileges](#platform-privileges-hostplugins)).

## Enable in the pack

In `pack/tenant.json`:

```json
"plugins": {
  "enable": ["example.demo"],
  "disableOptional": [],
  "private": ["example.demo"]
}
```

Then:

```bash
bun run materialize
bun run start
```

`FINDESK_DIST_REPO` (set by scripts) lets the SDK discover packages under `plugins/` and
generate private plugin loaders at materialize / Vite time.

## Activator pattern

```typescript
import type { FinDeskHost } from '@findesk/sdk';
import { registerSurfacePlugin } from '@findesk/sdk';
import { MY_PLUGIN_ID, MY_ROUTE } from './ids.js';
import MyPage from './MyPage.js';

export function activateMyPlugin(host: FinDeskHost): void {
  registerSurfacePlugin(host, {
    id: MY_PLUGIN_ID,
    nav: {
      labelKey: 'opc.nav.myPlugin',
      label: 'My plugin',
      icon: '◇',
      group: 'primary',
      order: 90,
      target: MY_ROUTE,
    },
    view: {
      route: MY_ROUTE,
      order: 90,
      lazy: MyPage,
    },
  });
}
```

## Platform privileges (`host.plugins`)

When the plugin needs local files, a supervised binary, or Guid/agent MCP — use
`host.plugins.*` (Proposal 0022). Do **not** add Electron IPC or ask for FinDesk-main patches.

**Requires** desktop SDK **≥ 2.1.27** (exposes `FinDeskHost.plugins`). Pin that SDK in
`findesk.lock.json` before shipping a privileged plugin.

| API | Use |
| --- | --- |
| `host.plugins.storage` | `userData/plugins/<pluginId>/…` |
| `host.plugins.files` | Pick / import / list / open / reveal / remove |
| `host.plugins.sidecars` | Ensure / status / stop / fetch (loopback HTTP to your own sidecar) |
| `host.plugins.mcp` | Upsert loopback Streamable HTTP MCP |

### Sidecar declaration (`findesk.sidecars[]`)

Declare supervised binaries on the plugin `package.json`. Example (casst / Knowledge Vault pattern):

```json
"sidecars": [{
  "id": "casst",
  "versionPin": "0.2.3",
  "download": {
    "repo": "finogeeks/code2wiki",
    "tag": "casst-v${version}",
    "asset": "casst-${version}-${triple}.tar.zst"
  },
  "localArtifact": "sidecars/casst.tar.zst",
  "bin": "bin/casst-ctl",
  "args": ["serve", "--data", "${dataRoot}", "--port", "${port}"],
  "healthPath": "/healthz",
  "mcpPath": "/mcp",
  "migrateFromUserDataDir": "code2wiki"
}]
```

The host substitutes `${moduleRoot}` / `${dataRoot}` / `${port}` / `${finclawHome}`,
prepends the module `bin/` plus the bundled finclaw directory to `PATH`, and injects
Hub/BYOK `FINCLAW_LLM_*`. Prefer a vendored `localArtifact` under the plugin when you
have the tarball; otherwise `download` pulls from GitHub Releases.

`bun run start` / `bun run dist` (with `FINDESK_DIST_REPO`) prepares each sidecar into
`resources/bundled-plugin-sidecars/<pluginId>/<sidecarId>/<platform-arch>/` and **fails
the build** if a declared sidecar cannot be prepared. Re-prepare when `versionPin`
changes or when `localArtifact` is newer than the prepare manifest.

Standard FinDesk ships **no** vault/sidecar modules — the distribution owns them end to
end. Use your own MCP name + pack `agentSeed` — do not depend on removed first-party
`host.findesk.knowledgeVault` / Secretary wiring.

Always scope calls with **your** `findesk.pluginId`. Cross-plugin paths fail closed.
Keep optional `backend/` for domain HTTP; it does not replace these privileges.

```typescript
import type { FinDeskHost } from '@findesk/sdk';
import { MY_PLUGIN_ID } from './ids.js';

export async function ensureMyRuntime(host: FinDeskHost): Promise<void> {
  await host.plugins.storage.ensureDir(MY_PLUGIN_ID, 'data');
  const status = await host.plugins.sidecars.ensure(MY_PLUGIN_ID, 'worker');
  if (!status.ready || !status.baseUrl) {
    throw new Error(status.lastError ?? 'sidecar not ready');
  }
  await host.plugins.mcp.upsertHttp({
    name: 'my-plugin-local',
    url: `${status.baseUrl.replace(/\/$/, '')}/mcp`,
    description: 'My plugin local MCP',
  });
}
```

After importing files into a knowledge-style sidecar, warm via loopback fetch:

```typescript
await host.plugins.sidecars.fetch(MY_PLUGIN_ID, 'casst', '/warm', { method: 'POST' });
```

## Rules

- Import **`@findesk/sdk` only** for host APIs — no Electron `ipcRenderer` in plugin UI.
- Privileged FS / process / MCP → `host.plugins.*`; product domains → `host.findesk.*` when the SDK exposes them.
- Prefer Arco + UnoCSS; put user-visible strings behind i18n keys when the host locale modules are available.
- Keep routes unique across plugins in this distribution.
- First-party shared plugins (`core.*`, etc.) stay in the SDK — enable them via ids only; do not vendor their source here.

## Agent skill

See [`.claude/skills/dist-private-plugin/SKILL.md`](../.claude/skills/dist-private-plugin/SKILL.md).
