// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistory",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ClipboardHistory", targets: ["ClipboardHistory"])
    ],
    targets: [
        .executableTarget(
            name: "ClipboardHistory",
            path: ".",
            sources: [
                "ClipboardHistoryApp.swift",
                "Models/ClipboardItem.swift",
                "Models/ClipboardManager.swift",
                "Views/StatusBarManager.swift",
                "Views/HistoryPanel.swift",
                "Views/SettingsView.swift",
                "Controllers/HotkeyManager.swift",
                "Controllers/StartupManager.swift",
                "Controllers/StorageManager.swift"
            ],
            resources: [
                .copy("Resources/Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
