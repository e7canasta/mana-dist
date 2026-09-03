#!/bin/bash
# Build all JARs for mana-dist deployment
set -e

echo "=== Building mana-hive JARs ==="
cd ../mana-hive
./gradlew :engines:night-watch-runtime:bootJar --console=plain
echo "✓ mana-hive JAR built"

echo ""
echo "=== Building mana-hub JARs ==="
cd ../mana-hub
./gradlew :bootstrap:bootJar :event-bridge:bootJar --console=plain
echo "✓ mana-hub JARs built"

echo ""
echo "=== Building mana-cox JAR ==="
cd ../mana-cox
gradle :app:bootJar --console=plain
echo "✓ mana-cox JAR built"

echo ""
echo "=== Copying JARs to mana-dist ==="
cd ../mana-dist
cp ../mana-hive/engines/night-watch-runtime/build/libs/engines-night-watch-runtime.jar aot-jvm/
cp ../mana-hub/bootstrap/build/libs/bootstrap-1.0.0-SNAPSHOT.jar aot-jvm/
cp ../mana-hub/event-bridge/build/libs/event-bridge-1.0.0-SNAPSHOT.jar aot-jvm/
cp ../mana-cox/app/build/libs/mana-cox.jar aot-jvm/

echo ""
echo "=== Build complete ==="
ls -lh aot-jvm/*.jar

echo ""
echo "=== Next steps ==="
echo "  Development:  docker compose -f compose.dev.yml up -d"
echo "  Production:   ./deploy.sh"
