#!/bin/bash
# Rebuild Docker image stack for flutterBench
# Detects stale layers and rebuilds only what's needed
#
# Usage:
#   ./rebuild-stack.sh           # Rebuild stale layers only
#   ./rebuild-stack.sh --check   # Just report status, don't rebuild
#   ./rebuild-stack.sh --force   # Rebuild all layers regardless of age

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_BENCH_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEV_BENCHES_DIR="$(cd "${FLUTTER_BENCH_DIR}/.." && pwd)"
WORKBENCHES_DIR="$(cd "${DEV_BENCHES_DIR}/.." && pwd)"
source "${WORKBENCHES_DIR}/scripts/lib/image-names.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MODE="rebuild"  # rebuild, check, force
USERNAME=$(whoami)

while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            MODE="check"
            shift
            ;;
        --force)
            MODE="force"
            shift
            ;;
        --user)
            USERNAME="$2"
            shift 2
            ;;
        *)
            USERNAME="$1"
            shift
            ;;
    esac
done

# Image names
LAYER0_IMAGE="workbench-base:latest"
LAYER1_IMAGE="$(resolve_family_base_image dev "$USERNAME" || family_base_image dev)"
LAYER2_IMAGE="flutter-bench:latest"
LAYER3_IMAGE="flutter-bench:${USERNAME}"

# Build script locations
LAYER0_BUILD="${WORKBENCHES_DIR}/base-image/build.sh"
LAYER1_BUILD="${DEV_BENCHES_DIR}/base-image/build.sh"
LAYER2_BUILD="${FLUTTER_BENCH_DIR}/scripts/build-layer.sh"
LAYER3_BUILD="${WORKBENCHES_DIR}/scripts/ensure-layer3.sh"

log_section() {
    echo ""
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get image creation timestamp (returns 0 if image doesn't exist)
get_image_timestamp() {
    local image="$1"
    if docker image inspect "$image" >/dev/null 2>&1; then
        local created
        created=$(docker inspect "$image" --format '{{.Created}}')
        date -d "$created" +%s 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Format timestamp for display
format_timestamp() {
    local ts="$1"
    if [ "$ts" = "0" ]; then
        echo "not built"
    else
        date -d "@$ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"
    fi
}

# Check if image exists
image_exists() {
    docker image inspect "$1" >/dev/null 2>&1
}

log_section "Docker Image Stack Status"

echo "Configuration:"
echo "  Username: ${USERNAME}"
echo "  Mode: ${MODE}"
echo ""

# Get timestamps
TS_LAYER0=$(get_image_timestamp "$LAYER0_IMAGE")
TS_LAYER1=$(get_image_timestamp "$LAYER1_IMAGE")
TS_LAYER2=$(get_image_timestamp "$LAYER2_IMAGE")
TS_LAYER3=$(get_image_timestamp "$LAYER3_IMAGE")

# Display current status
echo "Current Image Status:"
echo "  Layer 0 (${LAYER0_IMAGE}): $(format_timestamp $TS_LAYER0)"
echo "  Layer 1 (${LAYER1_IMAGE}): $(format_timestamp $TS_LAYER1)"
echo "  Layer 2 (${LAYER2_IMAGE}): $(format_timestamp $TS_LAYER2)"
echo "  Layer 3 (${LAYER3_IMAGE}): $(format_timestamp $TS_LAYER3)"
echo ""

# Determine what needs rebuilding
REBUILD_LAYER0=false
REBUILD_LAYER1=false
REBUILD_LAYER2=false
REBUILD_LAYER3=false

if [ "$MODE" = "force" ]; then
    REBUILD_LAYER0=true
    REBUILD_LAYER1=true
    REBUILD_LAYER2=true
    REBUILD_LAYER3=true
    log_warn "Force mode: rebuilding all layers"
else
    # Check Layer 0
    if [ "$TS_LAYER0" = "0" ]; then
        REBUILD_LAYER0=true
        REBUILD_LAYER1=true  # Cascade
        REBUILD_LAYER2=true  # Cascade
        REBUILD_LAYER3=true  # Cascade
        log_warn "Layer 0 missing - full rebuild required"
    fi

    # Check Layer 1
    if [ "$TS_LAYER1" = "0" ]; then
        REBUILD_LAYER1=true
        REBUILD_LAYER2=true  # Cascade
        REBUILD_LAYER3=true  # Cascade
        log_warn "Layer 1 missing - rebuild required"
    elif [ "$TS_LAYER1" -lt "$TS_LAYER0" ] 2>/dev/null; then
        REBUILD_LAYER1=true
        REBUILD_LAYER2=true  # Cascade
        REBUILD_LAYER3=true  # Cascade
        log_warn "Layer 1 is older than Layer 0 - stale"
    fi

    # Check Layer 2
    if [ "$TS_LAYER2" = "0" ]; then
        REBUILD_LAYER2=true
        REBUILD_LAYER3=true  # Cascade
        log_warn "Layer 2 missing - rebuild required"
    elif [ "$TS_LAYER2" -lt "$TS_LAYER1" ] 2>/dev/null; then
        REBUILD_LAYER2=true
        REBUILD_LAYER3=true  # Cascade
        log_warn "Layer 2 is older than Layer 1 - stale"
    fi

    # Check Layer 3
    if [ "$TS_LAYER3" = "0" ]; then
        REBUILD_LAYER3=true
        log_warn "Layer 3 missing - rebuild required"
    elif [ "$TS_LAYER3" -lt "$TS_LAYER2" ] 2>/dev/null; then
        REBUILD_LAYER3=true
        log_warn "Layer 3 is older than Layer 2 - stale"
    fi
fi

echo ""

# Summary
if $REBUILD_LAYER0 || $REBUILD_LAYER1 || $REBUILD_LAYER2 || $REBUILD_LAYER3; then
    echo "Rebuild Plan:"
    $REBUILD_LAYER0 && echo "  → Layer 0: ${LAYER0_IMAGE}"
    $REBUILD_LAYER1 && echo "  → Layer 1: ${LAYER1_IMAGE}"
    $REBUILD_LAYER2 && echo "  → Layer 2: ${LAYER2_IMAGE}"
    $REBUILD_LAYER3 && echo "  → Layer 3: ${LAYER3_IMAGE}"
    echo ""
else
    log_success "All layers are up to date!"
    exit 0
fi

# If check mode, exit here
if [ "$MODE" = "check" ]; then
    echo "Run without --check to rebuild stale layers."
    exit 0
fi

# Perform rebuilds
if $REBUILD_LAYER0; then
    log_section "Building Layer 0: workbench-base"
    if [ ! -f "$LAYER0_BUILD" ]; then
        log_error "Build script not found: ${LAYER0_BUILD}"
        exit 1
    fi
    "$LAYER0_BUILD" --user "$USERNAME"
fi

if $REBUILD_LAYER1; then
    log_section "Building Layer 1: $(family_base_repo dev)"
    if [ ! -f "$LAYER1_BUILD" ]; then
        log_error "Build script not found: ${LAYER1_BUILD}"
        exit 1
    fi
    "$LAYER1_BUILD" --user "$USERNAME"
fi

if $REBUILD_LAYER2; then
    log_section "Building Layer 2: flutter-bench"
    if [ ! -f "$LAYER2_BUILD" ]; then
        log_error "Build script not found: ${LAYER2_BUILD}"
        exit 1
    fi
    "$LAYER2_BUILD" --user "$USERNAME"
    REBUILD_LAYER3=false
fi

if $REBUILD_LAYER3; then
    log_section "Building Layer 3: flutter-bench:${USERNAME}"
    if [ ! -f "$LAYER3_BUILD" ]; then
        log_error "Build script not found: ${LAYER3_BUILD}"
        exit 1
    fi
    "$LAYER3_BUILD" --base "$LAYER2_IMAGE" --user "$USERNAME" --chown "/opt/flutter /opt/android-sdk"
fi

log_section "Stack Rebuild Complete!"

# Show final status
TS_LAYER0=$(get_image_timestamp "$LAYER0_IMAGE")
TS_LAYER1=$(get_image_timestamp "$LAYER1_IMAGE")
TS_LAYER2=$(get_image_timestamp "$LAYER2_IMAGE")
TS_LAYER3=$(get_image_timestamp "$LAYER3_IMAGE")

echo "Final Image Status:"
echo "  Layer 0 (${LAYER0_IMAGE}): $(format_timestamp $TS_LAYER0)"
echo "  Layer 1 (${LAYER1_IMAGE}): $(format_timestamp $TS_LAYER1)"
echo "  Layer 2 (${LAYER2_IMAGE}): $(format_timestamp $TS_LAYER2)"
echo "  Layer 3 (${LAYER3_IMAGE}): $(format_timestamp $TS_LAYER3)"
echo ""
log_success "All workspaces will now use the latest images on next container start."
