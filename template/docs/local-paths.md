# Local paths (developer machine)

Where files land when you develop and package from this distribution repo.

## Source (this repo)

```text
<dist-repo>/
├── pack/                 # brand + tenant + distribution SKU
├── plugins/              # private plugin source
├── artifacts/            # optional offline SDK tarball
└── findesk.lock.json     # pin
```

## SDK resolve / build cache

Default cache root: `~/.cache/findesk/platforms/<version-key>/`

| Path | Role |
| ---- | ---- |
| `…/src/findesk-desktop-sdk-*/` | Extracted desktop SDK (one-time `bun install`) |
| `…/packages/desktop/.materialized/<id>.brand.json` | Brand descriptor from `materialize` |
| `…/packages/desktop/.materialized/<id>.electron-builder.json` | Installer identity overlay (`appId`, product name, …) |
| `…/out/<Product>.app` (or platform equivalent) | Packaged app |
| `…/out/*-<distribution-id>-*.dmg` | Installer artifacts |

Override cache with `FINDESK_PLATFORM_CACHE`, or point at an extract with `FINDESK_PLATFORM`.

## Runtime (after launching the app)

White-label builds are **full apps**: Electron `userData` is scoped by the pack’s
`productNameEn` / `executableName` and `appId` (not under FinDesk).

| Path | Role |
| ---- | ---- |
| `~/.<configHome>` | CLI-safe symlink → Application Support / AppData product folder |
| `~/Library/Application Support/<Product>/` (macOS) | Electron userData + backend DB / runtimes |
| `~/Library/Logs/<Product>/` | Main + aioncore logs |

Example (Guosen): `configHome: guosen`, installer product name
`Guosen Securities AI Desk` → `~/Library/Application Support/Guosen Securities AI Desk/`
with `~/.guosen` pointing at that tree.

Dev (`bun run start`) uses `devAppName` (e.g. `GuosenAIDesk-Dev`).

## Not installed by default

Running `open …/out/…/*.app` does **not** copy into `/Applications`. Install from the DMG when you want a system-wide install.
