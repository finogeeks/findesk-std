# 私有插件

[English](./private-plugins.md) | **中文**

客户自有插件**源码**位于本分发仓库的 `plugins/`。
tenant pack（`pack/tenant.json`）只列出 **id / pin** — 不嵌入 TypeScript。

总览：[plugin-system.zh-CN.md](./plugin-system.zh-CN.md)。逐步指南：
[plugin-developer-guide.zh-CN.md](./plugin-developer-guide.zh-CN.md)。MCP 声明 vs 挂载：
[plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。

## 布局

```text
plugins/<kebab-name>/
├── package.json          # @findesk-private/<name>, findesk.pluginId
├── src/
│   ├── index.ts          # activate*Plugin + registerSurfacePlugin
│   ├── ids.ts
│   └── <Name>Page.tsx
├── sidecars/             # 可选：本地 sidecar tarball（localArtifact）
└── backend/              # 可选 BFF（findesk.backend + backendExport）
    └── index.ts
```

## package.json 约定

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

可选 BFF 字段：`backend`、`backendExport`、`backendId`。

可选受管二进制：`findesk.sidecars[]`（见 [平台特权](#平台特权-hostplugins)）。

## 在 pack 中启用

在 `pack/tenant.json`：

```json
"plugins": {
  "enable": ["example.demo"],
  "disableOptional": [],
  "private": ["example.demo"]
}
```

然后：

```bash
bun run materialize
bun run start
```

脚本设置的 `FINDESK_DIST_REPO` 让 SDK 发现 `plugins/` 下的包，并在
materialize / Vite 时生成私有插件加载器。

## Activator 模式

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

## 平台特权（`host.plugins`）

当插件需要本地文件、受管二进制或 Guid/agent MCP 时，使用
`host.plugins.*`（Proposal 0022）。**不要**加 Electron IPC 或要求改 FinDesk-main。

**要求**桌面 SDK **≥ 2.1.27**（暴露 `FinDeskHost.plugins`）。发货前在
`findesk.lock.json` 中固定该版本。

| API | 用途 |
| --- | --- |
| `host.plugins.storage` | `userData/plugins/<pluginId>/…` |
| `host.plugins.files` | 选择 / 导入 / 列表 / 打开 / 显示 / 删除 |
| `host.plugins.sidecars` | ensure / status / stop / fetch（回环 HTTP 到你自己的 sidecar） |
| `ctx.tools.provideEndpoint` | 为 Guid/智能体注册 sidecar 或 BFF MCP |
| `ctx.tools.provide` | 进程内（Shape B）工具；见 [plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md) |

### Sidecar 声明（`findesk.sidecars[]`）

在插件 `package.json` 上声明受管二进制。示例（casst / 知识库模式）：

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

宿主会替换 `${moduleRoot}` / `${dataRoot}` / `${port}` / `${finclawHome}`，
将模块 `bin/` 与烘焙的 finclaw 目录前置到 `PATH`，并注入 Hub/BYOK
`FINCLAW_LLM_*`。有 tarball 时优先用插件下的 `localArtifact`；否则
`download` 从 GitHub Releases 拉取。

`bun run start` / `bun run dist`（配合 `FINDESK_DIST_REPO`）会把每个 sidecar
准备到 `resources/bundled-plugin-sidecars/<pluginId>/<sidecarId>/<platform-arch>/`；
若声明的 sidecar 无法准备则**构建失败**。`versionPin` 变更或
`localArtifact` 新于 prepare manifest 时会重新准备。

标准 FinDesk **不**附带 vault/sidecar 模块 — 由分发端到端拥有。
使用你自己的 MCP 名 + pack `agentSeed` — 不要依赖已移除的一等
`host.findesk.knowledgeVault` / Secretary 接线。

调用时始终用**你的** `findesk.pluginId` 限定范围。跨插件路径默认失败关闭。
领域 HTTP 可保留可选 `backend/`；它不能替代上述特权。

需要可跟踪撤销（storage + MCP）时，导出 **2.0** `FinDeskPlugin` — 不要写第二个
`activateMyPlugin`。将 `findesk.activateExport` 设为该导出；加载器**仅**调用这一导出（可以是该 `FinDeskPlugin` 对象，或 1.0 的 `(host, boot)` 函数 — 不能两者兼有）：

```typescript
import type { FinDeskPlugin } from '@findesk/sdk';
import { MY_PLUGIN_ID } from './ids.js';

export const myPlugin: FinDeskPlugin = {
  name: MY_PLUGIN_ID,
  apply(ctx) {
    ctx.effect(async () => {
      await ctx.host.plugins.storage.ensureDir(MY_PLUGIN_ID, 'data');
    });
    ctx.effect(() =>
      ctx.tools.provideEndpoint({
        sidecarId: 'worker',
        name: 'my-plugin-local',
        tools: [{ name: 'list_items', description: 'List items', intent: 'read' }],
      })
    );
  },
};
```

原始 `host.plugins.mcp.upsertHttp` 仍为 Guid/产品种子保留；**插件不应直接调用** — 请使用 `ctx.tools.provideEndpoint`，以便 MCP 注册随插件 fiber 一并撤销。

声明 MCP 不等于挂到 Guid。分发作者必须在 `pack/tenant.json` 的
`agentSeed.sessionMcpAttachments` 中显式选择（用 `core-home` 这类目录名，不是带点的插件 id）。完整契约：[plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。

向知识类 sidecar 导入文件后，通过回环 fetch 预热：

```typescript
await host.plugins.sidecars.fetch(MY_PLUGIN_ID, 'casst', '/warm', { method: 'POST' });
```

## 规则

- 宿主 API **只**从 `@findesk/sdk` 导入 — 插件 UI 中禁止 Electron `ipcRenderer`。
- 特权 FS / 进程 / MCP → `host.plugins.*`；产品域 → SDK 暴露时用 `host.findesk.*`。
- 优先 Arco + UnoCSS；宿主有 locale 模块时，用户可见文案走 i18n key。
- 本分发内插件路由保持唯一。
- 一等共享插件（`core.*` 等）留在 SDK — 仅通过 id 启用；不要在此 vendor 其源码。

## Agent 技能

见 [`.claude/skills/dist-private-plugin/SKILL.md`](../.claude/skills/dist-private-plugin/SKILL.md)。
