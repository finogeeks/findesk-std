#!/usr/bin/env bash
# Write identity stubs for a FinDesk white-label distribution repo (Proposal 0014).
# Used after degit from finogeeks/findesk-std/template, and by
# `bun run findesk new-distribution-repo` (single writer for identity files).
set -euo pipefail

REPO_DIR="."
TENANT_ID=""
DISTRIBUTION_ID=""
CONFIG_HOME=""
APP_ID=""
PRODUCT_NAME=""
SHELL_ID="findesk-classic"

usage() {
  cat >&2 <<'EOF'
Usage: bash scripts/init-identity.sh \
  --tenant-id <id> --distribution-id <id> --config-home <slug> \
  --app-id <reverse.dns> --product-name <name> \
  [--shell findesk-classic] [--repo-dir <path>]
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tenant-id) TENANT_ID="${2:-}"; shift 2 ;;
    --distribution-id) DISTRIBUTION_ID="${2:-}"; shift 2 ;;
    --config-home) CONFIG_HOME="${2:-}"; shift 2 ;;
    --app-id) APP_ID="${2:-}"; shift 2 ;;
    --product-name) PRODUCT_NAME="${2:-}"; shift 2 ;;
    --shell) SHELL_ID="${2:-}"; shift 2 ;;
    --repo-dir) REPO_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "error: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$TENANT_ID" || -z "$DISTRIBUTION_ID" || -z "$CONFIG_HOME" || -z "$APP_ID" || -z "$PRODUCT_NAME" ]]; then
  echo "error: tenant-id, distribution-id, config-home, app-id, and product-name are required" >&2
  usage
fi

REPO_DIR="$(cd "$REPO_DIR" && pwd)"
YEAR="$(date +%Y)"
REPO_NAME="$(basename "$REPO_DIR")"

# PascalCase-ish executable from configHome (acme-desk → AcmeDesk)
EXECUTABLE_NAME="$(
  printf '%s' "$CONFIG_HOME" | awk -F'-' '{
    out=""
    for (i=1; i<=NF; i++) {
      w=$i
      if (length(w)>0) {
        out = out toupper(substr(w,1,1)) substr(w,2)
      }
    }
    if (out=="") out="WhiteLabel"
    print out
  }'
)"

mkdir -p \
  "$REPO_DIR/pack/distributions" \
  "$REPO_DIR/pack/assets" \
  "$REPO_DIR/pack/theme" \
  "$REPO_DIR/plugins" \
  "$REPO_DIR/artifacts" \
  "$REPO_DIR/scripts"

cat >"$REPO_DIR/catalog.json" <<EOF
{
  "schemaVersion": 1,
  "catalog": "${REPO_NAME}",
  "owner": "${TENANT_ID}",
  "description": "${PRODUCT_NAME} white-label distribution (Proposal 0014)",
  "tenants": [
    {
      "tenantId": "${TENANT_ID}",
      "path": "pack",
      "distributions": ["${DISTRIBUTION_ID}"]
    }
  ]
}
EOF

cat >"$REPO_DIR/pack/tenant.json" <<EOF
{
  "schemaVersion": 1,
  "tenantId": "${TENANT_ID}",
  "brand": {
    "productName": "${PRODUCT_NAME}",
    "windowTitle": "${PRODUCT_NAME}",
    "companyName": "${PRODUCT_NAME}",
    "copyright": "Copyright © ${YEAR}",
    "assets": {
      "logo": "assets/logo.png",
      "favicon": "assets/favicon.png"
    },
    "themeDir": "theme",
    "links": {
      "homepage": "https://example.com"
    }
  },
  "application": {
    "appId": "${APP_ID}",
    "executableName": "${EXECUTABLE_NAME}",
    "protocolSchemes": ["${CONFIG_HOME}"],
    "configHome": "${CONFIG_HOME}",
    "userDataNamespace": "${APP_ID}"
  },
  "release": {
    "channel": "beta",
    "publishTarget": "${CONFIG_HOME}-releases",
    "signingProfile": "development"
  },
  "policy": {
    "allowedTrustZones": ["on-device", "private-cloud"],
    "defaultTrustZone": "on-device",
    "locale": "en-US",
    "allowAmbientPathDiscovery": false
  },
  "plugins": {
    "enable": [],
    "disableOptional": [],
    "private": []
  },
  "legal": {
    "note": "Replace with licensed brand assets before shipping."
  }
}
EOF

cat >"$REPO_DIR/pack/distributions/${DISTRIBUTION_ID}.json" <<EOF
{
  "schemaVersion": 1,
  "id": "${DISTRIBUTION_ID}",
  "coordinate": {
    "edition": "consumer",
    "jurisdiction": "CN",
    "tenant": "${TENANT_ID}"
  },
  "shell": "${SHELL_ID}",
  "profiles": [
    "jurisdiction.cn",
    "edition.classic-shell",
    "tenant.${TENANT_ID}"
  ]
}
EOF

cat >"$REPO_DIR/findesk.lock.json" <<EOF
{
  "schemaVersion": 1,
  "findesk": {
    "package": "findesk-desktop-sdk",
    "version": "REPLACE_WITH_SDK_VERSION",
    "artifact": "artifacts/findesk-desktop-sdk.tar.gz",
    "integrity": "sha256-REPLACE_AFTER_DOWNLOAD",
    "note": "Pin the desktop SDK tarball from finogeeks/findesk-std Releases (no findesk source checkout). See docs/getting-started.md"
  },
  "findeskCore": {
    "note": "Runtime binaries follow the SDK package.json aioncoreVersion — findesk-core source is not required."
  }
}
EOF

cat >"$REPO_DIR/package.json" <<EOF
{
  "name": "${REPO_NAME}",
  "private": true,
  "version": "0.1.0",
  "description": "${PRODUCT_NAME} FinDesk white-label distribution",
  "scripts": {
    "init-identity": "bash scripts/init-identity.sh",
    "doctor": "bash scripts/doctor.sh",
    "materialize": "bash scripts/materialize.sh",
    "start": "bash scripts/start.sh",
    "dist": "bash scripts/dist.sh"
  }
}
EOF

if [[ ! -f "$REPO_DIR/pack/theme/tokens.json" ]]; then
  printf '%s\n' '{ "$schemaNote": "brand tokens" }' >"$REPO_DIR/pack/theme/tokens.json"
fi

# Minimal 1x1 PNG so doctor asset checks can pass after user replaces logo.
PNG_B64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
if command -v base64 >/dev/null 2>&1; then
  echo "$PNG_B64" | base64 -d >"$REPO_DIR/pack/assets/logo.png" 2>/dev/null \
    || echo "$PNG_B64" | base64 -D >"$REPO_DIR/pack/assets/logo.png"
  cp "$REPO_DIR/pack/assets/logo.png" "$REPO_DIR/pack/assets/favicon.png"
else
  echo "warning: base64 not found; create pack/assets/logo.png before doctor" >&2
fi

README_SRC="$REPO_DIR/README.md"
if [[ -f "$README_SRC" ]]; then
  # Portable placeholder substitution (no perl required).
  TMP_README="$(mktemp)"
  sed \
    -e "s/{{REPO_NAME}}/${REPO_NAME}/g" \
    -e "s/{{PRODUCT_NAME}}/${PRODUCT_NAME}/g" \
    -e "s/{{DISTRIBUTION_ID}}/${DISTRIBUTION_ID}/g" \
    -e "s/{{TENANT_ID}}/${TENANT_ID}/g" \
    -e "s/{{CONFIG_HOME}}/${CONFIG_HOME}/g" \
    "$README_SRC" >"$TMP_README"
  mv "$TMP_README" "$README_SRC"
fi

echo "✓ Identity written under ${REPO_DIR}"
echo "    tenant:         ${TENANT_ID}"
echo "    distribution:   ${DISTRIBUTION_ID}"
echo "    configHome:     ~/.${CONFIG_HOME}"
echo ""
echo "Next:"
echo "  # pin findesk-desktop-sdk in findesk.lock.json (docs/getting-started.md)"
echo "  bun run doctor"
echo "  bun run materialize"
echo "  bun run start"
