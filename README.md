# 🚀 FlutterBench - Flutter Development Environment

A comprehensive Flutter development environment with DevContainer templates and project creation tools.

## 🧱 Container Architecture (Layered)

FlutterBench is standardizing on the layered workBenches model:
- **Layer 0**: `workbench-base:latest`
- **Layer 1a**: `dev-bench-base:latest`
- **Layer 2**: `flutter-bench:latest` (bench-specific tools)
- **Layer 3**: `flutter-bench:{user}` (user image built from Layer 2)

### Legacy Note
Any monolithic `.devcontainer/` Dockerfiles are **deprecated**. The layered images are the source of truth going forward.

## Bench Image Workflow

Use these commands for the bench itself:

```bash
# Check whether Flutter bench images are current
./scripts/rebuild-stack.sh --check

# Rebuild Layer 2 and Layer 3
./scripts/build-layer.sh

# Start the bench container from the prebuilt user image
./scripts/start-monster.sh
```

`./scripts/start-monster.sh` no longer builds a monolithic devcontainer image. It ensures `flutter-bench:latest` exists, refreshes `flutter-bench:${USER}` if needed, and then starts the bench container from the layered image.

## 🎯 Purpose

FlutterBench provides two ways to create Flutter projects with DevContainer support:

1. **🤖 Automated Setup** - Use `new-flutter-project.sh` for quick, standardized project creation
2. **🔧 Manual Setup** - Copy templates manually for maximum customization control

## 📁 Structure

```
flutterBench/
├── scripts/
│   ├── new-flutter-project.sh        # Automated project creation
│   ├── new-dartwing-project.sh       # DartWing project creation  
│   ├── update-flutter-project.sh     # Update existing projects
│   ├── launch-devbench.sh           # Launch development container
│   └── start-monster.sh             # Container startup script
├── templates/
│   └── flutter-devcontainer-template/  # DevContainer template
│       ├── .devcontainer/            # VS Code DevContainer config
│       ├── .vscode/                  # VS Code settings & tasks
│       ├── scripts/
│       │   ├── manual-setup-project.sh  # Manual setup validation
│       │   └── README.md             # Script usage guide
│       ├── .env.example             # Environment template
│       └── README.md               # Template documentation
└── docs/                           # Additional documentation
```

## 🚀 Getting Started

### Option 1: Automated Setup (Recommended)

**Best for**: New projects, standardized setup, quick start

```bash
# Navigate to flutterBench scripts
cd /path/to/workBenches/devBenches/flutterBench/scripts

# Create new Flutter project with DevContainer
./new-flutter-project.sh my-flutter-app

# Or specify custom target directory  
./new-flutter-project.sh my-flutter-app ~/projects/special-projects
```

**What it does automatically:**
- ✅ Creates Flutter project using `flutter create`
- ✅ Copies and configures DevContainer template
- ✅ Sets up environment variables (`.env`)
- ✅ Configures user UID/GID for proper permissions
- ✅ Sets up infrastructure paths
- ✅ Includes specKit for spec-driven development
- ✅ Ready to open in VS Code

### Option 2: Manual Setup (Advanced)

**Best for**: Existing projects, template customization, learning/understanding

```bash
# 1. Create or navigate to your Flutter project
flutter create my-flutter-app  # or use existing project
cd my-flutter-app

# 2. Copy template files
TEMPLATE_PATH="/path/to/workBenches/devBenches/flutterBench/templates/flutter-devcontainer-template"
cp -r "$TEMPLATE_PATH/.devcontainer" .
cp -r "$TEMPLATE_PATH/.vscode" .
cp -r "$TEMPLATE_PATH/scripts" .
cp "$TEMPLATE_PATH/.env.example" .

# 3. Set up environment configuration
cp .env.example .env
# Edit .env file with your project settings...

# 4. Validate setup (IMPORTANT!)
./scripts/manual-setup-project.sh
```

**When to use manual setup:**
- ✅ Adding DevContainer to existing Flutter project
- ✅ Need to customize template before applying
- ✅ Working with non-standard directory structure
- ✅ Want to understand how the template works
- ✅ Debugging container configuration issues

## 📋 Key Differences

| Feature | Automated Setup | Manual Setup |
|---------|----------------|-------------|
| **Speed** | ⚡ Fast (single command) | 🐢 Multiple steps required |
| **Control** | 🎯 Standardized | 🔧 Full customization |
| **Validation** | ✅ Built-in | 📋 Manual validation required |
| **Learning** | 📦 Black box | 🎓 Educational |
| **Best For** | New projects | Existing projects, customization |
| **Difficulty** | 🟢 Easy | 🟡 Intermediate |

## 🔧 Manual Setup Validation

**⚠️ IMPORTANT**: When using manual setup, you **MUST** run the validation script:

```bash
./scripts/manual-setup-project.sh
```

This script:
- 🔍 Creates `.env` from `.env.example` if missing  
- ✅ Validates all required environment variables
- 🔧 Checks variable formats and values
- 🐳 Verifies Docker environment
- 📋 Tests container configuration
- 🏗️ Validates infrastructure paths

**📖 For detailed manual setup guidance**, see [`templates/flutter-devcontainer-template/scripts/README.md`](templates/flutter-devcontainer-template/scripts/README.md)

## 💡 Which Approach Should I Use?

### Use **Automated Setup** when:
- ✅ Creating a new Flutter project from scratch
- ✅ You want standard workBenches project structure
- ✅ You need to get started quickly
- ✅ You trust the default configuration
- ✅ You're new to DevContainers

### Use **Manual Setup** when:
- ✅ Adding DevContainer to existing Flutter project
- ✅ You need custom template modifications
- ✅ Working with unique directory structures
- ✅ You want to learn how DevContainers work
- ✅ Debugging container issues
- ✅ You need maximum control over the setup process

## ⚙️ Centralized Configuration Philosophy

**Key Principle: The `.env` file is the single source of truth for ALL project and user-specific configuration.**

### What This Means:
- ✅ **Template files remain untouched** - `devcontainer.json`, `docker-compose.yml`, etc. are never modified
- ✅ **All customization via environment variables** - container names, user settings, versions, ports
- ✅ **Project-specific settings isolated** - each project has its own `.env` file
- ✅ **Easy template updates** - template improvements don't conflict with your settings

### Configuration Examples:

```bash
# .env file controls everything:
PROJECT_NAME=dartwing
APP_CONTAINER_SUFFIX=app           # Results in: dartwing-app
SERVICE_CONTAINER_SUFFIX=gateway   # Results in: dartwing-gateway  
USER_UID=1000
FLUTTER_VERSION=3.24.0
COMPOSE_PROJECT_NAME=dartwingers
```

**Result**: Template files use `${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}` → resolves to `dartwing-app`

## 🚀 Next Steps After Setup

Regardless of which setup method you used:

1. **Open in VS Code**: `code .`
2. **Reopen in Container**: Click prompt or Ctrl+Shift+P → "Dev Containers: Reopen in Container"
3. **Wait for build**: First time takes 2-5 minutes
4. **Start coding**: Container includes Flutter SDK, Android tools, and VS Code extensions

## 🔧 Available Scripts

### Project Creation
- `scripts/new-flutter-project.sh` - Create new Flutter project with DevContainer
- `scripts/new-dartwing-project.sh` - Create new DartWing project variant

### Project Management  
- `scripts/update-flutter-project.sh` - Update existing project to latest template
- `templates/.../scripts/manual-setup-project.sh` - Validate manual setup

### Development Environment
- `scripts/launch-devbench.sh` - Launch development container
- `scripts/start-monster.sh` - Ensure Layer 2 and Layer 3, then start the bench container
- `scripts/rebuild-stack.sh` - Check or rebuild the Flutter bench image stack
- `scripts/ensure-images.sh` - Lightweight Layer 2/Layer 3 check for devcontainer startup

## 📚 Documentation

- [`templates/flutter-devcontainer-template/README.md`](templates/flutter-devcontainer-template/README.md) - Template details
- [`templates/flutter-devcontainer-template/scripts/README.md`](templates/flutter-devcontainer-template/scripts/README.md) - Manual setup guide
- [`docs/env-file-docker-compose-guide.md`](docs/env-file-docker-compose-guide.md) - Environment configuration guide

## 🎯 Template Features

The DevContainer template includes:

- 🐳 **Lightweight container** (~500MB vs 2GB+ FlutterBench)
- 🔧 **Centralized configuration** - ALL project and user settings in `.env` file only
- 📝 **No template file modification** - template files remain untouched, use environment variables
- 🏷️ **Configurable container naming** - customize app and service container names via `.env`
- 📱 **Shared ADB infrastructure** (connects to external ADB server)
- ⚙️ **VS Code integration** (tasks, launch configs, extensions)
- 🏗️ **Proper user permissions** (UID/GID matching)
- 🔄 **Hot reload support** (port forwarding configured)
- 🧪 **Testing support** (launch configurations)
- 📋 **Spec-driven development** (includes specKit)

## 🏗️ Container Philosophy

- **FlutterBench** = Heavy development workbench (~2GB, all tools)
- **Project Containers** = Lightweight project-specific environment (~500MB)

Use FlutterBench for heavy development, project containers for debugging and light development.
