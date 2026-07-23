#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
cd "$PLATFORM"
# Brand descriptor must exist before Vite define (__FINDESK_BRAND__) — same as start.sh.
bun run findesk materialize "$DIST_ID" --catalog "$ROOT"
# Forward args to platform dist (e.g. --mac --arm64 --pack-only)
exec bun run dist --distribution "$DIST_ID" "$@"
