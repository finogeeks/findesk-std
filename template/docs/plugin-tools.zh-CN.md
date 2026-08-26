# 插件工具（MCP）— Guid 与智能体

[English](./plugin-tools.md)

说明 **插件作者** 如何声明工具，以及 **分发作者** 如何把工具挂到 Guid / Copilot
会话。需要桌面 SDK 导出 `ctx.tools`（`provide` / `provideEndpoint`）。在
`findesk.lock.json` 中固定该 SDK（以 SDK CHANGELOG 中首次包含该表面的版本为准）。

相关：[private-plugins.zh-CN.md](./private-plugins.zh-CN.md)（插件布局）、
[getting-started.zh-CN.md](./getting-started.zh-CN.md)（固定版本与 doctor）。

## 两件事，默认关闭

| 角色 | 职责 |
| --- | --- |
| 插件 | 在插件 fiber 上 **声明** 工具（`ctx.tools.provide` 或 `provideEndpoint`）。 |
| 分发 | 在 `pack/tenant.json` 的 `agentSeed` 里把目录 MCP **名** 挂到智能体。 |

声明工具 **不会** 自动出现在 Guid。工作站必须启用插件 id，SKU 还必须在
`agentSeed.sessionMcpAttachments` 中列出目录 MCP 名。默认关闭，避免插件
悄悄进入整队智能体。

`sessionMcpAttachments["*"]` 会把这些 MCP 挂到 **每一个** Guid 会话（舰队通配）。
除非确实需要，否则优先用具体的 agent instance id。

## 目录 MCP 名 vs 插件 id

Guid 挂载表用的是 **目录 MCP 名**，不是带点的插件 id。

| 插件 id | 常见目录名 | 如何得到 |
| --- | --- | --- |
| `core.home` | `core-home` | 点号换成连字符（Shape B 默认） |
| `core.market-terminal` | `core-market` | `provideEndpoint` 上显式 `name` |
| 分发 vault（示例） | `fde-knowledge` | 显式 `name` — 选一个稳定字符串 |

用 `provideEndpoint({ name: '…' })` 覆盖。默认是
`pluginId.replaceAll('.', '-')`。

Shape B（进程内 `provide`）是 **每个插件一个目录名**。Shape A sidecar/BFF
使用你传入的名字（或上述默认值）。

## 插件作者

从 `@findesk/sdk` 导出 **2.0** `FinDeskPlugin`。在
`ctx.effect(() => ctx.tools.…)` 内注册，以便插件禁用时一并撤销。

**不要** 在插件里调用 `host.plugins.mcp.upsertHttp`。该 API 仍留给 Guid/产品种子；
插件 MCP 必须走 `ctx.tools`，才能被 fiber 跟踪撤销。

### Shape A — sidecar HTTP MCP

受管二进制 + `findesk.sidecars[]` + MCP 路径。sidecar 拥有 JSON-RPC 工具列表；
你仍需传入元数据 `tools[]`，供 doctor / ACL 使用。

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

Sidecar 工具保留 **线名**（sidecar 自己的目录）。Doctor 可能显示带资格的审计 id；
Guid 调用仍用线名。

若 Guid 挂载前需要先拉起 sidecar，再配置
`agentSeed.sessionMcpSidecarEnsure`（目录名 → `{ pluginId, sidecarId }`）。

### Shape A′ — 插件 BFF MCP

宿主节点 `/plugins/<backendId>/mcp` JSON-RPC（原始 body）。默认 `backendId`
是插件 id；HTTP 挂载更短时请覆盖（例如行情 `backendId: 'market'`）。

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

BFF 必须在该路径上讲 MCP JSON-RPC。REST `/mcp/tools` + `/mcp/call` 不是本契约。

### Shape B — 渲染进程内工具

每个插件一个 stdio MCP 服务（`FINDESK_TOOL_PLUGIN_ID`）。在插件里实现
`execute`。适合 UI 自有状态（首页布局等）。

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

MCP 线上的工具名是 **资格名**：插件 id 中非字母数字变成 `_`，再拼
`<plugin>__<localName>`（例如 `acme.reports` + `list_widgets` →
`acme_reports__list_widgets`）。`allowDestructiveTools` 与 `sessionToolDeny`
都用这个字符串。

### Intent

| `intent` | 含义 |
| --- | --- |
| `read` | 对智能体安全；挂载后可列出并调用。 |
| `human` | 对人类列出；智能体 `/call` 得到 **403**。 |
| `destructive` | 默认隐藏，除非 SKU 把 **资格名** 加入允许列表。 |

同一本地名后续 `provide` 的 intent 不得回退（只能 read → human → destructive）。

## 分发作者

1. 在 `pack/tenant.json` 启用插件（`plugins.enable`；分发插件再加 `private`）。
2. 在 `agentSeed.sessionMcpAttachments` 挂上目录名。
3. 按需拒绝工具或允许破坏性名字。
4. 固定包含 `ctx.tools` 的 SDK。
5. 运行 `bun run doctor`（传入 `--tenant-pack` 时会审 pack）。

`pack/tenant.json` 片段示例：

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

当前带该表面的 SDK 中的一等目录名：

| 目录名 | 插件 | 说明 |
| --- | --- | --- |
| `core-home` | `core.home` | Shape B：`surface_info`（read）、`reset_guid_layout`（human） |
| `core-market` | `core.market-terminal` | Shape A′ JSON-RPC；只有你希望 Guid 用行情工具时才挂载 |

工作站策略仍可跳过你已挂载但产品接线禁用的插件：Guid 发送不会给禁用插件挂 MCP。

## Doctor

`bun run doctor` 打印已声明插件工具的 **能力** 表（不执行工具）。用它在挂载智能体前
核对目录名、intent 和资格 id。

```bash
bun run doctor
# 显式 pack：findesk doctor --tenant-pack pack
```

与 SDK golden 的比对针对 **一等** 插件。分发插件是额外行 — 在表里审完后，用目录名挂载。

## 检查清单

- [ ] 插件走 `ctx.tools`，不走 `upsertHttp`
- [ ] 本 SKU 的目录名稳定且有文档
- [ ] `plugins.enable` 包含该插件 id
- [ ] `sessionMcpAttachments` 把该目录名挂到正确的智能体
- [ ] Sidecar Shape A：Guid 需要拉起二进制时配置 `sessionMcpSidecarEnsure`
- [ ] 破坏性工具写在 `allowDestructiveTools`（资格名）
- [ ] SDK 固定版本含 `ctx.tools`；`bun run doctor` 看起来正确
