# 插件开发指南

[English](./plugin-developer-guide.md)

在本分发仓库编写 **私有** 插件的逐步指南。总览：
[plugin-system.zh-CN.md](./plugin-system.zh-CN.md)。包字段：
[private-plugins.zh-CN.md](./private-plugins.zh-CN.md)。MCP 契约：
[plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。

固定一份导出 `FinDeskHost.plugins`（**≥ 2.1.27**）和 `ctx.tools`（插件工具表面）
的桌面 SDK。然后：

```bash
bun run materialize
bun run start
```

## 1. 选择形态

| 你在做 | 形态 |
| --- | --- |
| 一个屏幕（列表、表单、看板） | 仅 UI — `registerSurfacePlugin` |
| UI + 本地 HTTP | UI + BFF（`backend/`） |
| UI + 受管二进制 | UI + `findesk.sidecars[]` |
| 智能体需要调用插件 | 通过 `ctx.tools` 的 MCP（A / A′ / B）+ pack 挂载 |

Chrome（侧栏布局）属于 **壳**，不是表面插件。按导航项 / 有界上下文拆成一个插件。

## 2. 命名与脚手架

| 项 | 约定 | 示例 |
| --- | --- | --- |
| 文件夹 | `plugins/<kebab>/` | `plugins/acme-reports/` |
| 包名 | `@findesk-private/<kebab>` | `@findesk-private/acme-reports` |
| 插件 id | `<tenant>.<kebab>` | `acme.reports` |
| 路由 | 本 SKU 内唯一 | `/acme/reports` |

最小目录树：

```text
plugins/acme-reports/
├── package.json
├── src/
│   ├── index.ts      # FinDeskPlugin 导出（或 1.0 activator）
│   ├── ids.ts
│   └── ReportsPage.tsx
├── backend/          # 可选 BFF
└── sidecars/         # 可选 localArtifact 覆盖（通常 gitignore）
```

`package.json`（最小）：

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

把 `activateExport` 设为加载器应调用的 **唯一** 导出。

## 3. UI

- 宿主 API 只走 **`@findesk/sdk`** — 不要 `ipcRenderer`，不要 `window.electronAPI`。
- 交互控件用 **Arco Design**。避免裸 `<button>` / `<input>`。
- 图标：SDK 表面使用时用 `@icon-park/react`。
- 颜色：语义 token / CSS 变量 — 不要写死 hex。
- 用户可见文案：有 locale 模块时用 i18n key；私有插件也可以用 `label` 兜底。
- 本分发内各插件的 `route` 必须唯一。
- 先用 fixture；只有 UI 需要回环 HTTP 时再加 `backend/`。

## 4. 导出 2.0 插件（推荐）

只要会碰到 storage、sidecar 或 MCP，就用 `FinDeskPlugin`，这样禁用时能一并拆除。

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

仅 UI 的 1.0 activator（`export function activateX(host) { … }`）仍然可用。
不要把 2.0 对象和 1.0 函数同时作为 `activateExport`。

特权 IO（始终传入 **本插件** 的 `pluginId`）：

```typescript
await ctx.host.plugins.storage.ensureDir(MY_PLUGIN_ID, 'data');
const paths = await ctx.host.plugins.files.pickOpen({
  multiSelections: true,
  filters: [{ name: 'Documents', extensions: ['pdf', 'md'] }],
});
```

## 5. 在 pack 里启用

```json
"plugins": {
  "enable": ["acme.reports"],
  "disableOptional": [],
  "private": ["acme.reports"]
}
```

然后 `bun run materialize && bun run start`。确认导航项和路由出现。

## 6. 可选 BFF

当 UI 需要本地 HTTP 时：

- 添加 `backend/index.ts`，并在 `package.json` 上写 `findesk.backend` /
  `backendExport` / `backendId`（以及 `exports["./backend"]`）。
- 协议类型放在插件包内。
- 领域 REST **不能**替代 `host.plugins.storage` / sidecar / MCP。

若 Guid 要把 BFF 当 MCP 调用，BFF 必须在 `/plugins/<backendId>/mcp` 上说
**MCP JSON-RPC**（原始 body）。REST `/mcp/tools` + `/mcp/call` 不是契约。
然后 `provideEndpoint({ backend: true, backendId, name, tools })`。

## 7. 可选 sidecar

声明 `findesk.sidecars[]`，带上 `versionPin`、`bin` / `args`、`healthPath`，
以及 `download`（GitHub Release）或 `localArtifact`。宿主会替换
`${moduleRoot}` / `${dataRoot}` / `${port}` / `${finclawHome}`，并注入
`FINCLAW_LLM_*`。

`bun run start` / `bun run dist` 会把二进制准备到
`resources/bundled-plugin-sidecars/<pluginId>/<sidecarId>/<platform-arch>/`，
准备失败则 **失败关闭**。

sidecar 只能 exec 自己 `moduleRoot` 内的二进制（外加宿主提供的 finclaw 目录）
— 不能查 `PATH`，不能用 `/usr/bin/…`。

## 8. 给 Guid 和智能体的 MCP

在 `ctx.effect` 内 **声明**。在 pack 里 **挂载**。默认关闭。

```typescript
ctx.effect(() =>
  ctx.tools.provideEndpoint({
    sidecarId: 'worker',
    name: 'acme-reports',
    tools: [{ name: 'list_reports', description: 'List reports', intent: 'read' }],
  })
);
```

进程内（Shape B）：`ctx.tools.provide({ name, description, intent, inputSchema, execute })`。
线上名是带资格的（`acme_reports__list_widgets`）。

`intent`：`read`（智能体可调用）· `human`（智能体得到 403）· `destructive`
（除非 `allowDestructiveTools` 列出 **带资格的** 名，否则隐藏）。

Pack 挂载（用目录 MCP **名**，不是 `acme.reports`）：

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

Guid 是本机首页对话（`/guid`）。挂到这里，该 composer 里的智能体才能看到工具。
完整表格：[plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。

## 9. Doctor 与发货

```bash
bun run doctor
bun run materialize
bun run start
bun run dist -- --mac --arm64 --pack-only
```

Doctor 打印已声明工具的 **能力** 表（不会执行它们）。分发插件是额外行 —
先审计，再用目录名挂载。

## 清单

- [ ] 插件 id 与路由唯一
- [ ] 宿主 API 只走 `@findesk/sdk`
- [ ] 若有 storage / sidecar / MCP，用 2.0 导出
- [ ] `plugins.enable` + `plugins.private`
- [ ] MCP 走 `ctx.tools`，不要 `upsertHttp`
- [ ] 已记录目录名；Guid 要看到时写 `sessionMcpAttachments`
- [ ] Sidecar Shape A：Guid 必须先拉起二进制时写 `sessionMcpSidecarEnsure`
- [ ] `bun run doctor` 看起来正确

## 反模式

- 把 TypeScript 放到 `pack/` 下
- 在表面插件里重建壳 chrome
- Vendor 官方 `core.*` 源码
- 从插件调用 `host.plugins.mcp.upsertHttp`
- 假设声明 ⇒ Guid 挂载
- 为文件 / 进程 / MCP 新增 Electron IPC
