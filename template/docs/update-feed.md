# Online update feed

[English](./update-feed.md) | [中文](./update-feed.zh-CN.md)

Clients read `release.onlineUpdate` (proposal 0027). CI writes through
`release.publish` and a pluggable adapter (proposal 0032). Distro authors
configure those two blocks; they do not implement upload logic.

## Pack configuration

`pack/tenant.json`:

```json
"release": {
  "channel": "stable",
  "onlineUpdate": {
    "feedUrl": "https://updates.example.com/mydistro"
  },
  "publish": {
    "adapter": "s3",
    "bucket": "example-updates",
    "prefix": "mydistro",
    "endpoint": "https://oss-cn-hangzhou.aliyuncs.com",
    "region": "cn-hangzhou"
  }
}
```

| Field | Role |
| ----- | ---- |
| `channel` | `stable` / `beta` enable the updater; `internal` / `none` disable it. |
| `onlineUpdate.githubRepo` | Public `owner/repo` for GitHub Releases (read + default github adapter). |
| `onlineUpdate.feedUrl` | Generic HTTPS origin. Wins over `githubRepo` when both are set. |
| `publish.adapter` | `github` / `s3` / `rsync` / `file` / `external`. |
| `publish.originReachability` | `public` (default) or `internal`. Only changes signature-gate strength. |

Do not put secrets in the pack. Adapter credentials are env-only:

| Adapter | Env |
| ------- | --- |
| `github` | `GH_TOKEN` |
| `s3` | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / optional `AWS_SESSION_TOKEN` (OIDC preferred on AWS) |
| `rsync` | `RSYNC_SSH_KEY` or ssh-agent |
| `file` | none (local/mounted path) |
| `external` | none — SDK skips upload; you run your own pipeline |

`feedUrl` + `adapter: "github"` is rejected (`feed-adapter-mismatch`). GitHub-only distros omit `feedUrl`.

Scaffold with `init-identity.sh --update-origin github|generic|external`.

## SDK pin

`findesk.lock.json` must point at findesk-std **≥ 2.1.41** (proposal 0032
`--publish`). Older pins still prepare a GitHub feed list (0027) but cannot
dispatch adapters.

```bash
bun run findesk:doctor   # or: bun run doctor
```

`doctor` checks the declaration only (no credentials). `--probe` HEADs a
`feedUrl` layout and is skipped for github-only packs.

## Publish

After `bun run dist`:

```bash
# Plan JSON only (no upload). Compare remoteRelPath with the layout table.
bun run publish:online-update -- --out-dir "$FINDESK_PLATFORM/out" --dry-run

bun run publish:online-update -- --out-dir "$FINDESK_PLATFORM/out"
```

The thin script calls the SDK helper with `--publish` and must run from the
distribution repo root (it does not `cd` into the SDK).

Generic layout (`s3` / `rsync` / `file`):

```text
<root>/<channel>/<platform-arch>/latest*.yml
<root>/<channel>/<platform-arch>/<version>/<installer>
```

GitHub layout is flat under the release tag (0027).

Channel files the runtime will GET:

| Client | Channel file |
| ------ | ------------ |
| macOS arm64 | `latest-arm64-mac.yml` (also upload identical `latest-mac.yml`) |
| macOS x64 | `latest-mac.yml` |
| Windows x64 | `latest.yml` |
| Windows arm64 | `latest-win-arm64.yml` |
| Linux x64 | `latest-linux.yml` |
| Linux arm64 | `latest-linux-arm64.yml` |

## Smoke

Discovery and download are the v1 gates. Signed install / restart is required
for `channel: stable` on a public origin (0027 G-SIGN). Unsigned CI must not
claim a production upgrade loop.

1. Publish two sequential versions to the configured origin.
2. Install the older build on a clean machine.
3. Help → Check for Updates → confirm discover + download.
4. Record signed install separately when certificates are in place.

## Related

- [packaging.md](./packaging.md) — materialize + installer builds
- [upstream-sdk.md](./upstream-sdk.md) — findesk-std pin bumps
- FinDesk proposal 0027 — feed contract (channel files + artifact names)
- FinDesk proposal 0032 — generic origin + publish adapters
