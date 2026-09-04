# mana-dist

Distribucion reproducible de `mana-ui`, `mana-hub`, `mana-hive`, `mana-cox` y el bridge.
Este repositorio es el orquestador: los proyectos fuente permanecen en repositorios separados.

## Dos usos

### Desarrollo

Clona el orquestador y los cuatro repositorios hermanos:

```bash
git clone https://github.com/e7canasta/mana-dist.git
cd mana-dist
cp .env.example .env
./bootstrap.sh
./build.sh
docker compose -f compose.dev.yml up -d
./seed.sh jose
```

El workspace queda asi:

```text
mana-workspace/
  mana-dist/
  mana-ui/
  mana-hub/
  mana-hive/
  mana-cox/
```

`compose.dev.yml` es el entorno integrado: monta los JARs generados por `build.sh`,
expone los puertos de debug y contiene PostgreSQL, MongoDB, NATS, Hub, Hive, bridge,
Cox y UI. Para un ciclo de desarrollo con hot reload, ejecuta UI/Java desde sus
repositorios y usa Docker solo para las bases y NATS.

### Fabricar una distribucion

Desde un checkout con Docker, Java 25, Gradle, Node y pnpm:

```bash
./release.sh 1.0.0
```

El proceso compila los proyectos en los commits fijados por `repos.env`, genera las
cache JVM AOT, construye las imagenes y crea:

```text
mana-dist-1.0.0.tar.gz
```

El paquete contiene imagenes Docker, Compose, configuracion, seed, manifest y
`SHA256SUMS`. En el servidor de destino:

```bash
tar -xzf mana-dist-1.0.0.tar.gz
cd mana-dist-1.0.0
cp .env.example .env
# Editar .env y establecer un secreto real
./scripts/install.sh
```

La release no necesita un registry publico. Para usar un registry privado, se puede
reemplazar `docker save/load` por `docker push/pull`.

## Puertos

Los puertos del host se configuran en `.env`. Dentro de Docker siempre se usan los
 nombres de servicio:

| Servicio | Host dev/edge | Docker |
|---|---:|---:|
| UI | 3000 | 80 |
| Hub | 8080 | 8080 |
| bridge | 8090 | 8090 |
| Cox | 8091 | 8091 |
| Hive | 18081 | 8081 |
| PostgreSQL | 5432 | 5432 |
| MongoDB | 27017 | 27017 |
| NATS | 4222 | 4222 |

Los Compose usan `postgres`, `mongo`, `nats`, `mana-hub` y `mana-hive` como DNS
interno. No usar `localhost` entre contenedores.

## Datos y configuracion

- PostgreSQL, MongoDB y NATS viven en volumenes persistentes.
- `config/` contiene configuracion versionada y perfiles de ejemplo.
- `shared/logs/` y caches AOT son datos locales y estan ignorados por Git.
- Nunca usar las credenciales de `.env.example` en produccion.
- Flyway es responsabilidad de `mana-hub`; el seed se ejecuta despues de las migraciones.

## Seed

El seed de desarrollo es idempotente:

```bash
./seed.sh jose
```

Crea el escenario Manantial y asigna a Jose a `bed-103`. Para limpiar episodios y
eventos de ese escenario:

```bash
./scripts/clean-jose.sh
```

El reset de volumenes es destructivo:

```bash
docker compose -f compose.dev.yml down -v
```

## Validacion

```bash
docker compose -f compose.dev.yml config --quiet
docker compose -f compose.edge.yml config --quiet
curl http://localhost:3000/
curl http://localhost:8080/actuator/health
```

## Documentacion

- `docs/playbooks/development.md`
- `docs/playbooks/release.md`
- `docs/playbooks/production-install.md`
- `docs/playbooks/clean-room-validation.md`
- `docs/configuration.md`
- `docs/operations.md`

## Versiones

Las referencias de `repos.env` son commits, no ramas. Para cambiar una dependencia,
actualiza el commit, ejecuta la validacion completa y crea una nueva release.
