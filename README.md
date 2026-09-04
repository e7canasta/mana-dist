# Mana-Dist — Distribución Edge

Sistema de distribución para mana-hive + mana-hub + bridge + mana-cox.
Optimizado para edge: 3 residentes, 8 cámaras, ~1.6GB RAM con Leyden AOT.

---

## Índice

- [Servicios](#servicios)
- [Estructura del directorio](#estructura-del-directorio)
- [Dev vs Prod (Edge)](#dev-vs-prod-edge)
- [AOT (Ahead-Of-Time)](#aot-ahead-of-time)
- [Configuración](#configuración)
- [Logs](#logs)
- [Cómo buildear](#cómo-buildear)
- [Cómo deployar](#cómo-deployar)
- [Scripts útiles](#scripts-útiles)
- [Troubleshooting](#troubleshooting)

---

## Servicios

| Servicio | Puerto | RAM (prod) | Descripción |
|----------|--------|------------|-------------|
| **mana-hive** | 18081 | 400M | Motor nocturno: Scene, Sentinel, Harbor, Recorder |
| **mana-hub** | 8080 | 700M | System of record: JPA + PostgreSQL |
| **bridge** | 8090 | 350M | Traductor NATS ↔ HTTP |
| **mana-ui** | 3000 | 64M | Interfaz web de Manantial Care |
| **mana-cox** | 8091 | — | Orquestador (solo dev) |
| **PostgreSQL** | 5432 | 100M | Base de datos relacional |
| **MongoDB** | 27017 | — | Document store (solo dev) |
| **NATS** | 4222 | 50M | Message bus con JetStream |

**Flujo:** Cámaras → mana-hive (escena) → NATS → bridge → mana-hub (persistencia)

---

## Estructura del directorio

```
mana-dist/
├── build.sh                      # Builda todos los JARs desde los repos fuente
├── deploy.sh                     # Deploy edge (genera AOT si falta + levanta)
│
├── compose.dev.yml               # Desarrollo: JARs montados desde host
├── compose.edge.yml              # Producción/edge: imágenes con AOT + jlink
├── mana-ui/
│   ├── Dockerfile                 # Build multi-stage de crm-ui
│   └── nginx.conf                 # SPA + proxy /api hacia mana-hub
│
├── aot-jvm/
│   ├── Dockerfile.aotgen         # Genera cache AOT (se ejecuta una vez)
│   ├── Dockerfile.deploy         # Imagen runtime con AOT cacheado
│   ├── bootstrap-1.0.0-SNAPSHOT.jar  # mana-hub JAR
│   ├── event-bridge-1.0.0-SNAPSHOT.jar  # bridge JAR
│   ├── engines-night-watch-runtime.jar  # mana-hive JAR
│   └── mana-cox.jar              # mana-cox JAR (solo dev)
│
├── config/
│   ├── mana-hive/
│   │   ├── application.yml       # Config de mana-hive
│   │   └── profiles/             # Perfiles JSON de residentes
│   ├── mana-hub/
│   │   └── application.yml       # Config de mana-hub
│   └── bridge/
│       └── application.yml       # Config de bridge
│
├── shared/
│   ├── profiles/                 # Perfiles compartidos (montados por hive)
│   └── logs/                     # Logs de cada servicio
│       ├── hive/
│       ├── hub/
│       ├── bridge/
│       └── cox/
│
├── cache/                        # AOT cache de mana-hive
├── cache-hub/                    # AOT cache de mana-hub
├── cache-bridge/                 # AOT cache de bridge
│
│
├── scripts/
│   ├── apply-profile.sh          # Aplica un perfil JSON vía hub API
│   └── clean-jose.sh             # Limpia episodios de José para testing
│
├── seed/
│   └── manantial-jose.sql        # Fixture José -> bed-103
└── docs/                         # Documentación adicional
```

El schema de PostgreSQL lo administra `mana-hub` mediante Flyway. No se monta
un dump SQL en Docker, así el entorno puede reiniciarse desde cero sin conflicto
con `flyway_schema_history`.

Después de levantar los servicios y esperar a que Hub esté saludable, aplicar
la fixture de desarrollo con:

```bash
docker exec -i mana-pg-dev psql -U postgres -d mana_hub < seed/manantial-jose.sql
```

Esta fixture crea a José en `bed-103`; los escenarios sintéticos de Cox que usan
`bed-4` son una configuración separada.

---

## Dev vs Prod (Edge)

### compose.dev.yml — Desarrollo

- **JARs montados** directamente desde `aot-jvm/` (volumen bind mount)
- **Sin AOT**: usa JRE estándar (`eclipse-temurin:25-jre`)
- **Todos los servicios**: incluye mana-cox y MongoDB
- **Puertos expuestos** para debugging
- **Rebuild rápido**: `./build.sh && docker compose -f compose.dev.yml restart`

```
Services: postgres, mongo, nats, mana-hive, mana-hub, bridge, mana-ui, mana-cox
```

### compose.edge.yml — Producción / Edge

- **Imágenes construidas** con Dockerfile (jlink + Oracle Linux slim)
- **Con AOT**: genera cache AOT primero, luego lo carga en runtime
- **Sin mana-cox ni MongoDB** (servicios solo dev)
- **Límites de memoria** por servicio (deploy.resources.limits)
- **AOT training**: paso separado que corre una vez y genera los `.aot`

```
Services: postgres, nats, aotgen-hive, aotgen-hub, aotgen-bridge,
          mana-hive, mana-hub, bridge, mana-ui
```

### Comparación rápida

| | Dev | Prod/Edge |
|---|---|---|
| JARs | Montados desde host | Empaquetados en imagen Docker |
| Java | JRE estándar | jlink custom + AOT cache |
| mana-cox | ✅ | ❌ |
| MongoDB | ✅ | ❌ |
| RAM total | ~2GB | ~1.6GB |
| Rebuild | `./build.sh` + restart | `./build.sh` + aotgen + deploy |

`mana-ui` se construye desde el repositorio hermano `../crm-ui`, sirve la SPA
con Nginx y proxifica `/api/` internamente hacia `mana-hub`. Queda disponible en
`http://localhost:3000`.

---

## AOT (Ahead-Of-Time)

Project Leyden permite compilar el profile de Spring Boot a binario nativo, reduciendo tiempo de arranque y RAM.

### Qué es

1. **Training** (`aotgen-*`): corre la app una vez con `-XX:AOTCacheOutput=...` y genera un archivo `.aot`
2. **Runtime** (`Dockerfile.deploy`): carga ese `.aot` con `-XX:AOTCache=...` al iniciar

### Dónde quedan los caches

| Servicio | Directorio | Archivo |
|----------|------------|---------|
| mana-hive | `cache/` | `app.aot` |
| mana-hub | `cache-hub/` | `app.aot` |
| bridge | `cache-bridge/` | `app.aot` |

### Cuándo regenerar

- Después de cambiar código fuente
- Después de actualizar dependencias
- Si hay errores de AOT al iniciar

```bash
rm -rf cache/ cache-hub/ cache-bridge/
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
```

---

## Configuración

### Ubicación

| Servicio | Config | Perfiles |
|----------|--------|----------|
| mana-hive | `config/mana-hive/application.yml` | `config/mana-hive/profiles/*.json` |
| mana-hub | `config/mana-hub/application.yml` | — |
| bridge | `config/bridge/application.yml` | — |

### Perfiles de residentes

JSONs en `config/mana-hive/profiles/` o `shared/profiles/`. Ejemplo:

```json
{
  "profileId": "jose@v23",
  "residentId": "jose",
  "version": 23,
  "subjects": {
    "resident": {
      "kind": "dag",
      "aspects": {
        "posture": {
          "states": {
            "LYING": {
              "comeBack": [
                {
                  "window": "always",
                  "warningAfter": "PT12M",
                  "alertAfter": "PT15M"
                }
              ]
            }
          }
        }
      }
    }
  }
}
```

### Variables de entorno clave

| Variable | Default | Usado por |
|----------|---------|-----------|
| `NATS_URL` | `nats://nats:4222` | hive, bridge, cox |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://postgres:5432/mana_hub` | hub |
| `BRIDGE_TARGET_URL` | `http://mana-hub:8080` | bridge |
| `MANAHIVE_PROFILES_DIR` | `/app/profiles` | hive (dev) |
| `COX_PROFILE_PATH` | `/app/profiles/jose-v-min.json` | cox (dev) |

---

## Logs

### Ubicación

Todos los servicios loguean a `shared/logs/<servicio>/` montado como volumen.

```
shared/logs/
├── hive/      # mana-hive logs
├── hub/       # mana-hub logs
├── bridge/    # bridge logs
└── cox/       # mana-cox logs (solo dev)
```

### Ver logs

```bash
# Todos los servicios
docker compose -f compose.edge.yml logs -f

# Un servicio específico
docker compose -f compose.edge.yml logs -f mana-hive

# Solo las últimas 100 líneas
docker compose -f compose.edge.yml logs --tail=100 mana-hub

# Logs del host (si montás un volumen)
tail -f shared/logs/hive/*.log
```

---

## Cómo buildear

### 1. Build de JARs

```bash
./build.sh
```

Esto builda desde los repos fuente (`../mana-hive`, `../mana-hub`, `../mana-cox`) y copia los JARs a `aot-jvm/`.

El build de `mana-ui` necesita que `../crm-ui` este clonado al lado de
`mana-dist`. Docker usa el contexto `..` para construir la imagen desde ese
repositorio hermano.

### 2. Generar caches AOT (solo para prod/edge)

```bash
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
```

Corre una vez. Los caches quedan en `cache/`, `cache-hub/`, `cache-bridge/`.

### 3. Empaquetar imágenes Docker

Las imágenes se construyen automáticamente con `docker compose up` en compose.edge.yml. Cada servicio usa:

- **Dockerfile.deploy**: imagen runtime con jlink (JRE mínimo) + AOT cache
- **Dockerfile.aotgen**: imagen para generar el cache AOT

Si querés buildar manualmente:

```bash
docker compose -f compose.edge.yml build mana-hive
```

---

## Cómo deployar

### Edge / Producción

```bash
# Opción 1: todo junto
./deploy.sh

# Opción 2: paso a paso
./build.sh
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
docker compose -f compose.edge.yml up -d
```

`deploy.sh` verifica si existen los JARs y los caches AOT, y si faltan los genera.

### Desarrollo

```bash
./build.sh
docker compose -f compose.dev.yml up -d
```

### Parar

```bash
# Prod
docker compose -f compose.edge.yml down

# Dev
docker compose -f compose.dev.yml down

# Con volumes (borra datos)
docker compose -f compose.dev.yml down -v
```

---

## Scripts útiles

### apply-profile.sh

Aplica un perfil JSON a mana-hub y verifica que llega a mana-hive:

```bash
./scripts/apply-profile.sh config/mana-hive/profiles/jose-e1-v3.json
```

### clean-jose.sh

Limpia episodios y eventos de José para testing desde cero (no toca perfiles ni residentes):

```bash
./scripts/clean-jose.sh
```

---

## Troubleshooting

### Servicios no arrancan

```bash
docker compose -f compose.edge.yml logs <servicio>
docker stats
```

### Errores de AOT

```bash
rm -rf cache/ cache-hub/ cache-bridge/
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
docker compose -f compose.edge.yml up -d
```

### Problemas de conexión a BD

```bash
# Verificar que PostgreSQL está healthy
docker compose -f compose.edge.yml ps postgres

# Resetear BD
docker compose -f compose.edge.yml down -v
./deploy.sh
```

### Puerto ya en uso

```bash
# Verificar qué usa el puerto
lsof -i :8080
# O cambiar el mapeo en el compose
```

### Mana-hive no encuentra perfiles

Verificar que `shared/profiles/` o `config/mana-hive/profiles/` tienen los JSONs y que el volumen está montado correctamente en el compose.
