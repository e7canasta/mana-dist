#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$ROOT")"

# shellcheck disable=SC1091
source "$ROOT/repos.env"

clone_repo() {
  local name="$1"
  local url="$2"
  local ref="$3"
  local target="$WORKSPACE/$name"

  if [[ -e "$target" && ! -d "$target/.git" ]]; then
    echo "ERROR: $target exists but is not a Git repository" >&2
    exit 1
  fi

  if [[ -d "$target/.git" ]]; then
    echo "Already present: $name"
    return
  fi

  echo "Cloning $name ($ref)"
  git clone --branch "$ref" --single-branch "$url" "$target"
}

command -v git >/dev/null || { echo "ERROR: git is required" >&2; exit 1; }

clone_repo mana-hive "$MANA_HIVE_URL" "$MANA_HIVE_REF"
clone_repo mana-hub "$MANA_HUB_URL" "$MANA_HUB_REF"
clone_repo mana-cox "$MANA_COX_URL" "$MANA_COX_REF"
clone_repo mana-ui "$MANA_UI_URL" "$MANA_UI_REF"

echo
echo "Repositories ready in $WORKSPACE"
echo "Next: ./build.sh && docker compose -f compose.dev.yml up -d"
