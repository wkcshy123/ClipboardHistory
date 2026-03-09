import SwiftUI
import AppKit

@main
struct ClipboardHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarManager = StatusBarManager.shared
    private let clipboardManager = ClipboardManager.shared
    private let hotkeyManager = HotkeyManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Initialize core components
        statusBarManager.setup()
        clipboardManager.startMonitoring()
        hotkeyManager.setup()

        // Register for app termination
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func applicationWillTerminate() {
        clipboardManager.stopMonitoring()
        StorageManager.shared.saveHistory()
    }
}
