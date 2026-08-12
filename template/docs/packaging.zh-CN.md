# 打包安装程序

[English](./packaging.md) | **中文**

## 为何 `dist` 前必须 `materialize`

Vite 会从已解析 SDK 树内联 `__FINDESK_BRAND__`：

`packages/desktop/.materialized/<distribution-id>.brand.json`

若该文件缺失，打包应用仍会嵌入 `VITE_FINDESK_FLAVOR=<your-id>`，但无法启动
静态 SKU 注册表中没有的私有分发 id — 运行时错误：

```text
Unknown distribution: "<id>". Known: consumer-hk, findesk-classic, opc-advisory
```

`scripts/dist.sh` 会自动运行 `materialize`。优先走该路径，不要手工直接调
平台 `dist` 二进制。

## 命令

```bash
bun run materialize
bun run dist -- --mac --arm64 --pack-only   # Vite 打包冒烟（更快）
bun run dist -- --mac --arm64               # DMG / zip（发版需本地签名配置）
```

`--` 之后的参数透传给平台构建器（`--win`、`--linux`、架构标志等）。

## 输出

位于已解析 SDK 下（见 [local-paths.zh-CN.md](./local-paths.zh-CN.md)）：

```text
out/mac-arm64/<App>.app
out/<Product>-<distribution-id>-<version>-mac-arm64.dmg
out/<Product>-<distribution-id>-<version>-mac-arm64.zip
```

确切产品名 / 可执行文件名来自 pack + SDK 的 electron-builder 配置。

## 检查清单

- [ ] `findesk.lock.json` 的 `artifact` + `integrity` 匹配
- [ ] 附近无 FinDesk 源码时 `bun run doctor` 仍成功
- [ ] `bun run dist` 完成（会先 materialize）
- [ ] 窗口标题 / `configHome` 与 `pack/tenant.json` 一致
- [ ] Hub URL（若配置）：`materialize` 打印 `chatkitHub` / `finskills` — 见 [hub-urls.zh-CN.md](./hub-urls.zh-CN.md)
- [ ] 遥测（若配置）：`doctor` 接受 DSN；在你们的 Sentry 做 staging 冒烟 — 见 [telemetry.zh-CN.md](./telemetry.zh-CN.md)
- [ ] 打包后 Dock / 任务栏图标与名称符合品牌（非 Electron / FinDesk 默认）
- [ ] `plugins.enable` / `plugins.private` 中的私有插件启动后可见

## 安装包图标

可选：`pack/tenant.json` → `brand.assets`：`macIcon`、`windowsIcon`、`linuxIcon`。
省略时，`materialize` 从 `logo` 合成到 `.materialized/<id>/icons/`。
生产发货建议使用专用正方形图标。

## 排查

| 现象 | 可能原因 |
| ------- | ------------ |
| `Unknown distribution` | 未 materialize / 缺少 `.brand.json` |
| Integrity mismatch | lock 中 tarball 或摘要错误 |
| `aioncore binary not found` / 对 Geeksfino/findesk-core curl 404 | 该架构未 bake、错误的 `FINDESK_PLATFORM`，或损坏的 `~/.cache/findesk/platforms/<version>` — 见下方清单。正常 findesk-std pin **不需要** Geeksfino `GH_TOKEN`。 |
| `finsafe binary not configured` / 沙箱不可用 / FinSAFE 拒绝导致 LLM 配置失败 | findesk-std **< 2.1.26** 未含 `bundled-finsafe` / `bundled-finclaw`。将 lock 升到 ≥ 2.1.26；本地迭代可用 `FINDESK_PLATFORM=<findesk monorepo>` 并先 `bun run prepare:findesk`。见技能 `dist-packaging`。 |
| 索要 Geeksfino `GH_TOKEN` | 覆盖了 SDK 已 bake 的后端版本，或私有 URL 未设 `FINDESK_ARTIFACT_TOKEN` |
| UI 中缺少插件 | id 未进 `pack/tenant.json` 的 `plugins.enable`，或包缺少 `findesk.pluginId` |

### `dist` 期间 aioncore / 私有仓库 404

findesk-std SDK 已自带 `resources/bundled-aioncore/<platform-arch>/`。`dist` 复用该树；
仅在复用失败时访问 GitHub。

1. 确认解析到的平台是 **SDK 解压目录**，而非 FinDesk 单体：
   ```bash
   echo "$FINDESK_PLATFORM"
   test -f "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-arm64/aioncore"
   ```
2. 针对你正在打包的架构（`--mac --x64` → `darwin-x64`，`--mac --arm64` → `darwin-arm64`）检查：
   ```bash
   ls "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-x64/"
   # 期望：aioncore  manifest.json  （异架构上 managed-resources 可选）
   cat "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-x64/manifest.json"
   # version 须匹配 package.json aioncoreVersion / findesk.lock findeskCore.version
   ```
3. 若缺失或版本不对，清 pin 缓存并按 `findesk.lock.json` 重新解析：
   ```bash
   unset FINDESK_PLATFORM
   rm -rf ~/.cache/findesk/platforms/<sdk-version>
   bun run doctor
   ```
4. 尽量用本机架构（Apple Silicon 上 `--mac --arm64`）。跨架构（arm64 上 `--x64`）在 SDK bake 含该架构时仍可用。
5. 仅有权访问私有 `Geeksfino/findesk-core` 的 FinDesk 工程师应设 `GH_TOKEN` 并用 `gh` 强制下载；浏览器 `curl` 对私有资产即使带 token 也会 404。
