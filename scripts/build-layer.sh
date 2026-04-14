#!/bin/bash
# Build Layer 2 and ensure Layer 3 (flutter-bench)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$REPO_DIR/scripts/lib/image-names.sh"

USERNAME=${1:-$(whoami)}
if [ "$USERNAME" = "--user" ]; then
    USERNAME="${2:-$(whoami)}"
fi

BASE_IMAGE="$(resolve_family_base_image dev "$USERNAME" || true)"
if [ -z "$BASE_IMAGE" ]; then
    echo "⚠ Base image '$(family_base_image dev)' not found. Building automatically..."
    "${SCRIPT_DIR}/../../base-image/build.sh" --user "$USERNAME"
fi

"${SCRIPT_DIR}/build-layer2.sh" --user "$USERNAME"
exec "${REPO_DIR}/scripts/ensure-layer3.sh" --base "flutter-bench:latest" --user "$USERNAME" --chown "/opt/flutter /opt/android-sdk"
