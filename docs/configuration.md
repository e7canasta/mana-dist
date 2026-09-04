# Configuracion

## Precedencia

1. Variables exportadas por el shell.
2. Archivo `.env` junto al Compose.
3. Valores por defecto definidos para desarrollo.
4. Configuracion YAML montada por el servicio.

Produccion debe usar `production.env.example` como plantilla y proporcionar secretos
fuera de Git.

## Redes

Los nombres Docker son la interfaz estable entre servicios. Los puertos publicados
son solo para acceso desde el host y pueden cambiarse sin modificar las URLs internas.
