#!/usr/bin/env bash
# Compare this distribution's findesk.lock.json pin to the latest public
# finogeeks/findesk-std release. When upstream is newer, open (or refresh) a
# GitHub issue — humans decide when to bump the lock / rebake installers.
#
# Usage (from distribution repo root):
#   bash scripts/watch-findesk-std.sh
#   bash scripts/watch-findesk-std.sh --dry-run
#   UPSTREAM_REPO=finogeeks/findesk-std bash scripts/watch-findesk-std.sh
#
# Env:
#   UPSTREAM_REPO   default finogeeks/findesk-std
#   LOCK_PATH       default findesk.lock.json
#   ISSUE_LABEL     default upstream:findesk-std
#   DRY_RUN         1/true → log only (or pass --dry-run)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

UPSTREAM_REPO="${UPSTREAM_REPO:-finogeeks/findesk-std}"
LOCK_PATH="${LOCK_PATH:-findesk.lock.json}"
ISSUE_LABEL="${ISSUE_LABEL:-upstream:findesk-std}"
DRY_RUN="${DRY_RUN:-0}"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
  esac
done

if [[ ! -f "$LOCK_PATH" ]]; then
  echo "error: missing $LOCK_PATH" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI required" >&2
  exit 1
fi

read_lock_version() {
  python3 - "$LOCK_PATH" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
ver = (data.get("findesk") or {}).get("version")
if not ver:
    raise SystemExit(f"error: {path} missing findesk.version")
print(str(ver).lstrip("v"))
PY
}

semver_cmp() {
  # prints: eq | lt | gt  for $1 vs $2 (version strings without required v)
  python3 - "$1" "$2" <<'PY'
import sys

def parts(v: str):
    v = v.lstrip("v")
    out = []
    for p in v.replace("-", ".").split("."):
        if p.isdigit():
            out.append((0, int(p)))
        else:
            out.append((1, p))
    return out

def cmp(a, b):
    pa, pb = parts(a), parts(b)
    for x, y in zip(pa, pb):
        if x == y:
            continue
        if x[0] != y[0]:
            return -1 if x[0] < y[0] else 1
        if x[1] < y[1]:
            return -1
        if x[1] > y[1]:
            return 1
    if len(pa) == len(pb):
        return 0
    return -1 if len(pa) < len(pb) else 1

a, b = sys.argv[1], sys.argv[2]
c = cmp(a, b)
print("eq" if c == 0 else "lt" if c < 0 else "gt")
PY
}

PINNED="$(read_lock_version)"
LATEST_TAG="$(gh release view -R "$UPSTREAM_REPO" --json tagName --jq .tagName)"
LATEST="${LATEST_TAG#v}"

# Prefer GITHUB_REPOSITORY in Actions; else infer from gh when inside a git checkout.
THIS_REPO="${GITHUB_REPOSITORY:-}"
if [[ -z "$THIS_REPO" ]]; then
  THIS_REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
fi
GH_REPO_ARGS=()
if [[ -n "$THIS_REPO" ]]; then
  GH_REPO_ARGS=(-R "$THIS_REPO")
fi

echo "lock pin:     $PINNED  ($LOCK_PATH)"
echo "upstream:     $LATEST  ($UPSTREAM_REPO $LATEST_TAG)"

CMP="$(semver_cmp "$PINNED" "$LATEST")"
case "$CMP" in
  eq)
    echo "status: up to date"
    exit 0
    ;;
  gt)
    echo "status: lock ahead of latest public release (local/prerelease pin?) — no issue"
    exit 0
    ;;
  lt)
    echo "status: upstream newer — ensure tracking issue"
    ;;
  *)
    echo "error: unexpected compare result: $CMP" >&2
    exit 1
    ;;
esac

TITLE="Upstream findesk-std ${LATEST_TAG} available (pinned ${PINNED})"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

cat >"$BODY_FILE" <<EOF
## Upstream SDK available

| | |
| --- | --- |
| **Pinned** (\`${LOCK_PATH}\`) | \`${PINNED}\` |
| **Latest** ([${UPSTREAM_REPO}](https://github.com/${UPSTREAM_REPO}/releases/tag/${LATEST_TAG})) | \`${LATEST}\` |

This distribution treats **findesk-std** as upstream. Bump when ready — do not auto-merge.

### Upgrade checklist

1. Fetch lock snippet:
   \`\`\`bash
   gh release download ${LATEST_TAG} -R ${UPSTREAM_REPO} \\
     --pattern '*.lock.snippet.json' --dir /tmp/findesk-std-pin --clobber
   cat /tmp/findesk-std-pin/*.lock.snippet.json
   \`\`\`
2. Update \`findesk.lock.json\` (\`findesk.version\`, \`artifact\`, \`integrity\`; refresh \`findeskCore.version\` note if present).
3. Offline dual-delivery: download the tarball into \`artifacts/\` (gitignored) when using a relative \`artifact\` path.
4. Clear stale cache if needed: \`rm -rf ~/.cache/findesk/platforms/${PINNED}\`
5. \`bun run doctor && bun run materialize\`
6. Smoke / \`bun run dist\` as usual for this SKU.

### Notes

- Opened by \`.github/workflows/findesk-std-upstream-watch.yml\` (daily + manual).
- Label: \`${ISSUE_LABEL}\`
EOF

ensure_label() {
  if [[ ${#GH_REPO_ARGS[@]} -eq 0 ]]; then
    echo "error: cannot resolve this GitHub repo (set GITHUB_REPOSITORY or run inside a git remote)" >&2
    exit 1
  fi
  if gh label list "${GH_REPO_ARGS[@]}" --json name --jq '.[].name' | grep -Fxq "$ISSUE_LABEL"; then
    return 0
  fi
  gh label create "$ISSUE_LABEL" "${GH_REPO_ARGS[@]}" \
    --description "Newer finogeeks/findesk-std release than findesk.lock.json" \
    --color "0052CC" 2>/dev/null || true
}

existing="$(
  if [[ ${#GH_REPO_ARGS[@]} -eq 0 ]]; then
    echo ""
  else
    gh issue list "${GH_REPO_ARGS[@]}" --state open --label "$ISSUE_LABEL" --limit 50 \
      --json number,title \
      --jq ".[] | select(.title | test(\"findesk-std ${LATEST_TAG}|findesk-std v?${LATEST}\")) | .number" \
      | head -n 1 || true
  fi
)"

if [[ -n "$existing" ]]; then
  echo "existing open issue: #$existing"
  if [[ "$DRY_RUN" == "1" || "$DRY_RUN" == "true" ]]; then
    echo "dry-run: would comment on #$existing"
    exit 0
  fi
  gh issue comment "${GH_REPO_ARGS[@]}" "$existing" --body "Re-checked: still pinned at \`${PINNED}\`; upstream remains \`${LATEST_TAG}\`."
  exit 0
fi

# Collapse older open upstream issues for prior versions (optional hygiene)
older=""
if [[ ${#GH_REPO_ARGS[@]} -gt 0 ]]; then
  older="$(
    gh issue list "${GH_REPO_ARGS[@]}" --state open --label "$ISSUE_LABEL" --limit 20 \
      --json number,title \
      --jq '.[].number' || true
  )"
fi

if [[ "$DRY_RUN" == "1" || "$DRY_RUN" == "true" ]]; then
  echo "dry-run: would create issue:"
  echo "  title: $TITLE"
  echo "  label: $ISSUE_LABEL"
  echo "  repo:  ${THIS_REPO:-unknown}"
  if [[ -n "$older" ]]; then
    echo "  note: open ${ISSUE_LABEL} issues already exist: $(echo "$older" | tr '\n' ' ')"
  fi
  exit 0
fi

ensure_label
url="$(gh issue create "${GH_REPO_ARGS[@]}" --title "$TITLE" --label "$ISSUE_LABEL" --body-file "$BODY_FILE")"
echo "created: $url"
