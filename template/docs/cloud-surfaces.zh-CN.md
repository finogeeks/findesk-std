# 云上表面（`policy.cloudSurfaces`）

[English](./cloud-surfaces.md) | **中文**

控制本发行是否暴露 **ChatKit Hub 登录**、**云上 FinClaw**、**Hub 技能目录**、
**Hub LLM**。需要桌面 SDK 已包含 `policy.cloudSurfaces` 字段。

| 取值 | 结果 |
| ----- | ------ |
| 省略 / `"on"` | 一等品行为：登录墙 + Hub 表面 |
| `"off"` | 纯底座：不 bootstrap Hub、无云上 FinClaw、无技能市场；模型只靠设置里的 BYOK / 私有 LLM |

**不要**把 `"off"` 与 `integrations.chatkitHubUrl`、`integrations.finSkillsHubUrl`
或 `integrations.hubUrlsLocked: true` 一起写。`bun run doctor` 会拒绝。

## 纯底座 pack

省略整个 `integrations` 块，并设置：

```json
"policy": {
  "allowedTrustZones": ["on-device", "private-cloud"],
  "defaultTrustZone": "on-device",
  "locale": "zh-CN",
  "cloudSurfaces": "off"
}
```

在 findesk-std 尚未发布该字段前，本地 `doctor` / `materialize` / `start` 请用
`FINDESK_PLATFORM` 指向已合入该能力的 FinDesk 源码树。

另见 [hub-urls.zh-CN.md](./hub-urls.zh-CN.md)。
