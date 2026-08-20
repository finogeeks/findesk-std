#!/usr/bin/env bash
# Publish electron-builder installers + latest*.yml through the SDK adapter
# (Proposal 0032). Distros do not implement channel tables or upload logic.
#
# Reads pack/tenant.json from the distribution repo root (cwd). Do not cd into
# the SDK — pack resolution is a cwd contract (0032 §4.5.1).
#
# Usage (from the distro repo root):
#   bun run publish:online-update -- --out-dir <dir> [--platform darwin|win32|linux] \
#     [--arch arm64|x64] [--dry-run] [--sdk-root <findesk>]
#
# Credentials (env only, never pack):
#   github  → GH_TOKEN
#   s3      → AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / optional AWS_SESSION_TOKEN
#   rsync   → RSYNC_SSH_KEY or ssh-agent
#
# Requires findesk-std ≥ 2.1.41 (publishOnlineUpdate.ts --publish).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR=""
SDK_ROOT="${FINDESK_PLATFORM:-${PLATFORM_DIR:-}}"
UPDATE_PLATFORM=""
UPDATE_ARCH=""
DRY_RUN=0

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) OUT_DIR="${2:-}"; shift 2 ;;
    --sdk-root) SDK_ROOT="${2:-}"; shift 2 ;;
    --platform) UPDATE_PLATFORM="${2:-}"; shift 2 ;;
    --arch) UPDATE_ARCH="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown arg: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "$OUT_DIR" || ! -d "$OUT_DIR" ]]; then
  echo "error: --out-dir must be an existing directory (electron-builder out/)" >&2
  exit 1
fi
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

if [[ ! -f "$ROOT/pack/tenant.json" ]]; then
  echo "error: $ROOT/pack/tenant.json not found; run from the distribution repo" >&2
  exit 1
fi

if [[ -n "$SDK_ROOT" ]]; then
  export FINDESK_PLATFORM="$(cd "$SDK_ROOT" && pwd)"
fi

# Resolve SDK; do not cd into it.
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"
SDK_ROOT="$PLATFORM"

HELPER="$SDK_ROOT/packages/desktop/scripts/findesk/publishOnlineUpdate.ts"
if [[ ! -f "$HELPER" ]]; then
  echo "error: SDK is missing $HELPER" >&2
  echo "Pin findesk.lock.json to findesk-std ≥ 2.1.41 (proposal 0032)." >&2
  exit 1
fi

if ! bun "$HELPER" --help 2>/dev/null | grep -q -- '--publish'; then
  echo "error: SDK helper does not support --publish." >&2
  echo "Pin findesk.lock.json to findesk-std ≥ 2.1.41 (proposal 0032)." >&2
  exit 1
fi

HELPER_ARGS=(--out-dir "$OUT_DIR" --publish --pack "$ROOT/pack/tenant.json")
if [[ -n "$UPDATE_PLATFORM" ]]; then
  HELPER_ARGS+=(--platform "$UPDATE_PLATFORM")
fi
if [[ -n "$UPDATE_ARCH" ]]; then
  HELPER_ARGS+=(--arch "$UPDATE_ARCH")
fi
if [[ "$DRY_RUN" -eq 1 ]]; then
  HELPER_ARGS+=(--dry-run)
fi

# Stay in the distro repo so pack resolution cannot pick up SDK brand data.
cd "$ROOT"
exec bun "$HELPER" "${HELPER_ARGS[@]}"
