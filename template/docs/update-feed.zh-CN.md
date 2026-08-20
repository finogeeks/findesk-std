# 在线升级源

[English](./update-feed.md) | **中文**

客户端读 `release.onlineUpdate`（提案 0027）。CI 通过 `release.publish` 和可插拔适配器写入（提案 0032）。分发仓库作者只配这两块，**不要**自己实现上传逻辑。

## Pack 配置

`pack/tenant.json`：

```json
"release": {
  "channel": "stable",
  "onlineUpdate": {
    "feedUrl": "https://updates.example.com/mydistro"
  },
  "publish": {
    "adapter": "s3",
    "bucket": "example-updates",
    "prefix": "mydistro",
    "endpoint": "https://oss-cn-hangzhou.aliyuncs.com",
    "region": "cn-hangzhou"
  }
}
```

| 字段 | 作用 |
| --- | --- |
| `channel` | `stable` / `beta` 打开 updater；`internal` / `none` 关闭 |
| `onlineUpdate.githubRepo` | 公开 `owner/repo`（GitHub Releases 读侧 + github 适配器缺省） |
| `onlineUpdate.feedUrl` | 通用 HTTPS 源；与 `githubRepo` 同时存在时优先 |
| `publish.adapter` | `github` / `s3` / `rsync` / `file` / `external` |
| `publish.originReachability` | `public`（缺省）或 `internal`，只影响签名闸强度 |

密钥不要进 pack。凭据只走环境变量：

| 适配器 | Env |
| --- | --- |
| `github` | `GH_TOKEN` |
| `s3` | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / 可选 `AWS_SESSION_TOKEN`（真 AWS 推荐 OIDC） |
| `rsync` | `RSYNC_SSH_KEY` 或 ssh-agent |
| `file` | 无（本地/挂载路径） |
| `external` | 无 — SDK 跳过上传，走你们自己的流水线 |

`feedUrl` + `adapter: "github"` 会被拒绝（`feed-adapter-mismatch`）。只用 GitHub 的分发不要配 `feedUrl`。

脚手架：`init-identity.sh --update-origin github|generic|external`。

## SDK pin

`findesk.lock.json` 必须指向 findesk-std **≥ 2.1.41**（0032 `--publish`）。更旧的 pin 仍可准备 GitHub 清单（0027），但不能分发适配器。

`doctor` 只检查声明（不碰凭据）。`--probe` 只对 `feedUrl` 布局发 HEAD；纯 GitHub 配置会跳过。

## 发布

`bun run dist` 之后：

```bash
bun run publish:online-update -- --out-dir "$FINDESK_PLATFORM/out" --dry-run
bun run publish:online-update -- --out-dir "$FINDESK_PLATFORM/out"
```

薄脚本必须在分发仓根执行，且不得 `cd` 进 SDK。

签名安装是 `channel: stable` + 公网源的必过闸（0027 G-SIGN）。未签名 CI 不得宣称生产升级闭环。

## 相关

- [packaging.zh-CN.md](./packaging.zh-CN.md)
- [upstream-sdk.zh-CN.md](./upstream-sdk.zh-CN.md)
- 提案 0027 — feed 契约；提案 0032 — 通用更新源
