# 本机路径（开发机）

[English](./local-paths.md) | **中文**

从本分发仓库开发与打包时，文件落在何处。

## 源码（本仓库）

```text
<dist-repo>/
├── pack/                 # 品牌 + tenant + 分发 SKU
├── plugins/              # 私有插件源码
├── artifacts/            # 可选离线 SDK tarball
└── findesk.lock.json     # 版本固定
```

## SDK 解析 / 构建缓存

默认缓存根：`~/.cache/findesk/platforms/<version-key>/`

| 路径 | 作用 |
| ---- | ---- |
| `…/src/findesk-desktop-sdk-*/` | 已解压桌面 SDK（一次性 `bun install`） |
| `…/packages/desktop/.materialized/<id>.brand.json` | `materialize` 写入的品牌描述符 |
| `…/packages/desktop/.materialized/<id>.electron-builder.json` | 安装包身份覆盖（`appId`、产品名等） |
| `…/out/<Product>.app`（或平台等价物） | 打包后的应用 |
| `…/out/*-<distribution-id>-*.dmg` | 安装包产物 |

用 `FINDESK_PLATFORM_CACHE` 覆盖缓存，或用 `FINDESK_PLATFORM` 指向已解压目录。

## 运行时（启动应用之后）

白标构建是**完整应用**：Electron `userData` 由 pack 的
`productNameEn` / `executableName` 与 `appId` 隔离（不在 FinDesk 之下）。

| 路径 | 作用 |
| ---- | ---- |
| `~/.<configHome>` | CLI 友好符号链接 → Application Support / AppData 产品目录 |
| `~/Library/Application Support/<Product>/`（macOS） | Electron userData + 后端 DB / 运行时 |
| `~/Library/Logs/<Product>/` | 主进程 + aioncore 日志 |

示例（国信）：`configHome: guosen`，安装包产品名
`Guosen Securities AI Desk` → `~/Library/Application Support/Guosen Securities AI Desk/`，
`~/.guosen` 指向该树。

开发（`bun run start`）使用 `devAppName`（例如 `GuosenAIDesk-Dev`）。

## 默认不会系统安装

执行 `open …/out/…/*.app` **不会**复制到 `/Applications`。需要系统级安装时请用 DMG。
