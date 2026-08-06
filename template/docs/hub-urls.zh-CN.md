# Hub URL（ChatKit + FinSkills）

[English](./hub-urls.md) | **中文**

在 `pack/tenant.json` 中固定本分发的 ChatKit Hub 与 FinSkills Hub 端点，
使打包安装后直接指向你的 Hub（无需每个用户打开「设置 → 集成」）。

需要包含 **Proposal 0024**（Hub URL materialize + seed/lock）的桌面 SDK。
若 `bun run materialize` 未打印 `chatkitHub:` / `finskills:` 行，请将
`findesk.lock.json` 升到带该能力的 findesk-std 版本（本地迭代也可用
`FINDESK_PLATFORM` 指向已合入该能力的 FinDesk 树）。

## 配置

在 `policy` / `plugins` 旁增加可选的 `integrations` 块：

```json
{
  "schemaVersion": 1,
  "tenantId": "acme",
  "brand": { },
  "application": { },
  "integrations": {
    "chatkitHubUrl": "https://hub.your-org.example.com",
    "finSkillsHubUrl": "https://skills.your-org.example.com",
    "hubUrlsLocked": false
  }
}
```

| 字段 | 含义 |
| ----- | ------- |
| `chatkitHubUrl` | 绝对 ChatKit / Claw Hub 基址（HTTPS）。种子写入设置中的网关 URL。 |
| `finSkillsHubUrl` | 绝对 FinSkills Hub URL（HTTPS）。可含路径（如 `/client`）。 |
| `hubUrlsLocked` | `false`（默认）：首次启动种子一次，用户仍可改。`true`：组织托管 — 读取时以 pack 为准；集成 UI 只读。 |

省略整个 `integrations` 块则保持一等产品行为（由用户自行配置 Hub）。

### URL 规则

- 必须是绝对 `https://…`
- 仅本地 pack 允许 `http://localhost` / `http://127.0.0.1`
- 空字符串会被 `bun run doctor` 拒绝

## 应用

```bash
bun run doctor        # 存在时校验 integrations URL
bun run materialize   # 应打印 chatkitHub / finskills 行
bun run dist -- …     # materialize 会先执行；品牌中嵌入 URL
```

全新用户配置首次启动时，应用从品牌描述符**种子**尚未设置的 Hub 键。
已有用户设置不会被覆盖（`seed-once`）。`hubUrlsLocked: true` 时，无论
设置中存了什么，都以 pack 值为准。

## 检查清单

- [ ] `integrations.chatkitHubUrl` / `finSkillsHubUrl` 是你要发货的 Hub
- [ ] `hubUrlsLocked` 符合合规姿态（受监管 SKU 用 `true`）
- [ ] `bun run doctor` 通过
- [ ] `bun run materialize` 打印预期的 Hub 行
- [ ] 全新安装 → 设置 → 集成 显示种子 URL
- [ ] 锁定模式：字段禁用 +「由组织管理」（或对应文案）

## 排查

| 现象 | 可能原因 |
| ------- | ------------ |
| Doctor 报 URL 错 | 非绝对 HTTPS（或非 localhost 的 HTTP） |
| Materialize 打印 `hubs: (user-configured — no pack integrations)` | 块缺失/为空，或 SDK 早于 0024 |
| 打包应用 Hub 仍为空 | 未 rematerialize/dist 的旧安装；或 lock 无 0024 |
| 用户覆盖被忽略 | `hubUrlsLocked: true` — 预期行为 |
| 升级后用户覆盖丢失 | `hubUrlsLocked: false` 下不应发生（seed-once）；若发生请报 bug |

## 示例（FDE 风格）

```json
"integrations": {
  "chatkitHubUrl": "https://clawtest.finogeeks.club",
  "finSkillsHubUrl": "https://skillhub.finogeeks.club/client",
  "hubUrlsLocked": false
}
```
