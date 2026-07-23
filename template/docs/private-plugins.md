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

## Rules

- Import **`@findesk/sdk` only** for host APIs — no Electron `ipcRenderer` in plugin UI.
- Prefer Arco + UnoCSS; put user-visible strings behind i18n keys when the host locale modules are available.
- Keep routes unique across plugins in this distribution.
- First-party shared plugins (`core.*`, etc.) stay in the SDK — enable them via ids only; do not vendor their source here.

## Agent skill

See [`.claude/skills/dist-private-plugin/SKILL.md`](../.claude/skills/dist-private-plugin/SKILL.md).
