#!/bin/bash
# Aplica un perfil JSON a mana-hub y verifica que llegó a hive
# Uso: ./scripts/apply-profile.sh config/mana-hive/profiles/jose-escalation-v4.json
set -e
FILE=${1:-config/mana-hive/profiles/jose-e1-v3.json}
HUB_URL=${HUB_URL:-http://localhost:8080}

echo "=== Aplicando perfil $FILE a $HUB_URL ==="
RESIDENT=$(python3 -c "import json; print(json.load(open('$FILE'))['residentId'])")
echo "Resident: $RESIDENT"

curl -s -X PUT "$HUB_URL/api/profiles/$RESIDENT" -H "Content-Type: application/json" --data-binary "@$FILE" -w "\nHTTP_CODE:%{http_code}\n" | tail -5

echo ""
echo "=== Verificando en hub ==="
curl -s "$HUB_URL/api/profiles/$RESIDENT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"{d['profileId']} v{d['version']} validFrom={d['validFrom']}\"); cb=d['subjects']['resident']['aspects']['posture']['states']; print('states:', list(cb.keys()))"

echo ""
echo "=== Esperando hive (5s) ==="
sleep 3
docker compose -f compose.dev.yml logs --tail=10 mana-hive 2>&1 | grep -E "Recalibrado|huella|perfil" | tail -5
echo "Listo. Guardado en: $FILE (exportable via GET /api/profiles/$RESIDENT)"
