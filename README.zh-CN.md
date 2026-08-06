# findesk-std

[English](./README.md) | **中文**

面向白标 **分发仓库（distribution repository）** 的公开 **FinDesk 桌面打包 SDK** 产物渠道。

本仓库提供 **GitHub Release 资产**、一份 **分发仓库模板**，以及简短的运维说明。**不包含** FinDesk 应用源码。

| | |
| --- | --- |
| **私有产品源码** | FinDesk 平台（不在此发布） |
| **公开 SDK 摄入** | **本仓库** — `finogeeks/findesk-std` |

## 创建分发仓库

从已发布的模板脚手架（无需 FinDesk 单体仓库）：

```bash
npx degit finogeeks/findesk-std/template findesk-dist-acme
cd findesk-dist-acme
bash scripts/init-identity.sh \
  --tenant-id acme \
  --distribution-id acme-advisory-cn \
  --config-home acme \
  --app-id com.acme.desk \
  --product-name "Acme Desk"
```

然后固定桌面 SDK 版本（见下文），替换 `pack/assets/`，并运行：

```bash
bun run doctor
bun run materialize
bun run start
```

模板文档见 [`template/docs/`](./template/docs/)（[中文索引](./template/docs/README.zh-CN.md)）。脚手架后的 Agent 技能：
`dist-packaging`、`dist-private-plugin`（见 `template/AGENTS.md`）。

持有私有 checkout 的 FinDesk 工程师可使用等价命令：

`bun run findesk new-distribution-repo …`（同一模板 + `init-identity.sh`）。

## 你将获得什么（Releases）

每个打了 `v<semver>` 标签的 [GitHub Release](https://github.com/finogeeks/findesk-std/releases) 通常包含：

| 资产 | 用途 |
| ----- | ------- |
| `findesk-desktop-sdk-<semver>.tar.gz` | 可重定位的打包 SDK（Electron 应用源、一等插件/壳、`findesk` CLI、打包脚本） |
| `findesk-desktop-sdk-<semver>.sha256` | 摘要文件（`<hex>  <filename>`） |
| `findesk-desktop-sdk-<semver>.lock.snippet.json` | 可复制进分发仓库 `findesk.lock.json` 的字段 |
| `findesk-desktop-sdk-<semver>.manifest.json` | 构建元数据（`gitSha`、`aioncoreVersion` 等） |
| `SHA256SUMS` | 整次 Release 的校验和 |

已发布桌面三元组的运行时二进制**已烘焙进 SDK**，位于
`resources/bundled-aioncore/` 与 `resources/bundled-findesk-services/`（见
Release manifest）。其余 prepare 阶段拉取由 SDK 工具处理——你**不需要**单独的产品源码 checkout。

## 在分发仓库中固定版本（在线）

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.21",
    "artifact": "https://github.com/finogeeks/findesk-std/releases/download/v2.1.21/findesk-desktop-sdk-2.1.21.tar.gz",
    "integrity": "sha256-<64-hex-chars>"
  }
}
```

从对应的 `.lock.snippet.json` 或 `.sha256` 资产复制 `integrity`（使用 `sha256-` 前缀）。

## 离线 / 气隙环境

将同一 `.tar.gz` 下载一次，放到分发仓库的 `artifacts/` 下，并在 lock 中使用**相对路径**
而非 HTTPS URL。`integrity` 仍须与发布摘要一致。

## 许可 / 访问

Release 归档面向 FinDesk 白标合作伙伴与运维方发布。产品源码与商务条款仍归凡泰极客 /
你的分发协议约束——本仓库是**产物渠道**，不是开源单体镜像。
