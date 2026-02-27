# DevContainer Check-or-Attach System

## Table of Contents
- [Overview](#overview)
- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [How It Works](#how-it-works)
- [Implementation Details](#implementation-details)
- [User Experience](#user-experience)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Technical Reference](#technical-reference)

---

## Overview

The **Check-or-Attach** system is a smart container lifecycle management feature that dramatically improves the VSCode devcontainer experience by detecting running containers and attaching to them instead of always recreating them.

### Key Benefits

| Before (Force Recreate) | After (Smart Attach) |
|------------------------|---------------------|
| ⏱️ 2-3 minutes every open | ⚡ < 5 seconds on reopen |
| 💥 Kills running processes | 💾 Preserves all state |
| 🔄 Rebuilds everything | 🔌 Just reconnects |
| 😤 Frustrating UX | 😊 Seamless UX |

---

## The Problem

### Traditional DevContainer Behavior

In a standard devcontainer setup, the `initializeCommand` often includes a cleanup step:

```json
"initializeCommand": {
  "cleanup": "docker rm -f myproject-app || true"
}
```

**What happens:**
1. User closes VSCode (container keeps running in background)
2. User reopens VSCode
3. VSCode runs `docker rm -f` → **Kills the running container!**
4. VSCode rebuilds and restarts container → **2-3 minutes**
5. User waits... 😴

### Why This Is Bad

- **Lost State**: Terminal sessions, hot reload, debug sessions all destroyed
- **Wasted Time**: Unnecessary rebuilds when container was perfectly fine
- **Resource Waste**: CPU/memory spikes from constant recreation
- **Poor UX**: Developers frustrated by slow reopens

---

## The Solution

### Smart Check-or-Attach Logic

Instead of blindly removing containers, we **intelligently check** the container state:

```
┌─────────────────────────────────────┐
│  User Opens VSCode                  │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│  Run check-or-attach.sh              │
│  (Before any Docker operations)      │
└──────────────┬───────────────────────┘
               │
               ▼
        Check Container
               │
    ┌──────────┴──────────┬─────────────┐
    │                     │             │
    ▼                     ▼             ▼
┌─────────┐         ┌──────────┐   ┌──────────┐
│ RUNNING │         │ STOPPED  │   │  MISSING │
└────┬────┘         └─────┬────┘   └─────┬────┘
     │                    │              │
     ▼                    ▼              ▼
 Do Nothing          Remove It       Do Nothing
     │                    │              │
     ▼                    ▼              ▼
┌─────────┐         ┌──────────┐   ┌──────────┐
│ ATTACH  │         │ RECREATE │   │  CREATE  │
│  ~5s    │         │  ~3min   │   │  ~3min   │
└─────────┘         └──────────┘   └──────────┘
```

---

## How It Works

### Step-by-Step Flow

#### 1. VSCode Initialization
When you open a devcontainer project, VSCode runs the `initializeCommand` **on your host machine** before any container operations.

#### 2. Script Execution
Our `check-or-attach.sh` script runs:

```bash
#!/bin/bash
# Load config from .env
PROJECT_NAME=dartwing
CONTAINER_NAME="${PROJECT_NAME}-app"

# Check container status
STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
```

#### 3. Decision Logic

The script uses a case statement to handle all scenarios:

```bash
case "$STATUS" in
  "running")
    # Container is healthy and running
    echo "✅ Already running - will attach"
    exit 0  # Do nothing, let VSCode attach
    ;;

  "exited"|"stopped"|"created"|"paused"|"dead")
    # Container exists but not running
    echo "🧹 Stopped container found - cleaning up"
    docker rm -f "$CONTAINER_NAME"
    exit 0  # Let VSCode create fresh
    ;;

  "not_found")
    # No container exists
    echo "📦 No container - will create new"
    exit 0  # Let VSCode create
    ;;
esac
```

#### 4. VSCode Response

Based on the script's outcome:
- **Running container found** → VSCode attaches to existing container
- **Stopped/Missing container** → VSCode creates new container

---

## Implementation Details

### File Structure

```
.devcontainer/
├── devcontainer.json              # References the script
├── docker-compose.yml             # Defines container
├── .env                           # Configuration
│
├── docs/
│   └── CHECK-OR-ATTACH.md        # This file
│
└── scripts/
    ├── check-or-attach.sh        # Core logic
    └── test-smart-attach.sh      # Test suite
```

### Key Files

#### 1. devcontainer.json

```json
{
  "initializeCommand": {
    "check-or-attach": "${localWorkspaceFolder}/.devcontainer/scripts/check-or-attach.sh",
    "adb": "...",
    "dartwingers-check": "..."
  }
}
```

**Critical Notes:**
- Runs on **host machine** (not in container)
- Runs **before** container creation/start
- Has access to host's Docker daemon
- Can inspect existing containers

#### 2. check-or-attach.sh

```bash
#!/bin/bash
set -e  # Exit on error

# Load configuration
source "${SCRIPT_DIR}/../.env"
CONTAINER_NAME="${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}"

# Check container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not_found")

# Trim whitespace (important!)
CONTAINER_STATUS=$(echo "$CONTAINER_STATUS" | tr -d '[:space:]')

# Make decision based on status
case "$CONTAINER_STATUS" in
  "running") # Attach
  "exited")  # Cleanup
  "not_found") # Create
esac
```

**Important Details:**
- Uses `.env` for configuration consistency
- Handles all Docker container states
- Graceful error handling (`|| echo "not_found"`)
- Whitespace trimming prevents matching issues

#### 3. .env Configuration

```bash
# Container naming
PROJECT_NAME=dartwing
APP_CONTAINER_SUFFIX=app

# Results in container name: dartwing-app
```

---

## User Experience

### Scenario 1: First Time Opening

**What Happens:**
```
🔍 Checking for existing container: dartwing-app
📦 No existing container found - will create new container

[VSCode creates container - takes ~2-3 minutes]
[Container builds, starts, initializes]

✅ Ready to code!
```

**Time:** 2-3 minutes (normal first-time setup)

---

### Scenario 2: Reopening Active Project

**What Happens:**
```
🔍 Checking for existing container: dartwing-app
✅ Container dartwing-app is already running
📎 VSCode will attach to the existing container

[VSCode attaches immediately]

✅ Ready to code!
```

**Time:** ~5 seconds ⚡

**Benefits:**
- Terminal sessions preserved
- Hot reload still active
- Debug sessions maintained
- No rebuild needed

---

### Scenario 3: Container Was Stopped

**What Happens:**
```
🔍 Checking for existing container: dartwing-app
🧹 Container dartwing-app exists but is in state: exited
🗑️ Removing stopped container to allow fresh start...
✅ Cleanup complete - will create new container

[VSCode creates fresh container - takes ~2-3 minutes]

✅ Ready to code!
```

**Time:** 2-3 minutes (needed to recreate)

**Why:** Stopped containers may have stale state; better to start fresh

---

## Architecture

### Container State Machine

```
┌─────────────┐
│ NOT_FOUND   │ ◄──────────┐
└──────┬──────┘            │
       │                   │
       │ docker create     │ docker rm
       ▼                   │
┌─────────────┐            │
│  CREATED    │ ───────────┤
└──────┬──────┘            │
       │                   │
       │ docker start      │
       ▼                   │
┌─────────────┐            │
│  RUNNING    │ ◄───────┐  │
└──────┬──────┘         │  │
       │                │  │
       │ docker stop    │  │
       ▼                │  │
┌─────────────┐         │  │
│  EXITED     │ ────────┴──┘
└─────────────┘
```

**Our Handling:**
- `NOT_FOUND` → **Create** new container
- `CREATED` → **Remove** and recreate (stale)
- `RUNNING` → **Attach** to existing
- `EXITED` → **Remove** and recreate (stale)

### VSCode Lifecycle Hooks

```
Host Machine                    Container
─────────────                   ─────────

initializeCommand ────┐
(check-or-attach.sh)  │
                      │
                      ├─→ Container RUNNING?
                      │         ↓ Yes
                      │         ↓
                      │   [ATTACH]
                      │         ↓
postAttachCommand ────┴─→ ready-check.sh
                              ↓
                         ✅ Ready!


                      ├─→ Container NOT RUNNING?
                      │         ↓ Yes
                      │         ↓
                      │   [CREATE/START]
                      │         ↓
onCreateCommand ──────┴─→ (first time only)
                              ↓
postStartCommand ──────→ startup.sh
                              ↓
postAttachCommand ─────→ ready-check.sh
                              ↓
                         ✅ Ready!
```

---

## Troubleshooting

### Issue: Container Always Recreated

**Symptom:** Even when container is running, VSCode recreates it

**Diagnosis:**
```bash
# Test the script manually
cd .devcontainer
./scripts/check-or-attach.sh

# Should output one of:
# ✅ Already running - will attach
# 🧹 Stopped container - cleaning up
# 📦 No container - will create
```

**Solutions:**

1. **Check script permissions:**
   ```bash
   chmod +x .devcontainer/scripts/check-or-attach.sh
   ```

2. **Verify .env exists:**
   ```bash
   ls -la .devcontainer/.env
   # Should exist and be readable
   ```

3. **Check container name:**
   ```bash
   # In .env file
   PROJECT_NAME=dartwing
   APP_CONTAINER_SUFFIX=app

   # Should match running container
   docker ps | grep dartwing-app
   ```

---

### Issue: Script Errors

**Symptom:** Error messages in VSCode output

**Common Errors:**

#### Error: ".env file not found"
```bash
❌ Error: .env file not found at /path/to/.env
```

**Solution:**
```bash
# Check if .env exists
ls .devcontainer/.env

# If not, copy from example
cp .devcontainer/.env.example .devcontainer/.env
```

#### Error: "Permission denied"
```bash
bash: ./scripts/check-or-attach.sh: Permission denied
```

**Solution:**
```bash
chmod +x .devcontainer/scripts/check-or-attach.sh
```

#### Error: "Docker daemon not running"
```bash
Cannot connect to the Docker daemon
```

**Solution:**
- Start Docker Desktop
- Wait for Docker to fully start
- Retry opening VSCode

---

### Issue: Multiple Containers Running

**Symptom:** Several containers with similar names

**Diagnosis:**
```bash
docker ps -a | grep dartwing
# dartwing-app
# dartwing-app-old
# dartwing-app-test
```

**Solution:**
```bash
# Stop and remove extras
docker stop dartwing-app-old dartwing-app-test
docker rm dartwing-app-old dartwing-app-test

# Verify unique PROJECT_NAME in .env
grep PROJECT_NAME .devcontainer/.env
```

---

### Issue: Want to Force Fresh Container

**Symptom:** Container is running but you want a clean start

**Solution:**
```bash
# Manually stop and remove container
docker stop dartwing-app
docker rm dartwing-app

# Then open VSCode
# Will create fresh container
```

---

## Testing

### Manual Testing

Run the test suite to verify the system works:

```bash
cd .devcontainer
./scripts/test-smart-attach.sh
```

**Expected Output:**
```
=====================================
Smart Attach System Test
=====================================

Test 1: No container exists
Expected: Should say 'No existing container found'
---
🔍 Checking for existing container: dartwing-app
📦 No existing container found - will create new container

Test 2: Stopped container exists
Expected: Should say 'exists but is in state: created' and remove it
---
🔍 Checking for existing container: dartwing-app
🧹 Container dartwing-app exists but is in state: created
🗑️  Removing stopped container to allow fresh start...
✅ Cleanup complete - will create new container

Test 3: Running container exists
Expected: Should say 'already running' and 'will attach'
---
🔍 Checking for existing container: dartwing-app
✅ Container dartwing-app is already running
📎 VSCode will attach to the existing container

=====================================
All tests completed!
=====================================
```

### Testing Individual Scenarios

#### Test 1: No Container
```bash
# Ensure no container exists
docker rm -f dartwing-app 2>/dev/null || true

# Run script
./scripts/check-or-attach.sh

# Expected: "📦 No existing container found"
```

#### Test 2: Stopped Container
```bash
# Create stopped container
docker create --name dartwing-app alpine:latest

# Run script
./scripts/check-or-attach.sh

# Expected: "🧹 Container exists but is in state: created"
```

#### Test 3: Running Container
```bash
# Create running container
docker run -d --name dartwing-app alpine:latest sleep infinity

# Run script
./scripts/check-or-attach.sh

# Expected: "✅ Container is already running"

# Cleanup
docker rm -f dartwing-app
```

---

## Technical Reference

### Docker Container States

| State | Description | Our Action |
|-------|-------------|------------|
| `running` | Container actively running | **Attach** |
| `created` | Created but never started | **Remove** → Recreate |
| `exited` | Was running, now stopped | **Remove** → Recreate |
| `paused` | Temporarily suspended | **Remove** → Recreate |
| `restarting` | In restart loop | **Remove** → Recreate |
| `dead` | Container failed | **Remove** → Recreate |
| `not_found` | Doesn't exist | **Create** new |

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| `0` | Success | VSCode proceeds normally |
| `1` | Error (missing .env) | VSCode shows error |

### Environment Variables

From `.env` file:

```bash
# Used to build container name
PROJECT_NAME=dartwing           # Base name
APP_CONTAINER_SUFFIX=app        # Suffix

# Results in: dartwing-app
CONTAINER_NAME="${PROJECT_NAME}-${APP_CONTAINER_SUFFIX}"
```

### Docker Inspect Command

```bash
# Get container status
docker inspect -f '{{.State.Status}}' CONTAINER_NAME

# Possible outputs:
# - "running"
# - "exited"
# - "created"
# - "paused"
# - "restarting"
# - "dead"
# - (error if not found)
```

---

## Advanced Usage

### Debugging the Script

Enable verbose output:

```bash
# Edit check-or-attach.sh
# Add after #!/bin/bash
set -x  # Enable trace mode

# Now run script
./scripts/check-or-attach.sh

# Will show every command executed
```

### Custom Container Names

If you need different naming:

```bash
# In .env
PROJECT_NAME=myproject
APP_CONTAINER_SUFFIX=dev

# Results in: myproject-dev
```

### Integration with CI/CD

For automated testing:

```bash
# In CI pipeline
export PROJECT_NAME=ci-test
export APP_CONTAINER_SUFFIX=app

# Run script
.devcontainer/scripts/check-or-attach.sh

# Check exit code
if [ $? -eq 0 ]; then
  echo "Container check passed"
else
  echo "Container check failed"
  exit 1
fi
```

---

## Performance Metrics

### Time Savings

| Scenario | Before | After | Savings |
|----------|--------|-------|---------|
| First open | 3 min | 3 min | 0% (same) |
| Reopen (running) | 3 min | 5 sec | **97%** ⚡ |
| Reopen (stopped) | 3 min | 3 min | 0% (same) |

### Resource Usage

| Metric | Force Recreate | Smart Attach |
|--------|----------------|--------------|
| Docker pulls | Every open | Only when needed |
| CPU spikes | Every open | Only first time |
| Memory usage | Constant churn | Stable |
| Disk I/O | High | Minimal |

---

## Best Practices

### ✅ Do's

- **Keep container running** when you know you'll return soon
- **Let the script decide** - trust the automatic detection
- **Run tests** after modifying the script
- **Monitor VSCode output** to see what's happening

### ❌ Don'ts

- **Don't manually cleanup** running containers (defeats the purpose)
- **Don't modify script** without understanding the flow
- **Don't ignore errors** - check VSCode output if issues occur
- **Don't use same PROJECT_NAME** for multiple projects

---

## Related Documentation

- [Quick Start Guide](../QUICK-START.md)
- [Smart Attach Overview](../SMART-ATTACH.md)
- [DevContainer Scripts](../scripts/README.md)
- [Android Development](./ANDROID-DEVELOPMENT.md)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-13 | Initial implementation |
| | | - Basic container state detection |
| | | - Attach vs recreate logic |
| | | - Comprehensive testing suite |

---

## Support

### Getting Help

1. **Check VSCode Output:**
   - View → Output
   - Select "Dev Containers"

2. **Run Test Script:**
   ```bash
   ./scripts/test-smart-attach.sh
   ```

3. **Manual Script Test:**
   ```bash
   ./scripts/check-or-attach.sh
   echo $?  # Check exit code
   ```

4. **Check Container Status:**
   ```bash
   docker ps -a | grep dartwing
   docker inspect dartwing-app
   ```

### Common Questions

**Q: Will this work with Docker Compose?**
A: Yes! The script inspects containers created by Docker Compose.

**Q: What if I rename the container?**
A: Update `PROJECT_NAME` and `APP_CONTAINER_SUFFIX` in `.env`

**Q: Does this work on Windows/Mac/Linux?**
A: Yes! Works anywhere Docker runs.

**Q: Can I disable this feature?**
A: Yes, replace the script call with the old force cleanup command.

---

**Last Updated:** 2025-11-13
**Author:** Claude Code
**License:** MIT
