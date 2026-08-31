#!/bin/bash
set -e

# ==========================================================
#  LazyCalenderAI - 1-Click Installer for macOS
# ==========================================================

APP_NAME="CalendarAI"
REPO="taksheel-coder/LazyCalenderAI"
DEST_DIR="/Applications"

echo "⚡ [1/3] Downloading LazyCalenderAI..."
TMP_DIR=$(mktemp -d)

# Try downloading latest release zip, fallback to building if needed
if curl -s -f -I -L "https://github.com/${REPO}/releases/latest/download/CalendarAI.zip" >/dev/null 2>&1; then
    curl -sL "https://github.com/${REPO}/releases/latest/download/CalendarAI.zip" -o "${TMP_DIR}/CalendarAI.zip"
    echo "📦 [2/3] Extracting application bundle..."
    unzip -q "${TMP_DIR}/CalendarAI.zip" -d "${TMP_DIR}"
else
    echo "🛠️ [2/3] Building from source..."
    git clone --depth 1 "https://github.com/${REPO}.git" "${TMP_DIR}/repo" >/dev/null 2>&1
    cd "${TMP_DIR}/repo"
    chmod +x build.sh
    ./build.sh >/dev/null 2>&1
    cp -R "${APP_NAME}.app" "${TMP_DIR}/"
    cd - >/dev/null
fi

echo "🚀 [3/3] Installing to ${DEST_DIR}..."
pkill -f "${APP_NAME}" 2>/dev/null || true
rm -rf "${DEST_DIR}/${APP_NAME}.app"
cp -R "${TMP_DIR}/${APP_NAME}.app" "${DEST_DIR}/"
rm -rf "${TMP_DIR}"

# Remove quarantine attribute if downloaded from web
xattr -dr com.apple.quarantine "${DEST_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo ""
echo "🎉 Installation complete!"
echo "✨ Launching CalendarAI in your macOS menu bar..."
open "${DEST_DIR}/${APP_NAME}.app"
