#!/bin/bash

# Build script for Clipboard History app
# Usage: ./build.sh

set -e

APP_NAME="Clipboard History"
EXECUTABLE_NAME="ClipboardHistory"
BUNDLE_ID="com.example.ClipboardHistory"
VERSION="1.0.0"
MACOS_VERSION="12.0"

# Create build directory
mkdir -p build/Release

# Compile Swift files
echo "Compiling source files..."
swiftc \
    -target arm64-apple-macosx$MACOS_VERSION \
    -target x86_64-apple-macosx$MACOS_VERSION \
    -O \
    -wmo \
    -Xlinker -dead_strip \
    -Xlinker -sectcreate \
    -Xlinker __TEXT \
    -Xlinker __info_plist \
    -Xlinker Resources/Info.plist \
    -o "build/Release/$EXECUTABLE_NAME" \
    ClipboardHistoryApp.swift \
    Models/ClipboardItem.swift \
    Models/ClipboardManager.swift \
    Views/StatusBarManager.swift \
    Views/HistoryPanel.swift \
    Views/SettingsView.swift \
    Controllers/HotkeyManager.swift \
    Controllers/StartupManager.swift \
    Controllers/StorageManager.swift \
    -framework AppKit \
    -framework SwiftUI \
    -framework Combine \
    -framework ServiceManagement

# Create app bundle structure
echo "Creating app bundle..."
APP_BUNDLE="build/Release/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Move executable
mv "build/Release/$EXECUTABLE_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Create PkgInfo file
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy and modify Info.plist
cp Resources/Info.plist "$APP_BUNDLE/Contents/"
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace LSMinimumSystemVersion -string "$MACOS_VERSION" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleExecutable -string "$EXECUTABLE_NAME" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$APP_BUNDLE/Contents/Info.plist"

# Make executable
chmod +x "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"

# Codesign the app for local running
echo "Signing app with entitlements..."
codesign --force --deep --sign - --entitlements "ClipboardHistory.entitlements" "$APP_BUNDLE"

echo "Build complete! App bundle is at $APP_BUNDLE"
echo "To run: right-click the app and select Open, or run:"
echo "xattr -d com.apple.quarantine \"$APP_BUNDLE\""
