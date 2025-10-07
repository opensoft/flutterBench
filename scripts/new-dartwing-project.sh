#!/bin/bash

PROJECT_NAME=$1
TARGET_DIR=$2

# Validate project name is provided
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./new-dartwing-project.sh <project-name> [target-directory]"
    echo "Examples:"
    echo "  ./new-dartwing-project.sh myapp                    # Creates ~/projects/dartwingers/myapp"
    echo "  ./new-dartwing-project.sh myapp ~/other/path       # Creates ~/other/path/myapp"
    echo ""
    echo "This script is a wrapper around new-flutter-project.sh with a default"
    echo "target directory of ~/projects/dartwingers/"
    echo ""
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If no target directory specified, default to ~/projects/dartwingers
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/projects/dartwingers"
fi

# Call the original new-flutter-project.sh script with the arguments
echo "🎯 Creating Dartwing project: $PROJECT_NAME"
echo "📍 Target directory: $TARGET_DIR"
echo ""

# Call the base Flutter project creation
"$SCRIPT_DIR/new-flutter-project.sh" "$PROJECT_NAME" "$TARGET_DIR"

# Check if the Flutter project creation was successful
if [ $? -ne 0 ]; then
    echo "❌ Error: Flutter project creation failed"
    exit 1
fi

# Post-process for Dartwingers: Replace docker-compose.yml with dartwingers version
PROJECT_PATH="$TARGET_DIR/$PROJECT_NAME"
TEMPLATE_DIR="$SCRIPT_DIR/../templates/flutter-devcontainer-template"

echo "🔧 Configuring Dartwingers-specific setup..."
echo "   - Adding .NET service container"
echo "   - Updating docker-compose configuration"

# Replace the docker-compose.yml with the dartwingers version
cp "$TEMPLATE_DIR/docker-compose-dartwingers.yml" "$PROJECT_PATH/docker-compose.yml"

echo ""
echo "✅ Dartwingers project setup complete!"
echo ""
echo "📦 Your project includes:"
echo "   - Flutter app container: ${PROJECT_NAME}_app"
echo "   - .NET service container: ${PROJECT_NAME}_service"
echo "   - Stack name: dartwingers"
echo "   - Shared networking and ADB infrastructure"
echo ""
echo "🚀 Next steps:"
echo "   1. cd $PROJECT_PATH"
echo "   2. code ."
echo "   3. When prompted, click 'Reopen in Container'"
echo "   4. Both containers will start automatically"
echo ""
echo "🔗 Service connectivity:"
echo "   - Flutter app can reach .NET service at: http://service:5000"
echo "   - .NET service exposed on host port: 5000"
echo "   - Flutter hot reload on host port: 8080"
echo ""
echo "🎯 Happy Dartwing Development!"
