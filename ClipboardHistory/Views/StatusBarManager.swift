import AppKit
import SwiftUI

class StatusBarManager: ObservableObject {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private init() {}

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        // Set icon (use system clipboard icon)
        if let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard History") {
            image.isTemplate = true
            button.image = image
        }

        // Create menu
        let menu = NSMenu()

        let showHistoryItem = NSMenuItem(title: "Show History", action: #selector(showHistory), keyEquivalent: "")
        showHistoryItem.target = self
        menu.addItem(showHistoryItem)

        let clearHistoryItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearHistoryItem.target = self
        menu.addItem(clearHistoryItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.keyEquivalentModifierMask = .command
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func showHistory() {
        HistoryPanel.shared.show()
    }

    @objc private func clearHistory() {
        ClipboardManager.shared.clearHistory()
    }

    private var settingsWindow: NSWindow?

    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
