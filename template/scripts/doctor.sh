#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib.sh
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Private plugin sources live in this repo and import `@findesk/sdk` + UI peers
# that are installed only inside the extracted SDK tree.
mkdir -p "$ROOT/node_modules/@findesk" "$ROOT/node_modules/@arco-design" "$ROOT/node_modules/@icon-park"
ln -sfn "$PLATFORM/packages/sdk" "$ROOT/node_modules/@findesk/sdk"
for peer in react react-dom react-i18next react-router-dom i18next; do
  if [[ -e "$PLATFORM/node_modules/$peer" ]]; then
    ln -sfn "$PLATFORM/node_modules/$peer" "$ROOT/node_modules/$peer"
  fi
done
if [[ -e "$PLATFORM/node_modules/@arco-design/web-react" ]]; then
  ln -sfn "$PLATFORM/node_modules/@arco-design/web-react" "$ROOT/node_modules/@arco-design/web-react"
fi
if [[ -e "$PLATFORM/node_modules/@icon-park/react" ]]; then
  ln -sfn "$PLATFORM/node_modules/@icon-park/react" "$ROOT/node_modules/@icon-park/react"
fi

cd "$PLATFORM"
exec bun run findesk doctor --tenant-pack "$DIST_ID" --catalog "$ROOT"
