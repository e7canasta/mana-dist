#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE=(docker compose -f "$ROOT/compose.dev.yml")
SCENARIO="${1:-jose}"

case "$SCENARIO" in
  jose) FIXTURE="$ROOT/seed/manantial-jose.sql" ;;
  *) echo "Unknown scenario: $SCENARIO (available: jose)" >&2; exit 2 ;;
esac

echo "Waiting for PostgreSQL..."
for _ in {1..60}; do
  if "${COMPOSE[@]}" exec -T postgres pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-mana_hub}" >/dev/null 2>&1; then
    break
  fi
  sleep 2

"${COMPOSE[@]}" exec -T postgres pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-mana_hub}" >/dev/null
echo "Applying fixture: $SCENARIO"
"${COMPOSE[@]}" exec -T postgres psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-mana_hub}" < "$FIXTURE"
echo "Seed complete. José is assigned to bed-103."
