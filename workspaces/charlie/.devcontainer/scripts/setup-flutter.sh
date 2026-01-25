#!/bin/bash
# ===========================================
# Flutter DevContainer Setup Script
# Version: 1.0.0
# ===========================================
# This script runs on container creation to set up the Flutter development environment

set -e

echo "========================================"
echo "Flutter DevContainer Setup"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Flutter is available
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓${NC} Flutter is installed"
    flutter --version
else
    echo -e "${RED}✗${NC} Flutter not found in PATH"
    exit 1
fi

# Run flutter doctor to check setup
echo ""
echo "Running Flutter doctor..."
flutter doctor -v

# Accept Android licenses if not already accepted
echo ""
echo "Accepting Android licenses..."
yes | flutter doctor --android-licenses 2>/dev/null || echo "Android licenses already accepted"

# Configure Flutter
echo ""
echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

# Download Flutter dependencies
echo ""
echo "Downloading Flutter dependencies..."
flutter precache

# Check Dart version
echo ""
echo "Dart version:"
dart --version

echo ""
echo -e "${GREEN}========================================"
echo -e "Flutter DevContainer Setup Complete!"
echo -e "========================================${NC}"
echo ""
echo "You can now:"
echo "  • Run 'flutter create my_app' to create a new Flutter project"
echo "  • Run 'flutter doctor' to verify your setup"
echo "  • Run 'flutter devices' to see available devices"
echo ""
