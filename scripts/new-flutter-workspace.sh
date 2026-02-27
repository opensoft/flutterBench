#!/bin/bash
set -e

# Script metadata for version tracking
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="new-flutter-workspace.sh"

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_BENCH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }
log_section() { echo -e "\n${BLUE}==========================================${NC}\n${BLUE}$*${NC}\n${BLUE}==========================================${NC}\n"; }
log_subsection() { echo -e "${CYAN}$*${NC}"; }

die() {
    log_error "$*"
    exit 1
}

# NATO phonetic alphabet for workspace naming
NATO_ALPHABET=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu)

# Function to get next workspace name
get_next_workspace_name() {
    local flutter_bench_root="$1"
    local workspaces_dir="${flutter_bench_root}/workspaces"
    
    # If no workspaces exist, return first name
    if [ ! -d "$workspaces_dir" ] || [ -z "$(ls -A "$workspaces_dir" 2>/dev/null)" ]; then
        echo "${NATO_ALPHABET[0]}"
        return
    fi
    
    # Find all NATO phonetic workspace names
    local existing_workspaces=()
    for dir in "${workspaces_dir}"/*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            # Check if it's a NATO phonetic name
            for nato_name in "${NATO_ALPHABET[@]}"; do
                if [ "$basename" = "$nato_name" ]; then
                    existing_workspaces+=("$basename")
                    break
                fi
            done
        fi
    done
    
    # Find the last NATO name in sequence
    local last_index=-1
    for i in "${!NATO_ALPHABET[@]}"; do
        local nato_name="${NATO_ALPHABET[$i]}"
        for existing in "${existing_workspaces[@]}"; do
            if [ "$existing" = "$nato_name" ]; then
                last_index=$i
            fi
        done
    done
    
    # Return next name in sequence
    local next_index=$((last_index + 1))
    if [ $next_index -lt ${#NATO_ALPHABET[@]} ]; then
        echo "${NATO_ALPHABET[$next_index]}"
    else
        log_error "All NATO phonetic names exhausted!"
        return 1
    fi
}

# Main script
log_section "Flutter Workspace Creator v${SCRIPT_VERSION}"

# Check if template exists
if [ ! -d "${FLUTTER_BENCH_ROOT}/template/.devcontainer" ]; then
    die "Flutter template not found at ${FLUTTER_BENCH_ROOT}/template/.devcontainer"
fi

# Create workspaces directory if it doesn't exist
mkdir -p "${FLUTTER_BENCH_ROOT}/workspaces"

# Parse arguments
WORKSPACE_NAME="${1:-}"
PROJECT_TYPE="${2:-flutter}"  # flutter, dartwing, or custom

# If no workspace name provided, auto-detect next one
if [ -z "$WORKSPACE_NAME" ]; then
    WORKSPACE_NAME=$(get_next_workspace_name "$FLUTTER_BENCH_ROOT")
    if [ $? -ne 0 ]; then
        die "Failed to generate next workspace name"
    fi
    log_info "Auto-detected next workspace name: ${WORKSPACE_NAME}"
else
    log_info "Using provided workspace name: ${WORKSPACE_NAME}"
fi

# Validate workspace name (alphanumeric, hyphens, underscores only)
if [[ ! "$WORKSPACE_NAME" =~ ^[a-z0-9_-]+$ ]]; then
    die "Workspace name must contain only lowercase letters, numbers, hyphens, and underscores"
fi

NEW_DIR="${FLUTTER_BENCH_ROOT}/workspaces/${WORKSPACE_NAME}"

echo ""
log_info "Configuration:"
log_info "  Workspace name: ${WORKSPACE_NAME}"
log_info "  Project type: ${PROJECT_TYPE}"
log_info "  Location: ${NEW_DIR}"
echo ""

# Step 1: Create new workspace directory
log_subsection "[1/4] Creating workspace directory..."

if [ -d "$NEW_DIR" ]; then
    die "Workspace ${WORKSPACE_NAME} already exists at ${NEW_DIR}"
fi

mkdir -p "${NEW_DIR}"
log_success "Workspace directory created"

# Step 2: Copy devcontainer template
log_subsection "[2/4] Setting up devcontainer configuration..."

cp -r "${FLUTTER_BENCH_ROOT}/template/.devcontainer" "${NEW_DIR}/.devcontainer"
log_success "Devcontainer template copied"

# Step 3: Configure workspace-specific settings
log_subsection "[3/4] Configuring workspace settings..."

# Calculate unique port based on NATO alphabet index
BASE_PORT=8301  # Flutter base port (different from Frappe's 8201)
NATO_INDEX=-1

for i in "${!NATO_ALPHABET[@]}"; do
    if [ "${NATO_ALPHABET[$i]}" = "$WORKSPACE_NAME" ]; then
        NATO_INDEX=$i
        break
    fi
done

if [ $NATO_INDEX -eq -1 ]; then
    # Not a NATO name, use hash-based port
    log_info "  Custom workspace name, using hash-based port"
    PORT_OFFSET=$(echo -n "$WORKSPACE_NAME" | cksum | cut -d' ' -f1)
    HOST_PORT=$((BASE_PORT + (PORT_OFFSET % 50)))
else
    # Sequential port based on NATO index (alpha=8301, bravo=8302, etc.)
    HOST_PORT=$((BASE_PORT + NATO_INDEX))
fi

# Create/update .env file with workspace-specific settings
cat > "${NEW_DIR}/.devcontainer/.env" << EOF
# Flutter Workspace: ${WORKSPACE_NAME}
WORKSPACE_NAME=${WORKSPACE_NAME}
PROJECT_TYPE=${PROJECT_TYPE}

# Container configuration
CONTAINER_NAME=flutter-${WORKSPACE_NAME}
COMPOSE_PROJECT_NAME=flutter-${WORKSPACE_NAME}
HOST_PORT=${HOST_PORT}

# User configuration
USER=${USER}
UID=${UID}
GID=${GID}

# Flutter/Dart configuration
FLUTTER_VERSION=stable
DART_VERSION=stable

# Development settings
FLUTTER_ROOT=/flutter
PUB_CACHE=/home/developer/.pub-cache
EOF

log_success "Environment configured"
log_info "  Container: flutter-${WORKSPACE_NAME}"
log_info "  Port: ${HOST_PORT}"

# Step 4: Customize devcontainer.json
log_subsection "[4/4] Customizing devcontainer..."

# Replace placeholder with actual workspace name
if [ -f "${NEW_DIR}/.devcontainer/devcontainer.json" ]; then
    sed -i "s/WORKSPACE_NAME/${WORKSPACE_NAME}/g" "${NEW_DIR}/.devcontainer/devcontainer.json"
    log_success "Devcontainer customized"
fi

# Copy other template files if they exist
if [ -f "${FLUTTER_BENCH_ROOT}/template/.gitignore" ]; then
    cp "${FLUTTER_BENCH_ROOT}/template/.gitignore" "${NEW_DIR}/.gitignore"
    log_success "Copied .gitignore"
fi

if [ -d "${FLUTTER_BENCH_ROOT}/template/.vscode" ]; then
    cp -r "${FLUTTER_BENCH_ROOT}/template/.vscode" "${NEW_DIR}/.vscode"
    log_success "Copied VS Code settings"
fi

# Create README for the workspace
cat > "${NEW_DIR}/README.md" << EOF
# Flutter Workspace: ${WORKSPACE_NAME}

## Quick Start

1. Open this folder in VS Code
2. When prompted, click "Reopen in Container"
3. Wait for the container to build
4. Start developing!

## Configuration

- **Container Name**: flutter-${WORKSPACE_NAME}
- **Port**: ${HOST_PORT}
- **Project Type**: ${PROJECT_TYPE}

## Development

The Flutter SDK is pre-installed at \`/flutter\`.

### Create a new Flutter project

\`\`\`bash
flutter create my_app
cd my_app
flutter run
\`\`\`

### Run existing project

\`\`\`bash
flutter pub get
flutter run
\`\`\`

## Accessing the Application

Once running, access your Flutter web app at:
- http://localhost:${HOST_PORT}

## Workspace Management

- **Update workspace**: \`update-workspace ${WORKSPACE_NAME}\`
- **Delete workspace**: \`delete-workspace ${WORKSPACE_NAME}\`
EOF

log_success "Created README.md"

echo ""
log_section "Workspace Created Successfully!"

log_info "Next Steps:"
log_info "  1. Open workspace in VS Code:"
log_info "     ${CYAN}code ${NEW_DIR}${NC}"
log_info ""
log_info "  2. When prompted, click 'Reopen in Container'"
log_info ""
log_info "  3. Create your Flutter project inside the container:"
log_info "     ${CYAN}flutter create my_app${NC}"
log_info ""
log_info "  4. Access at: ${CYAN}http://localhost:${HOST_PORT}${NC}"
echo ""

log_success "Workspace ${WORKSPACE_NAME} is ready!"
