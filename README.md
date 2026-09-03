# Mana-Dist Edge Deployment

Edge deployment for mana-hive + mana-hub + bridge.
Optimized for 3 residents, 8 cameras, ~832M RAM with Leyden AOT.

## Directory Structure

```
mana-dist/
├── compose.edge.yml          # Docker Compose file
├── build.sh                  # Build all JARs
├── deploy.sh                 # Deploy edge environment
├── aot-jvm/
│   ├── Dockerfile.aotgen     # AOT cache generator
│   └── Dockerfile.deploy     # Runtime with AOT cache
├── init-db/
│   └── V01__schema.sql       # Database schema
├── config/
│   ├── mana-hive/
│   │   ├── application.yml   # mana-hive config
│   │   └── profiles/         # Resident profiles
│   ├── mana-hub/
│   │   └── application.yml   # mana-hub config
│   └── bridge/
│       └── application.yml   # bridge config
├── shared/
│   ├── profiles/             # Shared profiles (mounted)
│   └── logs/                 # Service logs
│       ├── hive/
│       ├── hub/
│       └── bridge/
├── cache/                    # AOT cache for mana-hive
├── cache-hub/                # AOT cache for mana-hub
└── cache-bridge/             # AOT cache for bridge
```

## Quick Start

```bash
# 1. Build all JARs
./build.sh

# 2. Generate AOT caches (one-time, or after code changes)
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge

# 3. Start all services
./deploy.sh

# 4. Check status
docker compose -f compose.edge.yml ps

# 5. View logs
docker compose -f compose.edge.yml logs -f
```

## Services

| Service | Port | RAM | Description |
|---------|------|-----|-------------|
| mana-hive | 18081 | 400M | Night watch runtime (Scene, Sentinel, Harbor, Recorder) |
| mana-hub | 8080 | 700M | System of record (JPA, PostgreSQL) |
| bridge | 8090 | 350M | NATS ↔ HTTP translator |
| PostgreSQL | 5432 | 100M | Database |
| NATS | 4222 | 50M | Message bus |

**Total: ~1.6GB** (with Leyden AOT)

## Configuration

### Resident Profiles

Place JSON profiles in `config/mana-hive/profiles/`:

```json
{
  "profileId": "jose@v2",
  "residentId": "jose",
  "version": 2,
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

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| NATS_URL | nats://nats:4222 | NATS connection URL |
| SPRING_DATASOURCE_URL | jdbc:postgresql://postgres:5432/mana_hub | PostgreSQL URL |
| BRIDGE_TARGET_URL | http://mana-hub:8080 | Bridge target URL |

## Development

### Adding New Profiles

1. Create JSON file in `config/mana-hive/profiles/`
2. Restart mana-hive: `docker compose -f compose.edge.yml restart mana-hive`

### Updating Code

1. Make changes to source code
2. Rebuild JARs: `./build.sh`
3. Regenerate AOT caches: `docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge`
4. Restart services: `docker compose -f compose.edge.yml restart`

### Database Changes

1. Update `init-db/V01__schema.sql`
2. Reset database: `docker compose -f compose.edge.yml down -v`
3. Restart: `./deploy.sh`

## Troubleshooting

### Services won't start

```bash
# Check logs
docker compose -f compose.edge.yml logs <service-name>

# Check resource usage
docker stats
```

### AOT cache errors

```bash
# Regenerate caches
rm -rf cache/ cache-hub/ cache-bridge/
docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
```

### Database connection issues

```bash
# Check PostgreSQL is healthy
docker compose -f compose.edge.yml ps postgres

# Reset database
docker compose -f compose.edge.yml down -v
./deploy.sh
```
