#!/bin/bash
# Ensure Docker images exist before devcontainer starts
# Called by devcontainer.json initializeCommand
#
# This is a lightweight check — if the final image exists, it exits immediately.
# If any layer is missing, it delegates to rebuild-stack.sh for cascading builds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
USERNAME=$(whoami)
LAYER2_IMAGE="flutter-bench:latest"
USER_IMAGE="flutter-bench:${USERNAME}"

if ! docker image inspect "$LAYER2_IMAGE" >/dev/null 2>&1; then
    echo "⚠ Image '$LAYER2_IMAGE' not found. Running rebuild-stack.sh..."
    echo ""
    exec "$SCRIPT_DIR/rebuild-stack.sh" --user "$USERNAME"
fi

echo "✓ Layer 2 image '$LAYER2_IMAGE' found"
echo ""

exec "$REPO_DIR/scripts/ensure-layer3.sh" --base "$LAYER2_IMAGE" --user "$USERNAME" --chown "/opt/flutter /opt/android-sdk"
