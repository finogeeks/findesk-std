# 快速开始

[English](./getting-started.md) | **中文**

在**没有** FinDesk / findesk-core 源码的情况下构建并运行本分发。

## 前置条件

- 已安装 **Bun** 的 macOS、Linux 或 Windows
- FinDesk **桌面 SDK** tarball 与 `sha256-…` 完整性摘要（来自 FinDesk 或
  [finogeeks/findesk-std](https://github.com/finogeeks/findesk-std) Releases）
- 身份文件已就绪（`catalog.json`、`pack/tenant.json` 等）。在
  `degit finogeeks/findesk-std/template` 之后，先运行一次
  `bash scripts/init-identity.sh …`（见仓库 README）。

当 lock 的 `integrity` 匹配时，拉取公开 `finogeeks/findesk-std` 资产**不需要**
GitHub token。Geeksfino 组织 token 仅供 FinDesk 维护者使用。

## 1. 固定 SDK 版本

编辑 `findesk.lock.json`。离线 / 在线示例见 [lock-examples.zh-CN.md](./lock-examples.zh-CN.md)。

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.17",
    "artifact": "artifacts/findesk-desktop-sdk-2.1.17.tar.gz",
    "integrity": "sha256-<64-hex-chars>"
  }
}
```

`artifact` 可以是本仓库下的路径、`file://…`，或仅 `https://…`
（`http://` 需要 `FINDESK_ALLOW_INSECURE_HTTP=1`）。

## 2. 品牌化产品

1. 替换 `pack/assets/logo.png`（以及 favicon）。
2. 发货建议：`assets/app.icns`、`assets/app.ico`、`assets/app.png`
   （或设置 `brand.assets.macIcon` / `windowsIcon` / `linuxIcon`）。若省略，
   `materialize` 会从 logo 合成安装包图标。
3. 编辑 `pack/tenant.json`（`productName`、`appId`、`configHome`、语言、插件）。
4. 可选：在 `integrations` 下配置 ChatKit / FinSkills Hub URL — 见
   [hub-urls.zh-CN.md](./hub-urls.zh-CN.md)。
5. 可选：在 `telemetry` 下固定客户 Sentry / OTLP — 见
   [telemetry.zh-CN.md](./telemetry.zh-CN.md)。
6. 若 SKU id 或 shell 基线变更，编辑 `pack/distributions/<id>.json`。

`configHome` 隔离运行时数据（例如 `~/.acme`）。不要在多个产品间共用。

## 3. 校验并运行

```bash
bun run doctor        # 校验 pack + lock + 解析 SDK（首次解压 tarball）
bun run materialize   # 将品牌写入已解析的 SDK 树
bun run start         # 本分发的 Electron 开发启动
```

脚本会导出 `FINDESK_DIST_REPO`（本仓库）与 `FINDESK_WHITE_LABEL=1`。

## 可选环境变量

| 环境变量 | 含义 |
| --- | ------- |
| `FINDESK_PLATFORM` | 使用已解压的 SDK 目录 |
| `FINDESK_PLATFORM_CACHE` | 缓存根目录（默认 `~/.cache/findesk/platforms`） |
| `FINDESK_ARTIFACT_TOKEN` | **私有** HTTPS 产物 URL 的 Bearer token |
| `FINDESK_DISTRIBUTION_ID` | 覆盖分发 id（默认来自 `catalog.json`） |
| `AIONCORE_PREFER_LOCAL` | 客户侧保持 `0` / 未设置 |

下一步：[hub-urls.zh-CN.md](./hub-urls.zh-CN.md) · [packaging.zh-CN.md](./packaging.zh-CN.md) · [private-plugins.zh-CN.md](./private-plugins.zh-CN.md) · [plugin-tools.zh-CN.md](./plugin-tools.zh-CN.md)。
