# Centralized Configuration Architecture
## Complete Guide for FlutterBench Templates

---

## 🎯 Philosophy: Single Source of Truth

**The `.env` file is the ONLY place for project and user-specific configuration.**

### What This Means

- 🚫 **Template files are NEVER modified** - `devcontainer.json`, `docker-compose.yml`, etc. remain untouched
- ✅ **All customization via environment variables** - Container names, user settings, versions, ports  
- ✅ **Perfect template reusability** - Same template works for unlimited projects
- ✅ **Conflict-free updates** - Template improvements never break your settings
- ✅ **Configurable container naming** - Control both app and service container names

---

## 🏗️ Architecture Overview

### Before: Template File Modification (Old Way)
```yaml
# BAD: Had to modify docker-compose.yml for each project
services:
  app:
    container_name: dartwing-app  # ← Hard-coded, different per project
```

### After: Environment Variable Substitution (New Way)  
```yaml
# GOOD: Template file never changes
services:
  app:
    container_name: ${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}  # ← From .env
```

```bash
# .env file (project-specific)
PROJECT_NAME=dartwing
APP_CONTAINER_SUFFIX=app
# Result: dartwing-app
```

---

## 🔧 Container Naming System

### App Container Naming
```bash
# .env configuration
PROJECT_NAME=myproject
APP_CONTAINER_SUFFIX=app

# Template uses: ${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}
# Result: myproject-app
```

### Service Container Naming (Multi-service Projects)
```bash
# .env configuration  
PROJECT_NAME=dartwing
SERVICE_CONTAINER_SUFFIX=gateway

# Template uses: ${PROJECT_NAME}-${SERVICE_CONTAINER_SUFFIX}
# Result: dartwing-gateway
```

### Complete Example: Dartwing Project
```bash
# .env file
PROJECT_NAME=dartwing
APP_CONTAINER_SUFFIX=app
SERVICE_CONTAINER_SUFFIX=gateway
COMPOSE_PROJECT_NAME=dartwingers

# Results in:
# - Container: dartwing-app (Flutter)
# - Container: dartwing-gateway (Service)  
# - Docker stack: dartwingers
```

---

## 📋 Complete Variable Reference

### Project Configuration
```bash
# Base project identity
PROJECT_NAME=myproject                    # Base name for all resources

# Container naming (configurable suffixes)
APP_CONTAINER_SUFFIX=app                  # App container: PROJECT_NAME-app
SERVICE_CONTAINER_SUFFIX=service          # Service container: PROJECT_NAME-service

# Docker Compose stack
COMPOSE_PROJECT_NAME=flutter              # Stack name (dartwingers for Dartwingers projects)
NETWORK_NAME=dartnet                      # Docker network name
```

### User Configuration
```bash
# User identity (should match host user)
USER_NAME=vscode                          # Username inside container
USER_UID=1000                            # User ID (run 'id -u')
USER_GID=1000                            # Group ID (run 'id -g')
```

### Development Environment
```bash
# Flutter SDK
FLUTTER_VERSION=3.24.0                    # Flutter version to install
ANDROID_HOME=/home/vscode/android-sdk     # Android SDK path
FLUTTER_PUB_CACHE=/home/vscode/.pub-cache # Flutter pub cache path

# Container resources
CONTAINER_MEMORY=4g                       # RAM limit
CONTAINER_CPUS=2                          # CPU limit

# Development ports
HOT_RELOAD_PORT=8080                      # Flutter hot reload
DEVTOOLS_PORT=9100                        # Flutter DevTools
```

### ADB Configuration
```bash
# Shared ADB server
ADB_SERVER_HOST=shared-adb-server         # ADB server hostname
ADB_SERVER_PORT=5037                      # ADB server port
ADB_INFRASTRUCTURE_PROJECT_NAME=infrastructure  # ADB infrastructure stack name
```

### Service Configuration (Dartwingers Only)
```bash
# .NET service ports
SERVICE_PORT=5000                         # .NET API port
SERVICE_DEBUG_PORT=5001                   # HTTPS debug port

# Service container resources  
SERVICE_MEMORY=2g                         # Service container RAM
SERVICE_CPUS=1                            # Service container CPUs
```

---

## 🔄 How Environment Variables Flow

### 1. VS Code Starts Container
```
1. VS Code reads devcontainer.json
2. devcontainer.json uses: "name": "${localEnv:PROJECT_NAME}"
3. VS Code reads .env file automatically  
4. PROJECT_NAME=dartwing becomes container display name "dartwing"
```

### 2. Docker Compose Starts
```
1. Docker Compose reads docker-compose.yml
2. Docker Compose automatically reads .env file
3. ${PROJECT_NAME}-${APP_CONTAINER_SUFFIX} becomes dartwing-app
4. All environment variables substituted before container creation
```

### 3. Container Built (If Needed)
```
1. Dockerfile receives build ARGs from .env via docker-compose.yml
2. USER_UID, FLUTTER_VERSION, etc. used during image build
3. ARG values discarded after build (not in running container)
```

### 4. Container Runs
```
1. Container starts with environment variables from .env
2. Runtime ENV variables available to applications
3. Container name, user, resources all configured from .env
```

---

## 📁 File Structure & Responsibilities

### Template Files (Never Modified)
```
.devcontainer/
├── devcontainer.json          # Uses ${localEnv:PROJECT_NAME}
├── docker-compose.yml         # Uses ${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}
├── docker-compose.override.yml # Uses ${PROJECT_NAME}-${SERVICE_CONTAINER_SUFFIX}
├── Dockerfile                 # Receives ARG from .env via compose
├── .env.example               # Template (checked into git)
└── .env.base                  # Template base (checked into git)
```

### Project-Specific Files
```
.env                           # Your configuration (NOT in git)
```

### Generated/Copied Files
```
.vscode/                       # Copied from template, can be customized
scripts/                       # Copied from template, can be customized  
```

---

## ✅ Best Practices

### 1. Never Modify Template Files
```bash
# ❌ WRONG - Don't edit template files
nano .devcontainer/docker-compose.yml
nano .devcontainer/devcontainer.json

# ✅ CORRECT - Only edit .env
nano .env
```

### 2. Use Descriptive Project Names
```bash
# ✅ Good - Clear, unique names
PROJECT_NAME=dartwing
PROJECT_NAME=ledgerlinc
PROJECT_NAME=mycompany-webapp

# ❌ Bad - Generic, conflicts likely
PROJECT_NAME=myproject
PROJECT_NAME=app
PROJECT_NAME=test
```

### 3. Match Host User Permissions
```bash
# Check your host user
id -u  # Your UID (e.g., 1000)
id -g  # Your GID (e.g., 1000)

# Set in .env to match
USER_UID=1000
USER_GID=1000
```

### 4. Keep .env Out of Git
```gitignore
# .gitignore
.env
.env.local
.env.*.local

# But keep templates in git
.env.example
.env.base
```

---

## 🔄 Update Process

### Template Updates are Safe
1. Template improvements happen in `templates/flutter-devcontainer-template/`
2. Your `.env` file remains unchanged
3. Copy updated template files over your project
4. Your configuration automatically applies to new template

### Project Updates
```bash
# Update your project with latest template
cd /path/to/workBenches/devBenches/flutterBench/scripts
./update-flutter-project.sh /path/to/your/project

# Your .env settings are preserved and applied to updated template
```

---

## 🛠️ Troubleshooting

### Check Variable Substitution
```bash
# See what Docker Compose will use (with variables resolved)
docker-compose config

# Should show: 
#   container_name: dartwing-app  # (not ${PROJECT_NAME}-${APP_CONTAINER_SUFFIX})
```

### Verify .env is Being Read
```bash
# Test: Change PROJECT_NAME in .env
echo "PROJECT_NAME=testname" > .env

# Check result
docker-compose config | grep container_name
# Should show: container_name: testname-app
```

### Common Issues

#### Variables Not Substituted
**Symptom**: Container name is literally `${PROJECT_NAME}-app`
**Cause**: `.env` file missing or wrong location
**Solution**: Ensure `.env` is in same directory as `docker-compose.yml`

#### Wrong Values Used  
**Symptom**: Using default values instead of your .env values
**Cause**: Syntax error in `.env` file
**Solution**: Check for spaces around `=`, quotes, or invalid characters

---

## 📊 Comparison: Old vs New

| Aspect | Old Approach | New Centralized Approach |
|--------|-------------|--------------------------|
| **Configuration Location** | Multiple files | Single `.env` file |
| **Template Reusability** | Manual editing required | Copy & configure .env only |  
| **Update Conflicts** | Frequent merge conflicts | Zero conflicts |
| **Container Naming** | Hard-coded in templates | Configurable via .env |
| **Project Setup Time** | 10+ manual edits | 1 .env file edit |
| **Template Updates** | Manual merge required | Automatic application |
| **Debugging Config** | Check multiple files | Check one .env file |

---

## 🎯 Quick Start Checklist

1. ✅ **Copy template files** (never edit them)
2. ✅ **Copy .env.example to .env** 
3. ✅ **Edit .env only** - set PROJECT_NAME, USER_UID, etc.
4. ✅ **Run validation script** (for manual setup)
5. ✅ **Open in VS Code** - all configuration applied automatically

**That's it!** The centralized configuration system handles everything else.

---

## 💡 Advanced Configuration Examples

### Multi-Service Dartwing Project
```bash
# .env
PROJECT_NAME=dartwing
APP_CONTAINER_SUFFIX=app
SERVICE_CONTAINER_SUFFIX=gateway
COMPOSE_PROJECT_NAME=dartwingers
SERVICE_PORT=5000
```

### Development vs Production Configurations
```bash
# .env.development
PROJECT_NAME=myapp-dev  
FLUTTER_VERSION=3.24.0
CONTAINER_MEMORY=8g

# .env.production  
PROJECT_NAME=myapp-prod
FLUTTER_VERSION=3.19.0  # Stable version
CONTAINER_MEMORY=4g
```

### Multiple Flutter Versions
```bash
# project1/.env
FLUTTER_VERSION=3.24.0  # Latest

# project2/.env  
FLUTTER_VERSION=3.19.6  # Legacy compatibility
```

---

## 📚 Related Documentation

- [`env-file-docker-compose-guide.md`](env-file-docker-compose-guide.md) - Detailed .env file usage
- [`flutter-devcontainer-networking-guide.md`](flutter-devcontainer-networking-guide.md) - Network configuration
- [`../templates/flutter-devcontainer-template/README.md`](../templates/flutter-devcontainer-template/README.md) - Template documentation

---

**The centralized configuration architecture makes FlutterBench templates infinitely reusable while keeping all customization simple and conflict-free.** 🎯