# 上游 SDK（findesk-std）

[English](./upstream-sdk.md) | **中文**

本分发**固定**来自
[`finogeeks/findesk-std`](https://github.com/finogeeks/findesk-std)
已发布的桌面 SDK。将该仓库视为**上游**：监视 Release，当其领先于
`findesk.lock.json` 时开 Issue，再在你选择切换时升级 lock。

## 每日监视（GitHub Actions）

工作流：[`.github/workflows/findesk-std-upstream-watch.yml`](../.github/workflows/findesk-std-upstream-watch.yml)

| | |
| --- | --- |
| 计划 | `0 2 * * *`（每日 UTC 02:00） |
| 手动 | Actions → **findesk-std upstream watch** → Run workflow |
| 演练 | `dry_run=true`（不创建/评论 Issue） |
| 本地 | `bash scripts/watch-findesk-std.sh` / `--dry-run` |

当最新非 draft Release **新于** `findesk.lock.json` 中的 `findesk.version` 时，
任务会打开（或评论）带 `upstream:findesk-std` 标签的 Issue，并附升级清单。
它**不会**改 lock，也不会下载 tarball。

权限：`issues: write`（默认 `GITHUB_TOKEN`）。读取公开 findesk-std Release
无需额外 secret。

## Issue 打开之后

按 Issue 清单执行（lock snippet → `findesk.lock.json` → doctor →
materialize → dist）。技能：[`dist-packaging`](../.claude/skills/dist-packaging/SKILL.md)。

## 禁用

在 GitHub Actions UI 中删除或禁用该工作流，或从本仓库移除
`.github/workflows/findesk-std-upstream-watch.yml`。
