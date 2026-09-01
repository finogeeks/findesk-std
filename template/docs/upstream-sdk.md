# Upstream SDK (findesk-std)

This distribution **pins** a published desktop SDK from
[`finogeeks/findesk-std`](https://github.com/finogeeks/findesk-std). Treat that
repo as **upstream**: monitor releases, open an issue when ahead of
`findesk.lock.json`, then bump the lock when you choose to cut over.

## Daily watch (GitHub Actions)

Workflow: [`.github/workflows/findesk-std-upstream-watch.yml`](../.github/workflows/findesk-std-upstream-watch.yml)

| | |
| --- | --- |
| Schedule | `0 2 * * *` (02:00 UTC daily) |
| Manual | Actions → **findesk-std upstream watch** → Run workflow |
| Dry run | `dry_run=true` (no issue create/comment) |
| Local | `bash scripts/watch-findesk-std.sh` / `--dry-run` |

When the latest non-draft release is **newer** than `findesk.version` in
`findesk.lock.json`, the job opens (or comments on) an issue labeled
`upstream:findesk-std` with an upgrade checklist. It does **not** change the
lock or download the tarball.

Permissions: `issues: write` (default `GITHUB_TOKEN`). Reading public
findesk-std releases needs no extra secret.

## After an issue opens

Follow the issue checklist (lock snippet → `findesk.lock.json` → harvest
`template/docs/` + skills if they changed → doctor → materialize → dist).
The SDK tarball does **not** include distro how-tos; copy them from
[`finogeeks/findesk-std` `template/`](https://github.com/finogeeks/findesk-std/tree/main/template)
when the release notes mention new docs. Do not overwrite distro-only pages.
Skills: [`dist-packaging`](../.claude/skills/dist-packaging/SKILL.md).

## Disable

Delete or disable the workflow in the GitHub Actions UI, or remove
`.github/workflows/findesk-std-upstream-watch.yml` from this repo.
