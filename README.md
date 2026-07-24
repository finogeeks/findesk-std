# findesk-std

Public **FinDesk desktop packaging SDK** artifacts for white-label **distribution repositories**.

This repository holds **GitHub Release assets**, a **distribution-repo template**, and short
operator notes. It does **not** contain FinDesk application source.

| | |
| --- | --- |
| **Private product source** | FinDesk platform (not published here) |
| **Public SDK intake** | **This repo** — `finogeeks/findesk-std` |

## Create a distribution repo

Scaffold from the published template (no FinDesk monorepo required):

```bash
npx degit finogeeks/findesk-std/template findesk-dist-acme
cd findesk-dist-acme
bash scripts/init-identity.sh \
  --tenant-id acme \
  --distribution-id acme-advisory-cn \
  --config-home acme \
  --app-id com.acme.desk \
  --product-name "Acme Desk"
```

Then pin the desktop SDK (below), replace `pack/assets/`, and run:

```bash
bun run doctor
bun run materialize
bun run start
```

Template docs live under [`template/docs/`](./template/docs/). Agent skills after scaffold:
`dist-packaging`, `dist-private-plugin` (see `template/AGENTS.md`).

FinDesk engineers with a private checkout can use the equivalent:

`bun run findesk new-distribution-repo …` (same template + `init-identity.sh`).

## What you get (Releases)

Each [GitHub Release](https://github.com/finogeeks/findesk-std/releases) tagged `v<semver>` typically includes:

| Asset | Purpose |
| ----- | ------- |
| `findesk-desktop-sdk-<semver>.tar.gz` | Relocatable packaging SDK (Electron app sources, first-party plugins/shells, `findesk` CLI, packaging scripts) |
| `findesk-desktop-sdk-<semver>.sha256` | Digest file (`<hex>  <filename>`) |
| `findesk-desktop-sdk-<semver>.lock.snippet.json` | Fields to copy into a distribution repo’s `findesk.lock.json` |
| `findesk-desktop-sdk-<semver>.manifest.json` | Build metadata (`gitSha`, `aioncoreVersion`, …) |
| `SHA256SUMS` | Release-wide checksums |

Runtime binaries for published desktop triples are **baked into the SDK** under
`resources/bundled-aioncore/` and `resources/bundled-findesk-services/` (see the
release manifest). Remaining prepare-time fetches are handled by the SDK tooling —
you do not need separate product checkouts.

## Pin from a distribution repo (online)

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.19",
    "artifact": "https://github.com/finogeeks/findesk-std/releases/download/v2.1.19/findesk-desktop-sdk-2.1.19.tar.gz",
    "integrity": "sha256-<64-hex-chars>"
  }
}
```

Copy `integrity` from the matching `.lock.snippet.json` or `.sha256` asset (prefix with `sha256-`).

## Offline / air-gapped

Download the same `.tar.gz` once, place it under `artifacts/` in the distribution repo, and pin a
**relative** path instead of the HTTPS URL. Integrity must still match.

## License / access

Release archives are published for FinDesk white-label partners and operators. Product source and
commercial terms remain with FinoGeeks / your distribution agreement — this repo is an **artifact
channel**, not an open-source monorepo mirror.
