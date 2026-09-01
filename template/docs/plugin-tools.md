# Plugin tools (MCP) for Guid and agents

[中文](./plugin-tools.zh-CN.md)

How **plugin authors** declare tools and how **distribution authors** attach them
to Guid / Copilot sessions. Requires a desktop SDK that exports `ctx.tools`
(`provide` / `provideEndpoint`). Pin that SDK in `findesk.lock.json` (see the
SDK CHANGELOG for the first release that includes this surface).

Related: [plugin-system.md](./plugin-system.md) (layers + runtime 2.0),
[plugin-developer-guide.md](./plugin-developer-guide.md) (author walkthrough),
[private-plugins.md](./private-plugins.md) (plugin layout),
[getting-started.md](./getting-started.md) (pin + doctor).

## Two jobs, one default: off

| Who | Job |
| --- | --- |
| Plugin | **Declare** tools on the plugin fiber (`ctx.tools.provide` or `provideEndpoint`). |
| Distro | **Attach** catalog MCP names to agents in `pack/tenant.json` `agentSeed`. |

Declaring a tool does **not** put it on Guid. The workstation must enable the
plugin id, and the SKU must list the catalog MCP name under
`agentSeed.sessionMcpAttachments`. Default is off so a plugin cannot surprise
the fleet.

`sessionMcpAttachments["*"]` attaches those MCP names to **every** Guid session
(fleet wildcard). Prefer named agent instance ids unless you really want that.

## Catalog MCP name vs plugin id

Guid attach maps use the **catalog MCP name**, not the dotted plugin id.

| Plugin id | Typical catalog name | How it is chosen |
| --- | --- | --- |
| `core.home` | `core-home` | Dots → hyphens (Shape B default) |
| `core.market-terminal` | `core-market` | Explicit `name` on `provideEndpoint` |
| Distro vault (example) | `fde-knowledge` | Explicit `name` — pick a stable string |

Override with `provideEndpoint({ name: '…' })`. Default is
`pluginId.replaceAll('.', '-')`.

Shape B (in-process `provide`) uses **one catalog name per plugin**. Shape A
sidecar/BFF keeps the name you pass (or that default).

## Plugin authors

Export a **2.0** `FinDeskPlugin` from `@findesk/sdk`. Register tools inside
`ctx.effect(() => ctx.tools.…)` so they withdraw when the plugin is disabled.

**Do not** call `host.plugins.mcp.upsertHttp` from a plugin. That API remains
for Guid/product seed; plugin MCP must go through `ctx.tools` so teardown is
tracked.

### Shape A — sidecar HTTP MCP

Supervised binary with `findesk.sidecars[]` and an MCP path. The sidecar owns
the JSON-RPC tool list; you still pass a metadata `tools[]` for doctor/ACL.

```typescript
ctx.effect(() =>
  ctx.tools.provideEndpoint({
    sidecarId: 'casst',
    name: 'acme-knowledge',
    tools: [
      { name: 'search_docs', description: 'Search the vault', intent: 'read' },
    ],
  })
);
```

Sidecar tools keep their **wire names** (the sidecar catalog). Doctor may show a
qualified audit id; Guid still calls the wire name.

If Guid should start the sidecar before attach, also set
`agentSeed.sessionMcpSidecarEnsure` (catalog name → `{ pluginId, sidecarId }`).

### Shape A′ — plugin BFF MCP

Host-node `/plugins/<backendId>/mcp` JSON-RPC (raw body). Default `backendId`
is the plugin id; override when the HTTP mount is shorter (e.g. market
`backendId: 'market'`).

```typescript
ctx.effect(() =>
  ctx.tools.provideEndpoint({
    backend: true,
    backendId: 'reports',
    name: 'acme-reports',
    tools: [
      { name: 'get_report', description: 'Fetch a report', intent: 'read' },
    ],
  })
);
```

The BFF must speak MCP JSON-RPC on that path. REST `/mcp/tools` + `/mcp/call`
are not the contract.

### Shape B — in-renderer tools

One stdio MCP server per plugin (`FINDESK_TOOL_PLUGIN_ID`). Implement
`execute` in the plugin. Use this for UI-owned state (home layout, etc.).

```typescript
ctx.effect(() =>
  ctx.tools.provide({
    name: 'list_widgets',
    description: 'List home widgets',
    intent: 'read',
    inputSchema: { type: 'object', additionalProperties: false },
    execute: async () => ({ widgets: [] }),
  })
);
```

On the MCP wire, the tool name is **qualified**:
non-alphanumeric characters in the plugin id become `_`, then
`<plugin>__<localName>` (example: `acme.reports` + `list_widgets` →
`acme_reports__list_widgets`). Use that string in `allowDestructiveTools` and
`sessionToolDeny`.

### Intent

| `intent` | Meaning |
| --- | --- |
| `read` | Safe for agents; listed and callable when attached. |
| `human` | Listed for humans; agents get **403** on `/call`. |
| `destructive` | Hidden unless the SKU allowlists the **qualified** name. |

Intents must not go backwards on a later `provide` of the same local name
(read → human → destructive only).

## Distribution authors

1. Enable the plugin in `pack/tenant.json` (`plugins.enable`, and `private` if
   it is a distro plugin).
2. Attach catalog names in `agentSeed.sessionMcpAttachments`.
3. Optionally deny tools or allow destructive names.
4. Pin an SDK that includes `ctx.tools`.
5. Run `bun run doctor` (and tenant-pack doctor when you pass `--tenant-pack`).

Example `pack/tenant.json` fragment:

```json
{
  "agentSeed": {
    "sessionMcpAttachments": {
      "secretary": ["acme-knowledge", "core-home"],
      "*": ["core-market"]
    },
    "sessionMcpSidecarEnsure": {
      "acme-knowledge": { "pluginId": "acme.reports", "sidecarId": "casst" }
    },
    "sessionToolDeny": {
      "secretary": ["core_home__reset_guid_layout"]
    },
    "allowDestructiveTools": []
  }
}
```

First-party catalog names in current SDKs that ship this surface:

| Catalog name | Plugin | Notes |
| --- | --- | --- |
| `core-home` | `core.home` | Shape B: `surface_info` (read), `reset_guid_layout` (human) |
| `core-market` | `core.market-terminal` | Shape A′ JSON-RPC; attach only if you want market tools on Guid |

Workstation policy can still skip a plugin whose MCP you attached: Guid send
does not attach MCP for plugins disabled in the product wiring.

## Doctor

`bun run doctor` prints a **capability** table of declared plugin tools (it does
not execute them). Use it to confirm catalog names, intents, and qualified
ids before attaching agents.

```bash
bun run doctor
# with an explicit pack: findesk doctor --tenant-pack pack
```

Mismatches against the SDK golden are for **first-party** plugins. Distro
plugins are extra rows — audit them in the table, then attach by catalog name.

## Checklist

- [ ] Plugin uses `ctx.tools`, not `upsertHttp`
- [ ] Catalog name is stable and documented for this SKU
- [ ] `plugins.enable` includes the plugin id
- [ ] `sessionMcpAttachments` lists that catalog name for the right agents
- [ ] Sidecar Shape A: `sessionMcpSidecarEnsure` if Guid must start the binary
- [ ] Destructive tools listed in `allowDestructiveTools` (qualified names)
- [ ] SDK pin includes `ctx.tools`; `bun run doctor` looks right
