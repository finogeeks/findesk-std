# Getting started

Build and run this distribution **without** FinDesk or findesk-core source.

## Prerequisites

- macOS, Linux, or Windows with **Bun** installed
- A FinDesk **desktop SDK** tarball + `sha256-…` integrity (from FinDesk or
  [finogeeks/findesk-std](https://github.com/finogeeks/findesk-std) Releases)
- Identity files present (`catalog.json`, `pack/tenant.json`, …). After
  `degit finogeeks/findesk-std/template`, run `bash scripts/init-identity.sh …`
  once (see repo README).

You do **not** need a GitHub token for public `finogeeks/findesk-std` assets when
the lock integrity matches. Geeksfino org tokens are for FinDesk maintainers only.

## 1. Pin the SDK

Edit `findesk.lock.json`. Offline and online examples: [lock-examples.md](./lock-examples.md).

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.17",
    "artifact": "artifacts/findesk-desktop-sdk-2.1.17.tar.gz",
    "integrity": "sha256-<64-hex-chars>"
  }
}
```

`artifact` may be a path under this repo, `file://…`, or `https://…` only
(`http://` requires `FINDESK_ALLOW_INSECURE_HTTP=1`).

## 2. Brand the product

1. Replace `pack/assets/logo.png` (and favicon).
2. Optional but recommended for shipping: `assets/app.icns`, `assets/app.ico`, `assets/app.png`
   (or set `brand.assets.macIcon` / `windowsIcon` / `linuxIcon`). When omitted, `materialize`
   synthesizes installer icons from the logo.
3. Edit `pack/tenant.json` (`productName`, `appId`, `configHome`, locale, plugins).
4. Edit `pack/distributions/<id>.json` if the SKU id or shell baseline changes.

`configHome` isolates runtime data (e.g. `~/.acme`). Do not share it across products.

## 3. Validate and run

```bash
bun run doctor        # pack + lock + resolve SDK (extracts tarball once)
bun run materialize   # writes brand into the resolved SDK tree
bun run start         # Electron dev for this distribution
```

Scripts export `FINDESK_DIST_REPO` (this repo) and `FINDESK_WHITE_LABEL=1`.

## Optional env overrides

| Env | Meaning |
| --- | ------- |
| `FINDESK_PLATFORM` | Use an already-extracted SDK directory |
| `FINDESK_PLATFORM_CACHE` | Cache root (default `~/.cache/findesk/platforms`) |
| `FINDESK_ARTIFACT_TOKEN` | Bearer token for **private** HTTPS artifact URLs |
| `FINDESK_DISTRIBUTION_ID` | Override distribution id (default from `catalog.json`) |
| `AIONCORE_PREFER_LOCAL` | Leave `0` / unset for customers |

Next: [packaging.md](./packaging.md) · [private-plugins.md](./private-plugins.md).
