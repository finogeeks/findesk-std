---
name: create-distribution
description: |
  Scaffold a new FinDesk white-label distribution repo from the public
  finogeeks/findesk-std template (degit + init-identity). Use when creating a
  customer/FDE distro repo without Geeksfino/findesk, or when the user asks how
  to start from findesk-std.
---

# Create a FinDesk distribution repo (public)

You do **not** need `Geeksfino/findesk` or `findesk-core` source. Use the public
template on [`finogeeks/findesk-std`](https://github.com/finogeeks/findesk-std).

## Steps

1. **Scaffold**

```bash
npx degit finogeeks/findesk-std/template findesk-dist-<owner>
cd findesk-dist-<owner>
```

2. **Identity** (required once)

```bash
bash scripts/init-identity.sh \
  --tenant-id <tenant-id> \
  --distribution-id <distribution-id> \
  --config-home <slug> \
  --app-id <reverse.dns> \
  --product-name "<Product Name>" \
  [--shell findesk-classic]
```

3. **Pin SDK** — edit `findesk.lock.json` from the matching Release
   `.lock.snippet.json` (online HTTPS) or drop a tarball under `artifacts/`
   (offline). See `docs/lock-examples.md`.

4. **Brand** — replace `pack/assets/logo.png` (and optional app icons).

5. **Validate**

```bash
bun run doctor
bun run materialize
bun run start
```

## After create

Switch to skills inside the new repo:

| Skill | Use when |
| ----- | -------- |
| `dist-packaging` | Doctor, materialize, start, installers |
| `dist-private-plugin` | Author `@findesk-private/*` under `plugins/` |

## Internal equivalent

With a FinDesk monorepo checkout:

```bash
bun run findesk new-distribution-repo ../findesk-dist-<owner> \
  --tenant-id … --distribution-id … --config-home … --app-id … --product-name …
```

Same template + `init-identity.sh` writer.

## Hard rules

1. Never tell partners to clone `Geeksfino/findesk` for day-to-day packaging.
2. Never skip `init-identity.sh` after degit (tree has no `catalog.json` until then).
3. Integrity on the lock pin must match the published digest.
