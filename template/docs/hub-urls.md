# Hub URLs (ChatKit + FinSkills)

Pin your distribution’s ChatKit Hub and FinSkills Hub endpoints in
`pack/tenant.json` so packaged installs come up pointed at your hubs
(without asking every user to open Settings → Integrations).

Requires a desktop SDK that includes **Proposal 0024** (hub URL materialize +
seed/lock). If `bun run materialize` does not print `chatkitHub:` /
`finskills:` lines, bump `findesk.lock.json` to a findesk-std release that
ships that support (or use `FINDESK_PLATFORM` against a FinDesk tree that has
it for local iteration).

## Configure

Add an optional `integrations` block next to `policy` / `plugins`:

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

| Field | Meaning |
| ----- | ------- |
| `chatkitHubUrl` | Absolute ChatKit / Claw hub base URL (HTTPS). Seeded into Settings as the gateway URL. |
| `finSkillsHubUrl` | Absolute FinSkills hub URL (HTTPS). May include a path (e.g. `/client`). |
| `hubUrlsLocked` | `false` (default): seed once on first boot; users may still change URLs. `true`: org-managed — pack values win at read time; Integration UI is read-only. |

Omit the whole `integrations` block to keep first-party behavior (users configure hubs themselves).

### URL rules

- Must be absolute `https://…`
- `http://localhost` / `http://127.0.0.1` allowed for local packs only
- Empty strings are rejected by `bun run doctor`

## Apply

```bash
bun run doctor        # validates integrations URLs when present
bun run materialize   # should print chatkitHub / finskills lines
bun run dist -- …     # materialize runs first; brand embeds the URLs
```

On first boot of a fresh user profile, the app **seeds** unset hub keys from the
brand descriptor. Existing user settings are not overwritten (`seed-once`).
With `hubUrlsLocked: true`, the pack values always win regardless of what is
stored in Settings.

## Checklist

- [ ] `integrations.chatkitHubUrl` / `finSkillsHubUrl` are the hubs you intend to ship
- [ ] `hubUrlsLocked` matches your compliance posture (`true` for regulated SKUs)
- [ ] `bun run doctor` is clean
- [ ] `bun run materialize` prints the expected hub lines
- [ ] Fresh install → Settings → Integrations shows the seeded URLs
- [ ] Locked mode: fields disabled + “Managed by your organization” (or locale equivalent)

## Troubleshooting

| Symptom | Likely cause |
| ------- | ------------ |
| Doctor errors on URL | Not absolute HTTPS (or non-localhost HTTP) |
| Materialize prints `hubs: (user-configured — no pack integrations)` | Block missing / empty, or SDK predates 0024 |
| Packaged app still empty hubs | Stale install without rematerialize/dist; or SDK pin without 0024 |
| User overrides ignored | `hubUrlsLocked: true` — expected |
| User overrides lost after upgrade | Should not happen with `hubUrlsLocked: false` (seed-once); file a bug if they do |

## Example (FDE-style)

```json
"integrations": {
  "chatkitHubUrl": "https://clawtest.finogeeks.club",
  "finSkillsHubUrl": "https://skillhub.finogeeks.club/client",
  "hubUrlsLocked": false
}
```
