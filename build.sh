#!/bin/bash
# Build all JARs for mana-dist deployment
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(dirname "$ROOT")"

echo "=== Building mana-hive JARs ==="
cd "$WORKSPACE/mana-hive"
./gradlew :engines:night-watch-runtime:bootJar --console=plain
echo "✓ mana-hive JAR built"

echo ""
echo "=== Building mana-hub JARs ==="
cd "$WORKSPACE/mana-hub"
./gradlew :bootstrap:bootJar :event-bridge:bootJar --console=plain
echo "✓ mana-hub JARs built"

echo ""
echo "=== Building mana-cox JAR ==="
cd "$WORKSPACE/mana-cox"
gradle :app:bootJar --console=plain
echo "✓ mana-cox JAR built"

echo ""
echo "=== Copying JARs to mana-dist ==="
cd "$ROOT"
cp "$WORKSPACE/mana-hive/engines/night-watch-runtime/build/libs/engines-night-watch-runtime.jar" aot-jvm/
cp "$WORKSPACE/mana-hub/bootstrap/build/libs/bootstrap-1.0.0-SNAPSHOT.jar" aot-jvm/
cp "$WORKSPACE/mana-hub/event-bridge/build/libs/event-bridge-1.0.0-SNAPSHOT.jar" aot-jvm/
cp "$WORKSPACE/mana-cox/app/build/libs/mana-cox.jar" aot-jvm/

echo ""
echo "=== Building mana-ui ==="
cd "$WORKSPACE/mana-ui"
pnpm --filter web build
echo "✓ mana-ui built"
cd "$ROOT"

echo ""
echo "=== Build complete ==="
ls -lh aot-jvm/*.jar

echo ""
echo "=== Next steps ==="
echo "  Development:  docker compose -f compose.dev.yml up -d"
echo "  Production:   ./deploy.sh"
