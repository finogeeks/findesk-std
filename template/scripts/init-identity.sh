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
CLOUD_SURFACES=""
UPDATE_ORIGIN="none"
GITHUB_REPO=""
FEED_URL=""
PUBLISH_ADAPTER=""
S3_BUCKET=""
S3_PREFIX=""
S3_ENDPOINT=""
S3_REGION=""
RSYNC_HOST=""
RSYNC_PATH=""
FILE_PATH=""

usage() {
  cat >&2 <<'EOF'
Usage: bash scripts/init-identity.sh \
  --tenant-id <id> --distribution-id <id> --config-home <slug> \
  --app-id <reverse.dns> --product-name <name> \
  [--shell findesk-classic] [--cloud-surfaces on|off] [--repo-dir <path>] \
  [--update-origin github|generic|external|none] \
  [--github-repo <owner/repo>] \
  [--feed-url <https://…>] [--publish-adapter s3|rsync|file] \
  [--s3-bucket <name>] [--s3-prefix <prefix>] [--s3-endpoint <url>] [--s3-region <region>] \
  [--rsync-host <host>] [--rsync-path <path>] [--file-path <path>]
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
    --cloud-surfaces) CLOUD_SURFACES="${2:-}"; shift 2 ;;
    --repo-dir) REPO_DIR="${2:-}"; shift 2 ;;
    --update-origin) UPDATE_ORIGIN="${2:-}"; shift 2 ;;
    --github-repo) GITHUB_REPO="${2:-}"; shift 2 ;;
    --feed-url) FEED_URL="${2:-}"; shift 2 ;;
    --publish-adapter) PUBLISH_ADAPTER="${2:-}"; shift 2 ;;
    --s3-bucket) S3_BUCKET="${2:-}"; shift 2 ;;
    --s3-prefix) S3_PREFIX="${2:-}"; shift 2 ;;
    --s3-endpoint) S3_ENDPOINT="${2:-}"; shift 2 ;;
    --s3-region) S3_REGION="${2:-}"; shift 2 ;;
    --rsync-host) RSYNC_HOST="${2:-}"; shift 2 ;;
    --rsync-path) RSYNC_PATH="${2:-}"; shift 2 ;;
    --file-path) FILE_PATH="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "error: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$TENANT_ID" || -z "$DISTRIBUTION_ID" || -z "$CONFIG_HOME" || -z "$APP_ID" || -z "$PRODUCT_NAME" ]]; then
  echo "error: tenant-id, distribution-id, config-home, app-id, and product-name are required" >&2
  usage
fi

json_value_guard() {
  local label="$1"
  local value="$2"
  if [[ -n "$value" && ( "$value" == *'"'* || "$value" == *'\'* ) ]]; then
    echo "error: ${label} must not contain double quotes or backslashes" >&2
    exit 1
  fi
}

for _id_field in \
  "tenant-id:$TENANT_ID" \
  "distribution-id:$DISTRIBUTION_ID" \
  "config-home:$CONFIG_HOME" \
  "app-id:$APP_ID" \
  "product-name:$PRODUCT_NAME" \
  "shell:$SHELL_ID"; do
  json_value_guard "${_id_field%%:*}" "${_id_field#*:}"
done

if [[ "$PRODUCT_NAME" == */* ]]; then
  echo "error: product-name must not contain slashes (breaks README substitution)" >&2
  exit 1
fi

if [[ -n "$CLOUD_SURFACES" && "$CLOUD_SURFACES" != "on" && "$CLOUD_SURFACES" != "off" ]]; then
  echo "error: --cloud-surfaces must be on or off" >&2
  usage
fi

for _uo_val in "$GITHUB_REPO" "$FEED_URL" "$S3_BUCKET" "$S3_PREFIX" "$S3_ENDPOINT" "$S3_REGION" "$RSYNC_HOST" "$RSYNC_PATH" "$FILE_PATH"; do
  json_value_guard "update-origin value" "$_uo_val"
done

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

POLICY_CLOUD_SURFACES=""
if [[ "$CLOUD_SURFACES" == "off" || "$CLOUD_SURFACES" == "on" ]]; then
  POLICY_CLOUD_SURFACES=",
    \"cloudSurfaces\": \"${CLOUD_SURFACES}\""
fi

RELEASE_UPDATE=""
case "$UPDATE_ORIGIN" in
  none) RELEASE_UPDATE="" ;;
  github)
    [[ -n "$GITHUB_REPO" ]] || { echo "error: --github-repo required for --update-origin github" >&2; exit 1; }
    RELEASE_UPDATE=",
    \"onlineUpdate\": { \"githubRepo\": \"${GITHUB_REPO}\" },
    \"publish\": { \"adapter\": \"github\" }" ;;
  external)
    [[ -n "$FEED_URL" ]] || { echo "error: --feed-url required for --update-origin external" >&2; exit 1; }
    [[ "$FEED_URL" == https://* ]] || { echo "error: --feed-url must be https (edit pack/tenant.json manually for intranet http + allowInsecureFeedUrl)" >&2; exit 1; }
    RELEASE_UPDATE=",
    \"onlineUpdate\": { \"feedUrl\": \"${FEED_URL}\" },
    \"publish\": { \"adapter\": \"external\" }" ;;
  generic)
    [[ -n "$FEED_URL" && -n "$PUBLISH_ADAPTER" ]] || { echo "error: --feed-url and --publish-adapter required for --update-origin generic" >&2; exit 1; }
    [[ "$FEED_URL" == https://* ]] || { echo "error: --feed-url must be https (edit pack/tenant.json manually for intranet http + allowInsecureFeedUrl)" >&2; exit 1; }
    case "$PUBLISH_ADAPTER" in
      s3)
        [[ -n "$S3_BUCKET" ]] || { echo "error: --s3-bucket required for s3" >&2; exit 1; }
        PUBLISH_JSON="{ \"adapter\": \"s3\", \"bucket\": \"${S3_BUCKET}\""
        [[ -n "$S3_PREFIX" ]] && PUBLISH_JSON+=", \"prefix\": \"${S3_PREFIX}\""
        [[ -n "$S3_ENDPOINT" ]] && PUBLISH_JSON+=", \"endpoint\": \"${S3_ENDPOINT}\""
        [[ -n "$S3_REGION" ]] && PUBLISH_JSON+=", \"region\": \"${S3_REGION}\""
        PUBLISH_JSON+=" }" ;;
      rsync)
        [[ -n "$RSYNC_HOST" && -n "$RSYNC_PATH" ]] || { echo "error: --rsync-host and --rsync-path required for rsync" >&2; exit 1; }
        PUBLISH_JSON="{ \"adapter\": \"rsync\", \"host\": \"${RSYNC_HOST}\", \"path\": \"${RSYNC_PATH}\" }" ;;
      file)
        [[ -n "$FILE_PATH" ]] || { echo "error: --file-path required for file" >&2; exit 1; }
        PUBLISH_JSON="{ \"adapter\": \"file\", \"path\": \"${FILE_PATH}\" }" ;;
      *) echo "error: --publish-adapter must be s3|rsync|file for generic" >&2; exit 1 ;;
    esac
    RELEASE_UPDATE=",
    \"onlineUpdate\": { \"feedUrl\": \"${FEED_URL}\" },
    \"publish\": ${PUBLISH_JSON}" ;;
  *) echo "error: --update-origin must be github|generic|external|none" >&2; exit 1 ;;
esac

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
    "signingProfile": "development"${RELEASE_UPDATE}
  },
  "policy": {
    "allowedTrustZones": ["on-device", "private-cloud"],
    "defaultTrustZone": "on-device",
    "locale": "en-US",
    "allowAmbientPathDiscovery": false${POLICY_CLOUD_SURFACES}
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
    "dist": "bash scripts/dist.sh",
    "publish:online-update": "bash scripts/publish-online-update.sh"
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
