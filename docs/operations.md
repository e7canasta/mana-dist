# Operacion

## Estado y logs

```bash
docker compose -f compose.dev.yml ps
docker compose -f compose.dev.yml logs -f mana-hub
```

## Actualizacion

Una release nueva reemplaza las imagenes completas. Los volumenes de datos no se
eliminan. Antes de actualizar, hacer backup de PostgreSQL y MongoDB.

## AOT

Las imagenes usan cache JVM AOT/CDS; no son binarios nativos. La cache debe generarse
con el mismo Java y el mismo JAR. Se regenera al cambiar codigo o dependencias.
