#!/bin/bash

PROJECT_NAME=$1
TARGET_DIR=$2

if [ -z "$PROJECT_NAME" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: ./new-flutter-project.sh <project-name> <target-directory>"
    echo "Example: ./new-flutter-project.sh myapp ../../Dartwingers"
    echo ""
    echo "This script will:"
    echo "  1. Create a new Flutter project using 'flutter create'"
    echo "  2. Copy DevContainer and VS Code configurations"
    echo "  3. Replace PROJECT_NAME placeholders with your project name"
    echo "  4. Set up Docker configuration for shared ADB infrastructure"
    echo ""
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates/flutter-devcontainer-template"

# Validate template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "❌ Error: Template directory not found at $TEMPLATE_DIR"
    echo "Please ensure the flutter-devcontainer-template exists."
    exit 1
fi

# Validate target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory $TARGET_DIR does not exist"
    echo "Please create the directory first or use a valid path."
    exit 1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter command not found"
    echo "Please install Flutter or run this script from within a Flutter container."
    exit 1
fi

echo "📦 Creating Flutter project: $PROJECT_NAME"
echo "📍 Target directory: $TARGET_DIR"

# Create Flutter project
cd "$TARGET_DIR"
if ! flutter create "$PROJECT_NAME"; then
    echo "❌ Error: Failed to create Flutter project"
    exit 1
fi

cd "$PROJECT_NAME"

# Copy template files
echo "📋 Copying DevContainer configuration..."
cp -r "$TEMPLATE_DIR/.devcontainer" .
cp -r "$TEMPLATE_DIR/.vscode" .
cp "$TEMPLATE_DIR/docker-compose.yml" .
cp "$TEMPLATE_DIR/Dockerfile" .
cp "$TEMPLATE_DIR/.gitignore" .

# Copy and setup environment files
echo "⚙️  Setting up environment configuration..."
cp "$TEMPLATE_DIR/.env.example" .
cp "$TEMPLATE_DIR/.env.example" .env

# Copy README for reference
cp "$TEMPLATE_DIR/README.md" "DEVCONTAINER_README.md"

# Replace placeholders in .env
echo "🔧 Configuring project environment..."

# Get current user UID and GID for proper file permissions
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
CURRENT_USER=$(whoami)

# Replace PROJECT_NAME and user settings in .env
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/PROJECT_NAME=myproject/PROJECT_NAME=$PROJECT_NAME/g" .env
    sed -i '' "s/USER_UID=1000/USER_UID=$CURRENT_UID/g" .env
    sed -i '' "s/USER_GID=1000/USER_GID=$CURRENT_GID/g" .env
else
    # Linux
    sed -i "s/PROJECT_NAME=myproject/PROJECT_NAME=$PROJECT_NAME/g" .env
    sed -i "s/USER_UID=1000/USER_UID=$CURRENT_UID/g" .env
    sed -i "s/USER_GID=1000/USER_GID=$CURRENT_GID/g" .env
fi

# Note: devcontainer.json no longer needs PROJECT_NAME replacement since it uses .env

# Validate infrastructure path exists (relative to project)
INFRA_PATH="../../infrastructure/mobile/android/adb/scripts/start-adb-if-needed.sh"
if [ ! -f "$INFRA_PATH" ]; then
    echo "⚠️  Warning: Infrastructure script not found at $INFRA_PATH"
    echo "   You may need to adjust the path in .devcontainer/devcontainer.json"
    echo "   Current assumption: 2 levels up from project (../../infrastructure/...)"
fi

# Create .gitignore additions for Docker
echo "" >> .gitignore
echo "# DevContainer" >> .gitignore
echo ".devcontainer/docker-compose.override.yml" >> .gitignore

echo ""
echo "✅ Project created successfully: $TARGET_DIR/$PROJECT_NAME"
echo ""
echo "📝 Next steps:"
echo "   1. cd $TARGET_DIR/$PROJECT_NAME"
echo "   2. code ."
echo "   3. When prompted, click 'Reopen in Container'"
echo "   4. Wait for container build (first time: ~5-10 minutes)"
echo "   5. Container will automatically:"
echo "      - Start shared ADB infrastructure"
echo "      - Run 'flutter pub get'"
echo "      - Run 'flutter doctor'"
echo "      - Check ADB device connection"
echo ""
echo "🔧 Configuration summary:"
echo "   - Container name: $PROJECT_NAME-dev"
echo "   - Network: dartnet (shared)"
echo "   - ADB server: shared-adb-server:5037"
echo "   - Infrastructure path: $INFRA_PATH"
echo "   - User UID/GID: $CURRENT_UID:$CURRENT_GID"
echo "   - Environment file: .env (customized from .env.example)"
echo ""
echo "⚙️  Environment configuration:"
echo "   - PROJECT_NAME=$PROJECT_NAME (in .env)"
echo "   - USER_UID=$CURRENT_UID (in .env)"
echo "   - USER_GID=$CURRENT_GID (in .env)"
echo "   - FLUTTER_VERSION=3.24.0 (in .env)"
echo ""
echo "📝 Next steps:"
echo "   1. Review and customize .env file if needed"
echo "   2. cd $TARGET_DIR/$PROJECT_NAME"
echo "   3. code ."
echo "   4. When prompted, click 'Reopen in Container'"
echo ""
echo "📚 For detailed information, see: DEVCONTAINER_README.md"
echo "📚 For environment variables, see: .env.example"
echo ""
echo "🎯 Happy Flutter Development!"
