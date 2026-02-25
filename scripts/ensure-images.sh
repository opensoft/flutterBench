#!/bin/bash
# Ensure Docker images exist before devcontainer starts
# Called by devcontainer.json initializeCommand
#
# This is a lightweight check — if the final image exists, it exits immediately.
# If any layer is missing, it delegates to rebuild-stack.sh for cascading builds.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$(whoami)

IMAGE="flutter-bench:${USERNAME}"

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "✓ Image '$IMAGE' found. Skipping rebuild."
    exit 0
fi

echo "⚠ Image '$IMAGE' not found. Running rebuild-stack.sh..."
echo ""

exec "$SCRIPT_DIR/rebuild-stack.sh" --user "$USERNAME"
