# 插件体系（总览）

[English](./plugin-system.md)

FinDesk 插件如何拼在一起。逐步编写指南见
[plugin-developer-guide.zh-CN.md](./plugin-developer-guide.zh-CN.md)。
MCP 声明 vs 挂载：[plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。
包契约：[private-plugins.zh-CN.md](./private-plugins.zh-CN.md)。

**不需要**私有 FinDesk 单体仓库。固定一份导出 `@findesk/sdk` 的桌面 SDK
（`FinDeskPlugin`、`ctx.effect`、`ctx.tools`）即可。

## 分层

一份已发货产品（本分发）= **壳（shell）** + 一组 **插件**，跑在 **宿主（host）** 上。
插件永不 import Electron 或桌面 renderer。

```text
L1  宿主     @findesk/sdk  — 注册表、host.plugins.*、ctx.tools
L2  壳       chrome        — 侧栏、顶栏、布局（启用一条基线即可；不要自己重建）
L3  插件     本仓库         — 导航 + 视图 + 可选 BFF / sidecar / MCP 工具
```

- **壳** 负责 chrome 布局，并读取 `host.registries.*`。
- **插件** 贡献一条可路由的表面（以及可选后端）。一个插件 ≈ 一个导航项 / 有界上下文。
- **Pack**（`pack/tenant.json`）按插件 **id** 开关。它不嵌入 TypeScript。

**Guid** 是本机首页对话（路由 `/guid`）。用户看到的是首页 / 数字员工，而不是
“Guid” 这个词。“挂到 Guid” 的意思是：让从该首页 composer 启动的智能体会话
能用到这些 MCP 工具。

## 官方 vs 私有

| 种类 | 源码在哪 | 怎么用 |
| --- | --- | --- |
| 官方（`core.*` 等） | 桌面 SDK 内 | 在 pack 里按 **id** 启用。不要 vendor 源码。 |
| 私有（`@findesk-private/*`） | 本仓库 `plugins/<kebab>/` | 你拥有源码。把 id 列入 `plugins.enable` 和 `plugins.private`。 |

两类共用同一套 SDK API。脚本设置 `FINDESK_DIST_REPO` 后，加载器会发现私有包。

## 插件运行时 2.0

运行时是 **Cordis 形态**（可回滚的 effect + `inject` / `provide` 名）。
renderer **不依赖** `cordis` 包。

| 概念 | 对你意味着什么 |
| --- | --- |
| **1.0 activator** | `function activateX(host) { registerSurfacePlugin(host, …) }`。仅 UI 的插件仍可用。 |
| **2.0 `FinDeskPlugin`** | `{ name, apply(ctx) { … } }`。需要可追踪拆除（sidecar、MCP、storage）时必用。 |
| **`ctx.effect`** | 注册插件禁用时必须 **撤销** 的工作。逆操作按 LIFO 执行。 |
| **单一导出** | `findesk.activateExport` 是 **要么** 2.0 对象 **要么** 1.0 函数 — 不能两个都是。 |

把定时器、sidecar ensure、MCP 注册放进 `ctx.effect`。activator 里裸写
`void ensureRuntime(host)` 没有逆操作。

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

## 插件可以贡献什么

| 贡献 | 方式 |
| --- | --- |
| 导航 + 视图（UI） | `registerSurfacePlugin` / `host.registries` |
| Copilot 上下文 | 表面注册上的 `copilotContext` |
| 回环 HTTP（BFF） | `findesk.backend` + `backend/` 模块 |
| 受管二进制 | `findesk.sidecars[]` + `host.plugins.sidecars` |
| 智能体工具（MCP） | `ctx.tools.provide` 或 `provideEndpoint` — 然后由分发 **挂载** |

特权本地 IO 用 `host.plugins.{storage,files,sidecars}` — 永远不要用
`ipcRenderer`。产品域 API（当 SDK 暴露时）留在 `host.findesk.*`。

## MCP 是一种贡献，不是镜像

声明工具 **不会** 把它们放到 Guid 上。插件若自动把每个 API 暴露成 MCP，
就是权限漏洞。

1. **插件** 在 fiber 上声明工具（`ctx.tools`）。
2. **分发** 在 `pack/tenant.json` 的 `agentSeed.sessionMcpAttachments` 里
   挂上 **目录 MCP 名**。
3. 默认 **关闭**。目录名 ≠ 带点的插件 id（通常把点换成连字符）。

**不要** 在插件里调用 `host.plugins.mcp.upsertHttp`。该 API 仍留给产品种子；
插件 MCP 必须走 `ctx.tools`，这样禁用时才会撤回目录条目。

形态（细节见 [plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)）：

| 形态 | 何时 |
| --- | --- |
| **A** sidecar HTTP | 受管二进制已经会说 MCP |
| **A′** BFF JSON-RPC | 宿主节点 `/plugins/<backendId>/mcp` |
| **B** 进程内 | UI 自有状态；在插件里写 `execute` |

## 接下来读

1. [plugin-developer-guide.zh-CN.md](./plugin-developer-guide.zh-CN.md) — 脚手架 → UI → BFF → sidecar → MCP → doctor
2. [private-plugins.zh-CN.md](./private-plugins.zh-CN.md) — `package.json` 与启用字段
3. [plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md) — intent、目录名、`agentSeed`
4. 技能 [`.claude/skills/dist-private-plugin/SKILL.md`](../.claude/skills/dist-private-plugin/SKILL.md)
