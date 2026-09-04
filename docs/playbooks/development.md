# Playbook: desarrollo

```bash
cp .env.example .env
./bootstrap.sh
./build.sh
docker compose -f compose.dev.yml up -d
./seed.sh jose
```

Validar UI en `http://localhost:3000` y Hub en `http://localhost:8080`.
Despues de cambiar Java, repetir `./build.sh` y reiniciar el servicio afectado.
