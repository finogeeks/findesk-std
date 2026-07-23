#!/usr/bin/env bash
# Shared helpers for white-label distribution repos (Proposal 0014).
# Resolves the desktop SDK from findesk.lock.json artifact pins — sibling
# findesk / findesk-core checkouts are NOT required.
#
# Keep behavior aligned with scripts/findesk/platformLock.ts (token auth,
# fixed pins, https-only unless FINDESK_ALLOW_INSECURE_HTTP=1).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$ROOT/findesk.lock.json"

# Bootstrap resolver used before the platform CLI is available on disk.
_resolve_platform_via_python() {
  python3 - "$LOCK" "$ROOT" <<'PY'
import hashlib, json, os, shutil, subprocess, sys, urllib.request
from pathlib import Path

lock_path = Path(sys.argv[1]).resolve()
dist_root = Path(sys.argv[2]).resolve()
lock = json.loads(lock_path.read_text())
pin = lock.get("findesk") or {}

def reject_floating(label: str, value) -> None:
    if value is None or value == "":
        return
    s = str(value).strip()
    if s == "*" or s.lower() == "latest" or "*" in s:
        sys.stderr.write(f"error: floating pin rejected for {label}: {value}\n")
        sys.exit(1)

reject_floating("findesk.version", pin.get("version"))
reject_floating("findesk.artifact", pin.get("artifact"))
reject_floating("findesk.path", pin.get("path"))

env_plat = os.environ.get("FINDESK_PLATFORM", "").strip()
if env_plat:
    root = Path(env_plat).expanduser().resolve()
    if not (root / "package.json").is_file():
        sys.stderr.write(f"error: FINDESK_PLATFORM has no package.json: {root}\n")
        sys.exit(1)
    print(root)
    sys.exit(0)

artifact = pin.get("artifact")
integrity = pin.get("integrity")
legacy_path = pin.get("path")

def download_url(url: str, dest: Path) -> None:
    if url.startswith("http://"):
        allow = os.environ.get("FINDESK_ALLOW_INSECURE_HTTP", "").strip().lower() in ("1", "true")
        if not allow:
            sys.stderr.write(
                "error: insecure http:// artifact rejected "
                "(use https:// or set FINDESK_ALLOW_INSECURE_HTTP=1)\n"
            )
            sys.exit(1)
    elif not url.startswith("https://"):
        sys.stderr.write(f"error: unsupported artifact URL scheme: {url}\n")
        sys.exit(1)

    token = os.environ.get("FINDESK_ARTIFACT_TOKEN", "").strip()
    # Prefer curl so Bearer auth matches platformLock.ts.
    curl_cmd = ["curl", "-fsSL", url, "-o", str(dest)]
    if token:
        curl_cmd = ["curl", "-fsSL", "-H", f"Authorization: Bearer {token}", url, "-o", str(dest)]
    try:
        subprocess.check_call(curl_cmd)
        return
    except FileNotFoundError:
        pass
    except subprocess.CalledProcessError as exc:
        hint = "" if token else " (set FINDESK_ARTIFACT_TOKEN if the URL requires auth)"
        sys.stderr.write(f"error: failed to download platform artifact: {url}{hint}\n")
        sys.exit(exc.returncode or 1)

    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp, open(dest, "wb") as out:
            shutil.copyfileobj(resp, out)
    except Exception as exc:  # noqa: BLE001 — surface download errors to operators
        hint = "" if token else " (set FINDESK_ARTIFACT_TOKEN if the URL requires auth)"
        sys.stderr.write(f"error: failed to download platform artifact: {url}{hint}\n{exc}\n")
        sys.exit(1)

if artifact:
    if not integrity or not str(integrity).startswith("sha256-"):
        sys.stderr.write("error: findesk.integrity (sha256-<hex>) required with findesk.artifact\n")
        sys.exit(1)
    expected = integrity.split("sha256-", 1)[1].lower()
    if len(expected) != 64 or any(c not in "0123456789abcdef" for c in expected):
        sys.stderr.write(f"error: unsupported integrity (want sha256-<64 hex>): {integrity}\n")
        sys.exit(1)
    cache_root = Path(os.environ.get("FINDESK_PLATFORM_CACHE") or (Path.home() / ".cache/findesk/platforms"))
    version_key = (pin.get("version") or expected[:12])
    version_key = "".join(c if (c.isalnum() or c in "._-") else "_" for c in str(version_key))
    cache_dir = cache_root / version_key
    stamp = cache_dir / ".integrity"
    src = cache_dir / "src"
    pkg = None
    if stamp.is_file() and stamp.read_text().strip() == expected:
        if (src / "package.json").is_file():
            pkg = src
        else:
            for child in src.iterdir() if src.is_dir() else []:
                if (child / "package.json").is_file():
                    pkg = child
                    break
    if pkg is None:
        cache_dir.mkdir(parents=True, exist_ok=True)
        archive = cache_dir / "platform.tar.gz"
        if artifact.startswith("http://") or artifact.startswith("https://"):
            download_url(artifact, archive)
        else:
            src_path = Path(artifact[7:] if artifact.startswith("file://") else artifact)
            if not src_path.is_absolute():
                src_path = (dist_root / src_path).resolve()
            if not src_path.is_file():
                sys.stderr.write(f"error: platform artifact not found: {src_path}\n")
                sys.exit(1)
            shutil.copy2(src_path, archive)
        h = hashlib.sha256()
        with open(archive, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                h.update(chunk)
        actual = h.hexdigest()
        if actual != expected:
            archive.unlink(missing_ok=True)
            sys.stderr.write(f"error: integrity mismatch\n  want {expected}\n  got  {actual}\n")
            sys.exit(1)
        if src.exists():
            shutil.rmtree(src)
        src.mkdir(parents=True)
        subprocess.check_call(["tar", "-xzf", str(archive), "-C", str(src)])
        stamp.write_text(expected + "\n")
        pkg = src if (src / "package.json").is_file() else None
        if pkg is None:
            for child in src.iterdir():
                if (child / "package.json").is_file():
                    pkg = child
                    break
    if pkg is None:
        sys.stderr.write("error: extracted platform has no package.json\n")
        sys.exit(1)
    if not (pkg / "node_modules").is_dir():
        sys.stderr.write(f"⋯ Installing platform deps in {pkg} (one-time)…\n")
        subprocess.check_call(["bun", "install"], cwd=str(pkg), stdout=sys.stderr)
    print(pkg.resolve())
    sys.exit(0)

if legacy_path:
    root = Path(legacy_path)
    if not root.is_absolute():
        root = (dist_root / root).resolve()
    else:
        root = root.resolve()
    if not (root / "package.json").is_file():
        sys.stderr.write(f"error: findesk.path has no package.json: {root}\n")
        sys.exit(1)
    print(root)
    sys.exit(0)

sys.stderr.write(
    "error: findesk.lock.json needs findesk.artifact+integrity (or FINDESK_PLATFORM).\n"
    "See white-label-distribution-developer-guide.md\n"
)
sys.exit(1)
PY
}

resolve_platform() {
  if [[ -n "${FINDESK_PLATFORM:-}" && -f "${FINDESK_PLATFORM}/package.json" ]]; then
    echo "$(cd "$FINDESK_PLATFORM" && pwd)"
    return
  fi
  _resolve_platform_via_python
}

DIST_ID="${FINDESK_DISTRIBUTION_ID:-}"
if [[ -z "$DIST_ID" ]]; then
  DIST_ID="$(python3 -c "import json; print(json.load(open('$ROOT/catalog.json'))['tenants'][0]['distributions'][0])")"
fi

export FINDESK_DIST_REPO="$ROOT"
export FINDESK_DISTRIBUTION_ID="$DIST_ID"
export FINDESK_WHITE_LABEL=1
# Customers must not need findesk-core source; prepared binaries only unless overridden.
export AIONCORE_PREFER_LOCAL="${AIONCORE_PREFER_LOCAL:-0}"
PLATFORM="$(resolve_platform)"
export FINDESK_PLATFORM="$PLATFORM"
