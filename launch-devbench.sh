#!/bin/bash

DEVBENCH_DIR="/home/brett/projects/DevBench/FlutterBench"
CONTAINER_NAME="flutter_bench"

cd "$DEVBENCH_DIR"

echo "🚀 DevFlutter - Starting FlutterBench Container..."

# Check if container is already running
if docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "✅ Container is already running, connecting..."
else
    echo "🔧 Container not running, starting it first..."
    ./start-monster.sh
    
    # Wait a moment for container to fully start
    sleep 3
    
    # Check if it started successfully
    if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "❌ Failed to start container. Check Docker logs."
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

echo "🔗 Connecting to FlutterBench container..."
echo "📁 You'll be in: /workspace (your projects folder)"
echo "🛠️  Available: Flutter, Android SDK, Firebase, Shorebird, and 15+ Flutter tools"
echo ""

# Connect to the container
docker exec -it "$CONTAINER_NAME" zsh