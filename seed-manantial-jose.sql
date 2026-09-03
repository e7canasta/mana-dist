-- Manantial — solo José, 1er piso, habitación 103, cama Single
-- Idempotente con ON CONFLICT DO NOTHING (re-ejecutable)
BEGIN;

-- facility
INSERT INTO facilities (id, name, timezone, created_at, updated_at, version)
VALUES ('fac-manantial', 'Geriátrico Manantial', 'America/Argentina/Buenos_Aires', now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- wing / primer piso
INSERT INTO wings (id, facility_id, name, floor, sort_order, created_at, updated_at, version)
VALUES ('wing-p1', 'fac-manantial', 'Primer Piso', '1', 1, now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, floor = EXCLUDED.floor;

-- room 103
INSERT INTO rooms (id, wing_id, number, created_at, updated_at, version)
VALUES ('room-103', 'wing-p1', '103', now(), now(), 0)
ON CONFLICT (id) DO NOTHING;

-- bed Single (la habitación es la cama)
INSERT INTO beds (id, room_id, label, monitor_key, created_at, updated_at, version)
VALUES ('bed-103', 'room-103', 'Single', 'm103', now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET label = EXCLUDED.label, monitor_key = EXCLUDED.monitor_key;

-- residente solo José (ingreso hoy)
INSERT INTO residents (id, full_name, birth_date, admission_date, status, created_at, updated_at, version)
VALUES ('jose', 'José García', '1942-03-15'::date, CURRENT_DATE, 'active', now(), now(), 0)
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, admission_date = CURRENT_DATE, status='active', updated_at = now();

-- desasignar camas previas de José (si re-seed desde seed-test.sql)
UPDATE resident_bed_assignments SET ends_at = now() WHERE resident_id='jose' AND ends_at IS NULL AND bed_id <> 'bed-103';

-- asignación José -> cama 103
INSERT INTO resident_bed_assignments (id, resident_id, bed_id, starts_at, created_at, version)
VALUES ('assign-jose-103', 'jose', 'bed-103', now(), now(), 0)
ON CONFLICT (id) DO NOTHING;

-- limpiar residentes de prueba extra (opcional: solo José)
-- comenta estas líneas si querés conservar María
DELETE FROM resident_bed_assignments WHERE resident_id='maria';
DELETE FROM alarm_profile_versions WHERE resident_id='maria';
DELETE FROM residents WHERE id='maria';

-- booking de perfil base si no existe (para que José tenga política)
INSERT INTO alarm_profile_versions (id, resident_id, valid_from, risk_level, mobility_aid, autopilot, mode, template_id, updated_by, created_at, version)
VALUES ('profile-jose-manantial-v1', 'jose', now(), 'LOW', 'NONE', false, 'PRESET', 'standard', 'seed-manantial', now(), 0)
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- verificacion
SELECT 'facilities' as t, count(*) FROM facilities
UNION ALL SELECT 'wings', count(*) FROM wings
UNION ALL SELECT 'rooms', count(*) FROM rooms WHERE id='room-103'
UNION ALL SELECT 'beds', count(*) FROM beds WHERE id='bed-103'
UNION ALL SELECT 'residents jose', count(*) FROM residents WHERE id='jose'
UNION ALL SELECT 'assignments jose', count(*) FROM resident_bed_assignments WHERE resident_id='jose' AND ends_at IS NULL;
