#!/usr/bin/env bash
# Version: 1.0.1
# Best-effort update for VS Code remote extensions.
#
# Dev Containers installs extension IDs listed in devcontainer.json, but a
# reused remote server can keep an older installed extension or cache entry.
# This script forces Marketplace reinstalls without blocking container attach if
# the Marketplace is temporarily unavailable. With no extension IDs, it reads the
# Flutter bench devcontainer extension list. Use --background from devcontainer
# lifecycle hooks so VS Code attach is not held by slow Marketplace downloads.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVBENCH_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEVCONTAINER_FILE="${DEVCONTAINER_FILE:-${DEVBENCH_DIR}/.devcontainer/devcontainer.json}"
EXTENSIONS_DIR="${HOME}/.vscode-server/extensions"
EXTENSIONS_CACHE_DIR="${HOME}/.vscode-server/extensionsCache"
EXTENSION_UPDATE_TIMEOUT_SECONDS="${EXTENSION_UPDATE_TIMEOUT_SECONDS:-180}"
BACKGROUND=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --background)
            BACKGROUND=true
            shift
            ;;
        --worker)
            # Retained for compatibility with background invocations.
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "ensure-latest-vscode-extension: unknown option: $1" >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

find_code_cli() {
    if command -v code >/dev/null 2>&1; then
        command -v code
        return 0
    fi

    find "${HOME}/.vscode-server/bin" \
        -mindepth 3 \
        -maxdepth 3 \
        -type f \
        -path "*/bin/code-server" \
        -executable \
        -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr \
        | awk 'NR == 1 { print $2 }'
}

load_devcontainer_extensions() {
    if [[ ! -f "$DEVCONTAINER_FILE" ]]; then
        return 1
    fi

    awk '
        found && /\]/ { exit }
        found { print }
        /"extensions"[[:space:]]*:[[:space:]]*\[/ { found = 1 }
    ' "$DEVCONTAINER_FILE" \
        | sed -E 's,//.*$,,' \
        | sed -nE 's/^[[:space:]]*"([^"]+)".*$/\1/p'
}

CODE_CLI="$(find_code_cli || true)"
if [[ -z "$CODE_CLI" ]]; then
    echo "ensure-latest-vscode-extension: VS Code Server CLI not found; skipping extension updates" >&2
    exit 0
fi

if [[ "$#" -gt 0 ]]; then
    EXTENSION_IDS=("$@")
else
    mapfile -t EXTENSION_IDS < <(load_devcontainer_extensions || true)
fi

if [[ "${#EXTENSION_IDS[@]}" -eq 0 ]]; then
    echo "ensure-latest-vscode-extension: no extensions found to update"
    exit 0
fi

if [[ "$LIST_ONLY" == true ]]; then
    printf '%s\n' "${EXTENSION_IDS[@]}"
    exit 0
fi

if [[ "$BACKGROUND" == true ]]; then
    LOG_DIR="${HOME}/.vscode-server/data/logs/flutterbench-extension-updates"
    mkdir -p "$LOG_DIR"
    LOG_FILE="${LOG_DIR}/$(date +%Y%m%dT%H%M%S).log"
    nohup bash "$0" --worker "$@" >"$LOG_FILE" 2>&1 &
    echo "ensure-latest-vscode-extension: update started in background: ${LOG_FILE}"
    exit 0
fi

LOCK_PARENT="${HOME}/.vscode-server/data/Machine"
LOCK_FILE="${LOCK_PARENT}/flutterbench-extension-update.lock"
mkdir -p "$LOCK_PARENT"
if ! command -v flock >/dev/null 2>&1; then
    echo "ensure-latest-vscode-extension: flock is unavailable; skipping extension updates" >&2
    exit 0
fi
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "ensure-latest-vscode-extension: another extension update is already running; skipping"
    exit 0
fi

for extension_id in "${EXTENSION_IDS[@]}"; do
    [[ -n "$extension_id" ]] || continue
    extension_prefix="${extension_id}-"

    echo "ensure-latest-vscode-extension: updating ${extension_id}"
    if [[ -d "$EXTENSIONS_CACHE_DIR" ]]; then
        find "$EXTENSIONS_CACHE_DIR" -maxdepth 1 -iname "${extension_prefix}*" -exec rm -rf {} + 2>/dev/null || true
    fi

    install_cmd=("$CODE_CLI" --install-extension "$extension_id" --force)
    if command -v timeout >/dev/null 2>&1; then
        install_cmd=(timeout "${EXTENSION_UPDATE_TIMEOUT_SECONDS}s" "${install_cmd[@]}")
    fi

    if "${install_cmd[@]}"; then
        :
    else
        status=$?
        if [[ "$status" -eq 124 ]]; then
            echo "ensure-latest-vscode-extension: timed out updating ${extension_id} after ${EXTENSION_UPDATE_TIMEOUT_SECONDS}s; continuing" >&2
        else
            echo "ensure-latest-vscode-extension: failed to update ${extension_id}; continuing" >&2
        fi
        continue
    fi

    if [[ -d "$EXTENSIONS_DIR" ]]; then
        find "$EXTENSIONS_DIR" -maxdepth 1 -type d -iname "${extension_prefix}*" -printf '%f\n' \
            | sort -V \
            | tail -1 \
            | sed 's/^/ensure-latest-vscode-extension: installed /'
    fi
done
