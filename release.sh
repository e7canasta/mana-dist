#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || {
  echo "Usage: $0 <version>, for example 1.0.0" >&2
  exit 2
}

cd "$ROOT"
source "$ROOT/repos.env"
set -a
source "$ROOT/.env.example"
set +a
export MANA_VERSION="$VERSION"
export MANA_IMAGE_PREFIX="mana"

./build.sh
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
docker compose -f compose.edge.yml build mana-hive mana-hub bridge mana-ui mana-cox

OUT="$ROOT/releases/mana-dist-$VERSION"
rm -rf "$OUT"
mkdir -p "$OUT/images" "$OUT/config" "$OUT/scripts"

docker save \
  "mana/mana-hive:$VERSION" \
  "mana/mana-hub:$VERSION" \
  "mana/mana-bridge:$VERSION" \
  "mana/mana-ui:$VERSION" \
  "mana/mana-cox:$VERSION" | gzip -9 > "$OUT/images/mana-images.tar.gz"

cp compose.edge.yml "$OUT/compose.production.yml"
cp -r config "$OUT/config/"
cp -r seed "$OUT/seed"
cp -r cache "$OUT/cache"
cp -r cache-hub "$OUT/cache-hub"
cp -r cache-bridge "$OUT/cache-bridge"
cp install.sh "$OUT/scripts/install.sh"
sed 's#^MANA_IMAGE_PREFIX=.*#MANA_IMAGE_PREFIX=mana#' production.env.example > "$OUT/.env.example"
cat > "$OUT/MANIFEST" <<EOF
MANA_VERSION=$VERSION
MANA_HIVE_REF=$MANA_HIVE_REF
MANA_HUB_REF=$MANA_HUB_REF
MANA_COX_REF=$MANA_COX_REF
MANA_UI_REF=$MANA_UI_REF
EOF

(cd "$OUT" && sha256sum images/mana-images.tar.gz MANIFEST > SHA256SUMS)
tar -C "$ROOT/releases" -czf "$ROOT/mana-dist-$VERSION.tar.gz" "mana-dist-$VERSION"
echo "Release created: $ROOT/mana-dist-$VERSION.tar.gz"
