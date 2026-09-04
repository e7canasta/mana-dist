# Playbook: instalacion productiva

1. Instalar Docker Engine y Compose.
2. Extraer `mana-dist-X.Y.Z.tar.gz`.
3. Copiar `.env.example` a `.env`.
4. Establecer secretos reales y revisar puertos.
5. Ejecutar `./scripts/install.sh`.
6. Verificar `docker compose -f compose.production.yml ps` y los healthchecks.
7. Ejecutar seeds solo si la instalacion requiere datos iniciales.
