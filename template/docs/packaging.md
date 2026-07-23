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
```

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
| Wants Geeksfino `GH_TOKEN` | Overriding backend version away from the SDK-baked pin, or pinning a private URL without `FINDESK_ARTIFACT_TOKEN` |
| Plugin missing in UI | Id not in `pack/tenant.json` `plugins.enable`, or package missing `findesk.pluginId` |
