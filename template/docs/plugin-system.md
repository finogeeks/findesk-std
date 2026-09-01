# Plugin system (overview)

[中文](./plugin-system.zh-CN.md)

How FinDesk plugins fit together. For a step-by-step authoring walkthrough, see
[plugin-developer-guide.md](./plugin-developer-guide.md). MCP declare vs attach:
[plugin-tools.md](./plugin-tools.md). Package contract:
[private-plugins.md](./private-plugins.md).

You do **not** need the private FinDesk monorepo. Pin a desktop SDK that
exports `@findesk/sdk` (`FinDeskPlugin`, `ctx.effect`, `ctx.tools`).

## Layers

A shipped product (this distribution) is a **shell** plus a set of **plugins**
on a **host**. Plugins never import Electron or the desktop renderer.

```text
L1  Host     @findesk/sdk  — registries, host.plugins.*, ctx.tools
L2  Shell    chrome        — sidebar, topbar, layout (you enable a baseline; do not rebuild it)
L3  Plugin   this repo     — nav + view + optional BFF / sidecar / MCP tools
```

- **Shell** lays out chrome and reads `host.registries.*`.
- **Plugin** contributes a routable surface (and optional backend). One plugin
  ≈ one nav item / bounded context.
- **Pack** (`pack/tenant.json`) turns plugin **ids** on. It does not embed
  TypeScript.

**Guid** is the local home chat (route `/guid`). Users see it as Home /
Digital staff — not the word “Guid”. “Attach to Guid” means: make MCP tools
available on agent sessions started from that home composer.

## First-party vs private

| Kind | Where the source lives | How you use it |
| --- | --- | --- |
| First-party (`core.*`, …) | Inside the desktop SDK | Enable by **id** in the pack. Do not vendor the source. |
| Private (`@findesk-private/*`) | This repo, `plugins/<kebab>/` | You own the source. List the id in `plugins.enable` and `plugins.private`. |

Both kinds share the same SDK APIs. The loader discovers private packages when
scripts set `FINDESK_DIST_REPO`.

## Plugin runtime 2.0

The runtime is **Cordis-shaped** (revertible effects + `inject` / `provide`
names). The renderer does **not** depend on the `cordis` package.

| Idea | What it means for you |
| --- | --- |
| **1.0 activator** | `function activateX(host) { registerSurfacePlugin(host, …) }`. Still valid for UI-only plugins. |
| **2.0 `FinDeskPlugin`** | `{ name, apply(ctx) { … } }`. Required for tracked teardown (sidecar, MCP, storage). |
| **`ctx.effect`** | Register work that must **undo** when the plugin is disabled. Inverses run LIFO. |
| **Single export** | `findesk.activateExport` is **either** the 2.0 object **or** the 1.0 function — not both. |

Move timers, sidecar ensure, and MCP registration into `ctx.effect`. Bare
`void ensureRuntime(host)` in an activator has no inverse.

```typescript
import type { FinDeskPlugin } from '@findesk/sdk';
import { registerSurfacePlugin } from '@findesk/sdk';

export const myPlugin: FinDeskPlugin = {
  name: 'acme.reports',
  apply(ctx) {
    ctx.effect(() =>
      registerSurfacePlugin(ctx.host, {
        id: 'acme.reports',
        nav: { label: 'Reports', icon: '◇', group: 'primary', order: 90, target: '/acme/reports' },
        view: { route: '/acme/reports', order: 90, lazy: ReportsPage },
      })
    );
  },
};
```

## What a plugin may contribute

| Contribution | How |
| --- | --- |
| Nav + view (UI) | `registerSurfacePlugin` / `host.registries` |
| Copilot context | `copilotContext` on the surface registration |
| Loopback HTTP (BFF) | `findesk.backend` + `backend/` module |
| Supervised binary | `findesk.sidecars[]` + `host.plugins.sidecars` |
| Agent tools (MCP) | `ctx.tools.provide` or `provideEndpoint` — then distro **attach** |

Privileged local IO uses `host.plugins.{storage,files,sidecars}` — never
`ipcRenderer`. Product domain APIs (when the SDK exposes them) stay on
`host.findesk.*`.

## MCP is a contribution, not a mirror

Declaring tools does **not** put them on Guid. A plugin that auto-exposed every
API as MCP would be an authority bug.

1. **Plugin** declares tools on the fiber (`ctx.tools`).
2. **Distro** attaches **catalog MCP names** in
   `pack/tenant.json` `agentSeed.sessionMcpAttachments`.
3. Default is **off**. Catalog name ≠ dotted plugin id (often dots → hyphens).

Do **not** call `host.plugins.mcp.upsertHttp` from a plugin. That API remains
for product seed; plugin MCP must go through `ctx.tools` so disable withdraws
the catalog entry.

Shapes (detail in [plugin-tools.md](./plugin-tools.md)):

| Shape | When |
| --- | --- |
| **A** sidecar HTTP | Supervised binary already speaks MCP |
| **A′** BFF JSON-RPC | Host-node `/plugins/<backendId>/mcp` |
| **B** in-process | UI-owned state; `execute` in the plugin |

## Read next

1. [plugin-developer-guide.md](./plugin-developer-guide.md) — scaffold → UI → BFF → sidecar → MCP → doctor
2. [private-plugins.md](./private-plugins.md) — `package.json` and enable fields
3. [plugin-tools.md](./plugin-tools.md) — intents, catalog names, `agentSeed`
4. Skill [`.claude/skills/dist-private-plugin/SKILL.md`](../.claude/skills/dist-private-plugin/SKILL.md)
