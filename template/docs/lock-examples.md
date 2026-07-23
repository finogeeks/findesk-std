# Dual-mode platform pin examples (0014 §6)
#
# Offline (air-gap): place the tarball under artifacts/ and use a relative path.
# Online: pin the public findesk-std release URL (same bytes + integrity).

## Offline — findesk.lock.json

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.16",
    "artifact": "artifacts/findesk-desktop-sdk-2.1.16.tar.gz",
    "integrity": "sha256-REPLACE_WITH_DIGEST"
  }
}
```

## Online — findesk.lock.json

```json
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "2.1.16",
    "artifact": "https://github.com/finogeeks/findesk-std/releases/download/v2.1.16/findesk-desktop-sdk-2.1.16.tar.gz",
    "integrity": "sha256-REPLACE_WITH_DIGEST"
  }
}
```

Copy `integrity` from the matching `.lock.snippet.json` or `.sha256` asset on the release.
