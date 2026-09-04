#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f .env ]] || { cp .env.example .env; echo "Edit .env and run install.sh again."; exit 1; }
set -a
source .env
set +a
[[ "${POSTGRES_PASSWORD:-}" != "replace-with-a-secret" ]] || { echo "Set POSTGRES_PASSWORD in .env" >&2; exit 1; }

gzip -dc images/mana-images.tar.gz | docker load
docker compose -f compose.production.yml up -d postgres nats mongo mana-hive mana-hub bridge mana-ui mana-cox
echo "Production distribution $MANA_VERSION started."
