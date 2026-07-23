#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
cd "$PLATFORM"
bun run findesk materialize "$DIST_ID" --catalog "$ROOT"
export FINDESK_DIST_REPO="$ROOT"
exec bun run findesk start "$DIST_ID" --catalog "$ROOT" "$@"
