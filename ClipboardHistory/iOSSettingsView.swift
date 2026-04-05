import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 50
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Stepper("Max history items: \(maxHistoryItems)", value: $maxHistoryItems, in: 10...500, step: 10)
                        .onChange(of: maxHistoryItems) { newValue in
                            let manager = ClipboardManager.shared
                            if manager.history.count > newValue {
                                manager.history.removeLast(manager.history.count - newValue)
                                StorageManager.shared.saveHistory()
                            }
                        }
                    
                    Toggle("iCloud Sync (Coming Soon)", isOn: $iCloudSyncEnabled)
                        .disabled(true)
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
                    
                    Link(destination: URL(string: "https://github.com/wkcshy123/ClipboardHistory")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Text("Open System Settings")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Clipboard History for iOS")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("A lightweight clipboard history tool that keeps track of everything you copy.\n\nFeatures:\n- Automatically saves copied text, images and files\n- Fast search across all history\n- One tap to copy any history item\n- Swipe to delete unwanted items\n- All data stored locally on your device")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("© 2026 Clipboard History")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .navigationTitle("About")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAbout = false
                            }
                        }
                    }
                }
            }
        }
    }
}
