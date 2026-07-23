#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"
cd "$PLATFORM"
exec bun run findesk doctor --tenant-pack "$DIST_ID" --catalog "$ROOT"
