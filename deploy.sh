#!/bin/bash
# Deploy mana-dist edge environment
set -e

echo "=== Mana-Dist Edge Deployment ==="
echo ""

# Check if JARs exist
if [ ! -f "aot-jvm/engines-night-watch-runtime.jar" ]; then
    echo "❌ JARs not found. Run ./build.sh first."
    exit 1
fi

# Check if AOT caches exist
if [ ! -f "cache/app.aot" ] || [ ! -f "cache-hub/app.aot" ] || [ ! -f "cache-bridge/app.aot" ]; then
    echo "⚠️  AOT caches not found. Generating..."
    echo ""
    docker compose -f compose.edge.yml up aotgen-hive aotgen-hub aotgen-bridge
    echo ""
    echo "✓ AOT caches generated"
fi

echo ""
echo "=== Starting services ==="
docker compose -f compose.edge.yml up -d

echo ""
echo "=== Waiting for services ==="
sleep 5

echo ""
echo "=== Service Status ==="
docker compose -f compose.edge.yml ps

echo ""
echo "=== Endpoints ==="
echo "  mana-ui:    http://localhost:3000"
echo "  mana-hive:  http://localhost:18081"
echo "  mana-hub:   http://localhost:8080"
echo "  bridge:     http://localhost:8090"
echo "  NATS:       localhost:4222"
echo "  PostgreSQL: localhost:5432"
echo ""
echo "=== Logs ==="
echo "  docker compose -f compose.edge.yml logs -f"
echo ""
echo "=== Stop ==="
echo "  docker compose -f compose.edge.yml down"
