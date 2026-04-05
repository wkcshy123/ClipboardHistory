import SwiftUI
import UIKit

@main
struct iOSClipboardHistoryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    private let clipboardManager = ClipboardManager.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 启动时加载历史记录
        _ = clipboardManager.history
        // 注册进入前台通知，检查剪贴板变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        return true
    }
    
    @objc private func applicationDidBecomeActive() {
        // App进入前台时检查剪贴板新内容
        clipboardManager.checkClipboard()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        StorageManager.shared.saveHistory()
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HistoryListView()
                .tabItem {
                    Label("History", systemImage: "clipboard")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
