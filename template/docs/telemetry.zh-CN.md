# 遥测（Sentry / OTLP）

在 `pack/tenant.json` 中固定本分发的崩溃与诊断上报目标，使安装包导出到
**你们自己的** Sentry（或 OTLP）— 而不是 FinDesk SaaS。

需要包含 **Proposal 0026** 遥测打包（materialize + doctor）的桌面 SDK。若
`bun run doctor` 在存在 `telemetry` 块时不校验该字段，请将 `findesk.lock.json`
升到已包含该能力的 findesk-std 版本。

DSN 属于**配置**而非密钥。请先使用**预发 / staging** 项目；在组织就绪前不要写入生产 DSN。

## 配置

在 `policy` / `plugins` / `integrations` 旁增加可选的 `telemetry` 块：

```json
{
  "schemaVersion": 1,
  "tenantId": "acme",
  "brand": {},
  "application": {},
  "telemetry": {
    "mode": "self_hosted_sentry",
    "sentryDsn": "https://KEY@sentry.your-org.example/1",
    "consentDefault": "opt-in"
  }
}
```

| 字段 | 含义 |
| ----- | ------- |
| `mode` | `self_hosted_sentry` \| `otel` \| `dual` \| `off`。省略时由 DSN / endpoint 推断。 |
| `sentryDsn` | 客户自建 Sentry（或 Relay）DSN。`self_hosted_sentry` / `dual` 时必填。 |
| `otelEndpoint` | `otel` / `dual` 时的 OTLP HTTP JSON 绝对 HTTPS URL。 |
| `consentDefault` | `opt-in`（用户须在「设置 → 隐私」开启）、`opt-out`（默认开、可关）、或 `enterprise-mandatory`（始终开；UI 不得声称用户已关闭）。 |

省略整个 `telemetry` 块（或 `mode: "off"` / 空 DSN）表示**不向远端导出**。

### 硬性规则

- `self_hosted_sentry` 与 `dual` **不得**使用托管 SaaS 主机名，如
  `*.sentry.io` / `*.ingest.sentry.io`。`bun run doctor` 会拒绝。
- 企业目标为**客户自建** Sentry（或 Relay）；FinDesk 不会代填生产 DSN。
- 公开模板不包含真实客户 DSN — 由你们自行提供。

## 生效

```bash
bun run doctor        # 存在 telemetry 块时进行校验
bun run materialize   # 将遥测写入品牌描述符
bun run dist -- …     # 会先 materialize；安装包嵌入 DSN
```

materialize 后，品牌经 `__FINDESK_BRAND__` 携带遥测配置。无 DSN ⇒ SDK 对远端导出保持空操作。

### 后端（可选）

打包进 SDK 的 `aioncore`（findesk 特性）也可导出。在后端进程上设置环境变量（**不要**写进 `tenant.json`）：

| 环境变量 | 含义 |
| --- | ------- |
| `FINDESK_SENTRY_DSN` 或 `SENTRY_DSN` | 后端 Sentry DSN |
| `FINDESK_TELEMETRY_OPT_OUT=1` | 即使有 DSN 也关闭远端导出 |
| `FINDESK_SENTRY_RELEASE` | 可选 release 覆盖（默认 `aioncore@…`） |

## 同意（设置 → 隐私）

| `consentDefault` | 行为 |
| ---------------- | -------- |
| `opt-in` | 应用层诊断默认关，用户开启后才导出 |
| `opt-out` | 默认开，用户可关 |
| `enterprise-mandatory` | 始终开；隐私开关锁定 |

更改同意后可能需要重启应用，活动中的遥测 sink 才会重建。

## 冒烟清单（你们的 staging 项目）

在**非生产** Sentry 项目上验证。桌面 release 形如
`findesk@<version>+<distributionId>`。

1. 使用 staging DSN 执行 materialize / start（或打包）。
2. 若 `consentDefault` 为 `opt-in`，在「设置 → 隐私」开启诊断。
3. 触发已知路径（应用内反馈，或有意的诊断消息），确认事件出现在**你们的**项目。
4. 抽查脱敏：事件中不得出现提示词、token 或绝对家目录路径等原始 extras。
5. 若 `mode: dual`，确认 Sentry 与 OTLP HTTP 端点均收到应用层事件（网关可能把 JSON 映射为 OTLP）。
6. 关闭隐私开关（`opt-in` / `opt-out`）后确认应用层停止导出；`enterprise-mandatory` 下开关应保持锁定开启。

## 客户侧后续工作

以下由你们组织负责 — 不属于 FinDesk 工程交付缺口：

| 事项 | 你们需要做的 |
| ---- | ----------- |
| 仪表盘 / 告警 | 在**你们的** Sentry 组织中创建崩溃率、启动失败、安装完整性等告警 |
| 生产 DSN | 就绪后替换 `pack/tenant.json` 中的 staging DSN，并重新 materialize / 发布 |
| Source map | 在**你们的**发布流水线上配置 `SENTRY_AUTH_TOKEN`、`SENTRY_ORG`、`SENTRY_PROJECT`；为每个要发布的 OS 验证 Sentry 中可解析的压缩堆栈 |

## 已有分发仓库

已脚手架生成的仓库**不会**自动获得新的模板文档。当你们开始接入 staging 遥测时，请从当前
`finogeeks/findesk-std` 的 `template/docs/`（或 FinDesk 的
`templates/distribution-repo/docs/`）复制本文件与 [telemetry.md](./telemetry.md)
到分发仓库的 `docs/`，或在该分发仓库开一个小型文档 PR。

## 排查

| 现象 | 可能原因 |
| ------- | ------------ |
| Doctor 拒绝 DSN | `self_hosted_sentry` / `dual` 使用了托管 `*.sentry.io` |
| Doctor 要求 `sentryDsn` | 模式为 `self_hosted_sentry` / `dual` 但缺少 DSN |
| Sentry 无事件 | 未 materialize/dist；`opt-in` 未开隐私；telemetry 为空或省略 |
| 关闭后仍有事件 | 切换隐私后需重启；或 `enterprise-mandatory` |
| 后端无声 | 未设 `FINDESK_SENTRY_DSN`，或设置了 `FINDESK_TELEMETRY_OPT_OUT=1` |

## 示例（企业自建）

```json
"telemetry": {
  "mode": "self_hosted_sentry",
  "sentryDsn": "https://KEY@sentry.customer.example/1",
  "consentDefault": "enterprise-mandatory"
}
```

## 示例（双路由）

```json
"telemetry": {
  "mode": "dual",
  "sentryDsn": "https://KEY@sentry.customer.example/1",
  "otelEndpoint": "https://otel.customer.example/v1/logs",
  "consentDefault": "opt-out"
}
```
