# {{REPO_NAME}}

White-label FinDesk distribution for **{{PRODUCT_NAME}}**.

You do **not** need FinDesk or findesk-core source trees. Pin a published
`findesk-desktop-sdk` artifact, develop brand + private plugins here, then
`start` / `dist`.

## Quick start

If this tree came from `npx degit finogeeks/findesk-std/template` and you have not
set identity yet:

```bash
bash scripts/init-identity.sh \
  --tenant-id <id> --distribution-id <id> --config-home <slug> \
  --app-id <reverse.dns> --product-name "<name>"
```

Then:

1. Pin the desktop SDK in `findesk.lock.json` (see [docs/getting-started.md](docs/getting-started.md) and [docs/lock-examples.md](docs/lock-examples.md)).
2. Replace brand assets under `pack/assets/` and edit `pack/tenant.json` if needed.
3. Run:

```bash
bun run doctor
bun run materialize
bun run start
bun run dist -- --mac --arm64          # full installer (or --pack-only for smoke)
```

## Documentation (this repo)

| Doc | Topic |
| --- | ----- |
| [docs/getting-started.md](docs/getting-started.md) | Lock pin, doctor, first run |
| [docs/packaging.md](docs/packaging.md) | `materialize` / `dist`, signing, installers |
| [docs/private-plugins.md](docs/private-plugins.md) | Author private plugins under `plugins/` |
| [docs/local-paths.md](docs/local-paths.md) | Where SDK cache, app, and user data land |

## Agent skills (Cursor / Claude)

| Skill | Use when |
| ----- | -------- |
| [`dist-packaging`](.claude/skills/dist-packaging/SKILL.md) | Doctor, materialize, start, package installers |
| [`dist-private-plugin`](.claude/skills/dist-private-plugin/SKILL.md) | Scaffold / wire a private plugin |

See [AGENTS.md](AGENTS.md) for routing.

## Layout

```text
{{REPO_NAME}}/
├── catalog.json
├── findesk.lock.json
├── pack/                 # brand, identity, distribution SKU
├── plugins/              # optional @findesk-private/* plugins
├── artifacts/            # optional offline SDK tarball
├── scripts/              # doctor / materialize / start / dist
├── docs/                 # public developer docs
└── .claude/skills/       # agent skills (Cursor: .cursor/skills → symlink)
```

Distribution id: `{{DISTRIBUTION_ID}}` · Tenant: `{{TENANT_ID}}` · `configHome`: `~/.{{CONFIG_HOME}}`
