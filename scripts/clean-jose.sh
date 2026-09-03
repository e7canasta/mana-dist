#!/bin/bash
# Limpia todo lo de José para pruebas desde cero
# No toca perfiles, residentes, camas — solo episodios y eventos
set -e
PG_CONTAINER="mana-pg-dev"
DB="mana_hub"
USER="postgres"

echo "=== Limpiando José (episodios + eventos) ==="
docker exec $PG_CONTAINER psql -U $USER -d $DB -c "
DELETE FROM episode_transitions WHERE episode_id IN (SELECT id FROM episodes WHERE resident_id='jose');
DELETE FROM episode_timeline_events WHERE resident_id='jose';
DELETE FROM episodes WHERE resident_id='jose';
DELETE FROM scene_events WHERE bed_id='bed-4';
DELETE FROM sensor_events WHERE bed_id='bed-4';
DELETE FROM evidence WHERE resident_id='jose';
DELETE FROM notification_events WHERE resident_id='jose';
DELETE FROM notification_deliveries WHERE episode_id NOT IN (SELECT id FROM episodes);
"

echo ""
echo "=== Estado limpio ==="
docker exec $PG_CONTAINER psql -U $USER -d $DB -c "SELECT 'episodes:' || count(*) FROM episodes WHERE resident_id='jose';"
docker exec $PG_CONTAINER psql -U $USER -d $DB -c "SELECT 'scene_events:' || count(*) FROM scene_events;"
docker exec $PG_CONTAINER psql -U $USER -d $DB -c "SELECT 'timeline:' || count(*) FROM episode_timeline_events;"
echo ""
echo "Listo para: ./gradlew :examples:jose-e1:run -Pmain=jose301.MainNatsScenarioE1Kt"
echo "           ./gradlew :examples:jose-e1:run -Pmain=jose301.MainNatsScenarioE2Kt"
