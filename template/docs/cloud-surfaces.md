# Cloud surfaces (`policy.cloudSurfaces`)

**English** | [中文](./cloud-surfaces.zh-CN.md)

Control whether this distribution exposes **ChatKit Hub login**, **cloud FinClaw**,
**Hub skill catalog**, and **Hub LLM**. Requires a desktop SDK that includes the
`policy.cloudSurfaces` pack field.

| Value | Result |
| ----- | ------ |
| omit / `"on"` | First-party behavior: login wall + Hub surfaces |
| `"off"` | Pure-base SKU: no Hub bootstrap, no cloud FinClaw, no skill market; models are Settings BYOK / private LLM only |

**Do not** set `"off"` together with `integrations.chatkitHubUrl`,
`integrations.finSkillsHubUrl`, or `integrations.hubUrlsLocked: true`.
`bun run doctor` rejects that combination.

## Pure-base pack

Omit the entire `integrations` block and set:

```json
"policy": {
  "allowedTrustZones": ["on-device", "private-cloud"],
  "defaultTrustZone": "on-device",
  "locale": "zh-CN",
  "cloudSurfaces": "off"
}
```

Until a findesk-std release ships this field, point `FINDESK_PLATFORM` at a
FinDesk tree that contains it (sibling checkout) when running `doctor` /
`materialize` / `start`.

See also [hub-urls.md](./hub-urls.md).
