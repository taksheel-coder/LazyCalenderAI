#!/bin/bash
set -e

APP_NAME="CalendarAI"
EXECUTABLE_NAME="CalenderAI"
BUNDLE_ID="com.example.CalendarAI"

# Build the Swift package in release mode
echo "Building Swift Package..."
swift build -c release

# Paths
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RESOURCES_DIR="${APP_DIR}/Contents/Resources"

# Create App bundle structure
echo "Creating App Bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp "${BUILD_DIR}/${EXECUTABLE_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp Info.plist "${APP_DIR}/Contents/Info.plist"

echo "Done! The app is located at ${PWD}/${APP_DIR}"
