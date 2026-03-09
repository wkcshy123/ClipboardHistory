import Foundation
import ServiceManagement

class StartupManager {
    static let shared = StartupManager()

    private init() {}

    func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Error setting launch at login: \(error)")
            }
        } else {
            // Fallback for macOS 12 and earlier
            let bundleID = Bundle.main.bundleIdentifier ?? "com.yourcompany.ClipboardHistory"
            let jobDict: [String: Any] = [
                "Label": bundleID,
                "ProgramArguments": [Bundle.main.bundlePath],
                "RunAtLoad": enabled,
                "StandardOutPath": "/dev/null",
                "StandardErrorPath": "/dev/null"
            ]

            let plistPath = "~/Library/LaunchAgents/\(bundleID).plist" as NSString
            let expandedPath = plistPath.expandingTildeInPath

            if enabled {
                do {
                    let plistData = try PropertyListSerialization.data(fromPropertyList: jobDict, format: .xml, options: 0)
                    try plistData.write(to: URL(fileURLWithPath: expandedPath))
                    // Load the job
                    let process = Process()
                    process.launchPath = "/bin/launchctl"
                    process.arguments = ["load", expandedPath]
                    process.launch()
                } catch {
                    print("Error creating launch agent plist: \(error)")
                }
            } else {
                // Unload and remove the plist
                let process = Process()
                process.launchPath = "/bin/launchctl"
                process.arguments = ["unload", expandedPath]
                process.launch()

                do {
                    try FileManager.default.removeItem(atPath: expandedPath)
                } catch {
                    print("Error removing launch agent plist: \(error)")
                }
            }
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            let bundleID = Bundle.main.bundleIdentifier ?? "com.yourcompany.ClipboardHistory"
            let plistPath = "~/Library/LaunchAgents/\(bundleID).plist" as NSString
            let expandedPath = plistPath.expandingTildeInPath
            return FileManager.default.fileExists(atPath: expandedPath)
        }
    }
}
