# macOS Clipboard History Tool

A lightweight, native macOS clipboard history tool similar to Windows' Win+V functionality.

## Features

- 📋 Automatically records up to 50 clipboard history items
- 🖼️ Supports text, images, and file URLs
- ⌨️ Global customizable shortcut (default: Command+Option+V)
- 🖱️ Click any history item to instantly copy AND auto-paste to current input
- 🔍 Search functionality to quickly find old clipboard items
- 🔄 Optional launch at login
- 🎯 Very low resource usage
- 🚀 No third-party dependencies, 100% native AppKit/SwiftUI

## Requirements

- macOS 12.0 Monterey or later
- Supports both Intel and Apple Silicon

## How to Build

Use the included build script:

```bash
cd ClipboardHistory
./build.sh
```

The built app will be at `build/Release/Clipboard History.app`

## Usage

1. Launch the app - you'll see a clipboard icon in the menu bar
2. Use `Command+Option+V` anywhere to bring up the history panel
3. Click any item - it will automatically copy AND paste to your current input
4. Use the search bar to filter history items
5. Click the menu bar icon for more options (Show History, Clear History, Settings, Quit)

## Permissions

The app requires two sets of permissions:

### 1. Accessibility Permissions (for global hotkey)
On first launch:
1. Go to System Settings > Privacy & Security > Accessibility
2. Enable "Clipboard History"
3. Restart the app for changes to take effect

### 2. Optional: Automation Permissions (for AppleScript fallback)
For more reliable auto-paste:
1. Go to System Settings > Privacy & Security > Automation
2. Enable "System Events" for "Clipboard History"

## Customization

- Change the global shortcut in Settings
- Adjust the maximum number of history items
- Enable/disable launch at login

## Architecture

The app follows a clean MVC architecture:

- **Models**: ClipboardItem (data model), ClipboardManager (core logic)
- **Views**: StatusBarManager (menu bar), HistoryPanel (floating window), SettingsView
- **Controllers**: HotkeyManager (global shortcuts via Carbon API), StartupManager (login items), StorageManager (persistence)

## Recent Improvements (2026-03-07)

- ✅ Fixed Settings menu not responding
- ✅ Fixed menu bar shortcuts (Command+, for Settings, Command+Q for Quit)
- ✅ Fixed global hotkey using reliable Carbon EventHotKey API
- ✅ Implemented auto-paste functionality (no need to manually press Command+V)
- ✅ Optimized window activation and event timing
- ✅ Added multiple fallback mechanisms for reliable auto-paste

## Performance

- Clipboard polling interval: 500ms
- Images are automatically compressed
- Automatic duplicate detection
- History persisted to UserDefaults for fast startup
