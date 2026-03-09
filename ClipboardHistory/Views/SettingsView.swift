import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("globalHotkey") private var globalHotkey = "Command+Shift+V"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    @State private var recordingHotkey = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        StartupManager.shared.setLaunchAtLogin(enabled: newValue)
                    }

                Stepper("Max history items: \(maxHistoryItems)", value: $maxHistoryItems, in: 10...200, step: 10)
                    .onChange(of: maxHistoryItems) { newValue in
                        // Trim history if needed
                        let manager = ClipboardManager.shared
                        if manager.history.count > newValue {
                            manager.history.removeLast(manager.history.count - newValue)
                        }
                    }
            }

            Section("Shortcut") {
                HStack {
                    Text("Global shortcut:")
                    Spacer()
                    Button(recordingHotkey ? "Press keys..." : globalHotkey) {
                        recordingHotkey.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .onChange(of: recordingHotkey) { newValue in
                        HotkeyManager.shared.isRecording = newValue
                    }
                }

                Text("Use this shortcut to show clipboard history anywhere")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("About") {
                HStack {
                    Image(systemName: "clipboard")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("Clipboard History")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("A lightweight clipboard history tool for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .navigationTitle("Settings")
        .onReceive(HotkeyManager.shared.$recordedHotkey) { newHotkey in
            if let hotkey = newHotkey {
                globalHotkey = hotkey
                HotkeyManager.shared.updateHotkey(hotkey)
                recordingHotkey = false
            }
        }
    }
}
