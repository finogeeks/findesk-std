# Packaging installers

## Why `materialize` is required before `dist`

Vite inlines `__FINDESK_BRAND__` from:

`packages/desktop/.materialized/<distribution-id>.brand.json`

inside the **resolved SDK** tree. If that file is missing, the packaged app still
embeds `VITE_FINDESK_FLAVOR=<your-id>` but cannot boot a private distribution id
that is not in the static SKU registry — runtime error:

```text
Unknown distribution: "<id>". Known: consumer-hk, findesk-classic, opc-advisory
```

`scripts/dist.sh` runs `materialize` automatically. Prefer that path over calling
the platform `dist` binary by hand.

## Commands

```bash
bun run materialize
bun run dist -- --mac --arm64 --pack-only   # Vite package smoke (faster)
bun run dist -- --mac --arm64               # DMG / zip (needs local signing setup for release)
# After a real dist, publish the electron-updater feed (proposal 0032):
# bun run publish:online-update -- --out-dir "$FINDESK_PLATFORM/out" --dry-run
```

Online-update publish (GitHub / S3 / rsync / file) is documented in [update-feed.md](./update-feed.md).

Pass-through args after `--` go to the platform builder (`--win`, `--linux`, arch flags, etc.).

## Outputs

Under the resolved SDK (see [local-paths.md](./local-paths.md)):

```text
out/mac-arm64/<App>.app
out/<Product>-<distribution-id>-<version>-mac-arm64.dmg
out/<Product>-<distribution-id>-<version>-mac-arm64.zip
```

Exact product / executable names come from the pack + SDK electron-builder config.

## Checklist

- [ ] `findesk.lock.json` has matching `artifact` + `integrity`
- [ ] `bun run doctor` succeeds without FinDesk source nearby
- [ ] `bun run dist` completes (materialize runs first)
- [ ] Window title / `configHome` match `pack/tenant.json`
- [ ] Hub URLs (if set): `materialize` prints `chatkitHub` / `finskills` — see [hub-urls.md](./hub-urls.md)
- [ ] Telemetry (if set): `doctor` accepts DSN; staging smoke in your Sentry — see [telemetry.md](./telemetry.md)
- [ ] Packaged Dock / taskbar icon + name match brand (not Electron / FinDesk defaults)
- [ ] Private plugins listed in `plugins.enable` / `plugins.private` appear after boot

## Installer icons

Optional in `pack/tenant.json` → `brand.assets`: `macIcon`, `windowsIcon`, `linuxIcon`.
When omitted, `materialize` synthesizes from `logo` into `.materialized/<id>/icons/`.
Prefer dedicated square icons for production shipping.

## Troubleshooting

| Symptom | Likely cause |
| ------- | ------------ |
| `Unknown distribution` | Dist without materialize / missing `.brand.json` |
| Integrity mismatch | Wrong tarball or digest in the lock |
| `aioncore binary not found` / curl 404 on Geeksfino/findesk-core | SDK bake missing for that arch, wrong `FINDESK_PLATFORM`, or corrupt `~/.cache/findesk/platforms/<version>` — see checklist below. Customers should **not** need Geeksfino `GH_TOKEN` for a normal findesk-std pin. |
| `finsafe binary not configured` / sandbox unavailable / LLM provider config fails via FinSAFE refuse | findesk-std **< 2.1.26** omitted `bundled-finsafe` / `bundled-finclaw`. Bump lock to ≥ 2.1.26, or for local iteration use `FINDESK_PLATFORM=<findesk monorepo>` after `bun run prepare:findesk`. See skill `dist-packaging`. |
| Wants Geeksfino `GH_TOKEN` | Overriding backend version away from the SDK-baked pin, or pinning a private URL without `FINDESK_ARTIFACT_TOKEN` |
| Plugin missing in UI | Id not in `pack/tenant.json` `plugins.enable`, or package missing `findesk.pluginId` |

### aioncore / private-repo 404 during `dist`

findesk-std SDKs already ship `resources/bundled-aioncore/<platform-arch>/`. `dist` reuses that tree; it only hits GitHub when reuse fails.

1. Confirm the resolved platform is the **SDK extract**, not a FinDesk monorepo:
   ```bash
   # scripts/lib.sh sets FINDESK_PLATFORM — or:
   echo "$FINDESK_PLATFORM"
   test -f "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-arm64/aioncore"
   ```
2. For the arch you are packaging (`--mac --x64` → `darwin-x64`, `--mac --arm64` → `darwin-arm64`), check:
   ```bash
   ls "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-x64/"
   # expect: aioncore  manifest.json  (managed-resources optional on foreign arch)
   cat "$FINDESK_PLATFORM/resources/bundled-aioncore/darwin-x64/manifest.json"
   # version must match package.json aioncoreVersion / findesk.lock findeskCore.version
   ```
3. If missing or wrong version, clear the pin cache and re-resolve from `findesk.lock.json`:
   ```bash
   unset FINDESK_PLATFORM
   rm -rf ~/.cache/findesk/platforms/<sdk-version>
   bun run doctor
   ```
4. Prefer native arch when possible (`--mac --arm64` on Apple Silicon). Cross-arch (`--x64` on arm64) still works when the SDK bake for that arch is present.
5. Only FinDesk engineers with access to private `Geeksfino/findesk-core` should set `GH_TOKEN` and use the `gh` CLI to force-download; browser `curl` URLs return 404 for private assets even with a token.
