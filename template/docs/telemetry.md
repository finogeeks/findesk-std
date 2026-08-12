# Telemetry (Sentry / OTLP)

Pin your distribution’s crash and diagnostics destination in `pack/tenant.json`
so packaged installs export to **your** Sentry (or OTLP) — not FinDesk SaaS.

Requires a desktop SDK that includes **Proposal 0026** telemetry packaging
(materialize + doctor). If `bun run doctor` does not validate a `telemetry`
block when present, bump `findesk.lock.json` to a findesk-std release that
ships that support.

DSN values are **configuration**, not secrets. Prefer a **staging** project
first; omit production DSNs until your org is ready.

## Configure

Add an optional `telemetry` block next to `policy` / `plugins` /
`integrations`:

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

| Field | Meaning |
| ----- | ------- |
| `mode` | `self_hosted_sentry` \| `otel` \| `dual` \| `off`. Omit to infer from DSN / endpoint. |
| `sentryDsn` | Customer-operated Sentry (or Relay) DSN. Required when mode is `self_hosted_sentry` or `dual`. |
| `otelEndpoint` | Absolute HTTPS URL for OTLP HTTP JSON when mode is `otel` or `dual`. |
| `consentDefault` | `opt-in` (user must enable in Settings → Privacy), `opt-out` (on until user disables), or `enterprise-mandatory` (always on; UI cannot claim user-disabled). |

Omit the whole `telemetry` block (or set `mode: "off"` / empty DSN) for **no
remote export**.

### Hard rules

- For `self_hosted_sentry` and `dual`, **do not** use hosted SaaS hosts such as
  `*.sentry.io` / `*.ingest.sentry.io`. `bun run doctor` rejects those.
- Enterprise destination is **customer-operated** Sentry (or Relay), not
  FinDesk-invented production DSNs.
- FinDesk does not ship real customer DSNs in the public template — you supply
  them.

## Apply

```bash
bun run doctor        # validates telemetry when the block is present
bun run materialize   # bakes telemetry into the brand descriptor
bun run dist -- …     # materialize runs first; packaged app embeds the DSN
```

After materialize, the brand carries telemetry into `__FINDESK_BRAND__`. No DSN
⇒ SDK init stays no-op for remote export.

### Backend (optional)

Packaged `aioncore` can also export when the findesk feature is built into the
SDK bake. Set on the backend process (not in `tenant.json`):

| Env | Meaning |
| --- | ------- |
| `FINDESK_SENTRY_DSN` or `SENTRY_DSN` | Backend Sentry DSN |
| `FINDESK_TELEMETRY_OPT_OUT=1` | Disable remote export even if a DSN is set |
| `FINDESK_SENTRY_RELEASE` | Optional release override (default `aioncore@…`) |

## Consent (Settings → Privacy)

| `consentDefault` | Behavior |
| ---------------- | -------- |
| `opt-in` | App-layer diagnostics off until the user enables them |
| `opt-out` | On by default; user may turn off |
| `enterprise-mandatory` | Always on; Privacy toggle locked |

Changing consent may require an app restart for the active telemetry sink to
rebuild.

## Smoke checklist (your staging project)

Run against a **non-production** Sentry project. Confirm release identity looks
like `findesk@<version>+<distributionId>` (desktop).

1. Materialize / start (or package) with your staging DSN.
2. Settings → Privacy → enable diagnostics if `consentDefault` is `opt-in`.
3. Trigger a known path (in-app feedback, or an intentional diagnostics
   message). Confirm the event appears in **your** project.
4. Spot-check redaction: events must not contain prompts, tokens, or absolute
   home paths as raw extras.
5. If `mode: dual`, confirm both Sentry and your OTLP HTTP endpoint receive an
   app-layer event (gateway may map JSON → OTLP).
6. Toggle Privacy off (`opt-in` / `opt-out`) and confirm app-layer export stops;
   for `enterprise-mandatory`, confirm the toggle stays locked on.

## Customer-owned leftovers

These stay with your org — they are not FinDesk engineering deliverables:

| Item | What you do |
| ---- | ----------- |
| Dashboards / alerts | Create crash-free sessions, startup-failure, and integrity alerts in **your** Sentry org |
| Production DSN | Replace staging DSN in `pack/tenant.json` when ready; rematerialize / redeploy |
| Source maps | Set `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT` on **your** release builders; verify minified stacks resolve in Sentry for each OS you ship |

## Existing distribution repos

Scaffolded repos do **not** auto-receive new template docs. When you adopt
staging telemetry, copy this file (and [telemetry.zh-CN.md](./telemetry.zh-CN.md))
from a current `finogeeks/findesk-std` `template/docs/` (or FinDesk
`templates/distribution-repo/docs/`) into your distro’s `docs/`, or open a
small docs PR in that distro.

## Troubleshooting

| Symptom | Likely cause |
| ------- | ------------ |
| Doctor rejects DSN | Hosted `*.sentry.io` with `self_hosted_sentry` / `dual` |
| Doctor requires `sentryDsn` | Mode is `self_hosted_sentry` / `dual` but DSN missing |
| No events in Sentry | Missing materialize/dist; `opt-in` without Privacy enable; empty / omitted telemetry |
| Events after opt-out | Restart app after toggling Privacy; or `enterprise-mandatory` |
| Backend silent | `FINDESK_SENTRY_DSN` unset, or `FINDESK_TELEMETRY_OPT_OUT=1` |

## Example (enterprise self-hosted)

```json
"telemetry": {
  "mode": "self_hosted_sentry",
  "sentryDsn": "https://KEY@sentry.customer.example/1",
  "consentDefault": "enterprise-mandatory"
}
```

## Example (dual route)

```json
"telemetry": {
  "mode": "dual",
  "sentryDsn": "https://KEY@sentry.customer.example/1",
  "otelEndpoint": "https://otel.customer.example/v1/logs",
  "consentDefault": "opt-out"
}
```
