# Flutter DevContainer Template

Version: 1.4.0  
Template: flutter-devcontainer-1.4.0

## Overview

This is a comprehensive Flutter development container template that provides:
- **Flutter SDK** with configurable version
- **Android SDK** for mobile development
- **AI CLI Tools** (Codex, Claude Code, Gemini)
- **Development Tools** (Git, Zsh, Oh My Zsh, ImageMagick)
- **VS Code Extensions** for Flutter, Dart, and AI assistants

## Quick Start

### 1. Configure Environment

Copy the environment template and customize:

```bash
cp .devcontainer/.env.example .devcontainer/.env
```

Edit `.env` and set:
- `PROJECT_NAME` - Unique name for your project
- `FLUTTER_VERSION` - Flutter version (e.g., `stable`, `3.24.0`)
- `USER_NAME`, `USER_UID`, `USER_GID` - Match your host user

### 2. Enable AI CLI Tools (Optional)

If you have AI CLI tools authenticated on your host:

1. Edit `.devcontainer/docker-compose.override.yml`
2. Uncomment the AI CLI volume mounts:
   - `~/.codex:/home/${USER}/.codex:cached` for Codex
   - `~/.claude:/home/${USER}/.claude:cached` for Claude Code
   - `~/.gemini:/home/${USER}/.gemini:cached` for Gemini

### 3. Open in VS Code

```bash
code .
```

Then select "Reopen in Container" when prompted.

## Features

### Built-in Extensions

- **Flutter/Dart**: Dart-Code.dart-code, Dart-Code.flutter
- **AI Assistants**: Claude Code, Codex, GitHub Copilot, Gemini
- **Docker**: ms-azuretools.vscode-docker
- **Git**: eamodio.gitlens
- **Utilities**: Prettier, YAML, Tailwind CSS

### Terminal Profiles

Three terminal profiles are available:
- **zsh** (default) - Standard Zsh shell
- **Codex** - Opens with Codex CLI
- **Claude Code** - Opens with Claude CLI

### Ports

- `8080` - Flutter Hot Reload
- `9100` - Flutter DevTools
- `1455` - Codex auth callback

## Directory Structure

```
.devcontainer/
├── devcontainer.json          # Main devcontainer configuration
├── Dockerfile                 # Container image definition
├── docker-compose.yml         # Base compose configuration
├── docker-compose.override.yml # Local overrides (gitignored)
├── .env.base                  # Environment template
├── .env.example               # Environment example (copy to .env)
├── assets/
│   └── claude-logo.svg        # Claude Code extension fix
└── scripts/
    ├── setup-flutter.sh       # Initial Flutter setup
    └── ...                    # Other helper scripts
```

## Environment Variables

Key variables in `.env`:

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_NAME` | Container and project identifier | `myapp` |
| `FLUTTER_VERSION` | Flutter SDK version | `stable` or `3.24.0` |
| `USER_NAME` | Container user (match host) | `$(whoami)` |
| `USER_UID` | User ID (match host) | `$(id -u)` |
| `USER_GID` | Group ID (match host) | `$(id -g)` |
| `CONTAINER_MEMORY` | Memory limit | `4g` |
| `CONTAINER_CPUS` | CPU limit | `2` |

## Version History

### 1.4.0 (Current)
- Enhanced AI CLI integration (Codex, Claude Code, Gemini)
- Added terminal profiles for AI assistants
- Improved port forwarding attributes
- Added docker-compose.override.yml support
- Enhanced VS Code extension set
- Added Claude logo fix for extension

### 1.3.0
- Initial template release
- Basic Flutter and Android SDK setup
- Docker Compose configuration

## Troubleshooting

### Flutter not found

Run inside the container:
```bash
flutter doctor -v
```

### AI CLI not authenticated

1. Check mounts in `docker-compose.override.yml`
2. Verify host authentication: `claude auth status` or `codex status`
3. Rebuild container after adding mounts

### Permission issues

Ensure `.env` has correct UID/GID:
```bash
echo "USER_UID=$(id -u)" >> .env
echo "USER_GID=$(id -g)" >> .env
```

## Support

For issues or questions:
1. Check `.devcontainer/docs/` for additional documentation
2. Review scripts in `.devcontainer/scripts/`
3. Run `flutter doctor -v` for Flutter-specific issues

<citations>
<document>
<document_type>RULE</document_type>
<document_id>2Kb8uDHQxvHzpfbQcgxu2E</document_id>
</document>
<document>
<document_type>RULE</document_type>
<document_id>DV9Ij5hJwiVBE8CyBTMOLd</document_id>
</document>
</citations>
