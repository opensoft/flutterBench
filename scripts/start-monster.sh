#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVBENCH_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${DEVBENCH_DIR}/../.." && pwd)"
COMPOSE_PROJECT="dev-bench"

# Get current user info
export UID=$(id -u)
export GID=$(id -g)
export USER=$(whoami)
LAYER2_IMAGE="flutter-bench:latest"
USER_IMAGE="flutter-bench:${USER}"

echo "🚀 Starting the Flutter DevBench Monster Container"
echo "   User: $USER (UID: $UID, GID: $GID)"

# Validate we have the required info
if [ -z "$USER" ] || [ -z "$UID" ] || [ -z "$GID" ]; then
    echo "❌ Error: Could not determine user info"
    echo "   USER=$USER, UID=$UID, GID=$GID"
    exit 1
fi

cd "$DEVBENCH_DIR"

if ! docker image inspect "$LAYER2_IMAGE" >/dev/null 2>&1; then
    echo "🔧 Docker image '$LAYER2_IMAGE' not found. Building Flutter bench layers..."
    ./scripts/build-layer.sh
else
    echo "✓ Base image '$LAYER2_IMAGE' found"
fi

echo ""
echo "🔧 Ensuring user image '$USER_IMAGE'..."
"$REPO_DIR/scripts/ensure-layer3.sh" --base "$LAYER2_IMAGE" --user "$USER" --chown "/opt/flutter /opt/android-sdk"
echo ""
echo "🔧 Starting container with layered image..."

if docker compose -p "$COMPOSE_PROJECT" -f .devcontainer/docker-compose.yml up -d; then
    echo "✅ Container started successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "   - Open VS Code and select 'Reopen in Container'"
    echo "   - Or run: docker exec -it flutter_bench zsh"
    echo ""
    echo "🔍 To check container status:"
    echo "   docker ps | grep flutter_bench"
    echo ""
    echo "📱 Flutter Development Ready:"
    echo "   - Flutter SDK installed at /opt/flutter"
    echo "   - Android SDK with emulator support"
    echo "   - 15+ Flutter development tools"
    echo "   - Firebase, Fastlane, Shorebird ready"
    echo "   - Design workflow with Figma integration"
else
    echo "❌ Container failed to start. Check Docker logs:"
    echo "   docker compose -p $COMPOSE_PROJECT -f .devcontainer/docker-compose.yml logs"
fi
