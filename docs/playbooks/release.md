# Playbook: release

1. Revisar los commits fijados en `repos.env`.
2. Ejecutar `git diff --check`.
3. Ejecutar `./release.sh X.Y.Z`.
4. Verificar `SHA256SUMS`.
5. Probar el paquete en un workspace limpio.
6. Conservar el paquete anterior para rollback.
