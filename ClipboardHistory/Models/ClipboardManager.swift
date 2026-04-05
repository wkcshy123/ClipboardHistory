import Combine

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    @Published var history: [ClipboardItem] = []
    private let defaults = UserDefaults.standard
    private var maxHistoryItems: Int {
        get { defaults.integer(forKey: "maxHistoryItems") > 0 ? defaults.integer(forKey: "maxHistoryItems") : 50 }
        set { defaults.set(newValue, forKey: "maxHistoryItems") }
    }
    
    #if os(macOS)
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    #elseif os(iOS)
    private var lastChangeCount = UIPasteboard.general.changeCount
    #endif

    private init() {
        history = StorageManager.shared.loadHistory()
    }

    #if os(macOS)
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    #endif

    func checkClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            for url in fileURLs {
                addItem(ClipboardItem(fileURL: url))
            }
            return
        }

        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !image.isEmpty {
            if let firstImage = image.first {
                if let compressedData = firstImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: compressedData),
                   let pngData = bitmap.representation(using: .png, properties: [.compressionFactor: 0.5]) {
                    if let compressedImage = NSImage(data: pngData) {
                        addItem(ClipboardItem(image: compressedImage))
                    }
                }
            }
            return
        }

        if let text = pasteboard.string(forType: .string) {
            addItem(ClipboardItem(text: text))
            return
        }
        #elseif os(iOS)
        let pasteboard = UIPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // 检查文件URL
        if let fileURLs = pasteboard.urls, !fileURLs.isEmpty {
            for url in fileURLs {
                addItem(ClipboardItem(fileURL: url))
            }
            return
        }

        // 检查图片
        if let image = pasteboard.image {
            if let pngData = image.pngData() {
                addItem(ClipboardItem(image: UIImage(data: pngData)!))
            }
            return
        }

        // 检查文本
        if let text = pasteboard.string {
            addItem(ClipboardItem(text: text))
            return
        }
        #endif
    }

    private func addItem(_ item: ClipboardItem) {
        if let existingIndex = history.firstIndex(where: { $0 == item }) {
            history.remove(at: existingIndex)
            history.insert(item, at: 0)
            return
        }

        history.insert(item, at: 0)

        if history.count > maxHistoryItems {
            history.removeLast(history.count - maxHistoryItems)
        }

        StorageManager.shared.saveHistory()
    }

    func copyItemToClipboard(_ item: ClipboardItem, autoPaste: Bool = true) {
        // Step 1: Copy to clipboard
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        #elseif os(iOS)
        let pasteboard = UIPasteboard.general
        #endif
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let text = item.textContent {
                #if os(macOS)
                pasteboard.setString(text, forType: .string)
                #elseif os(iOS)
                pasteboard.string = text
                #endif
            }
        case .image:
            if let image = item.getImage() {
                pasteboard.writeObjects([image])
            }
        case .fileURL:
            if let url = item.fileURL {
                #if os(macOS)
                pasteboard.writeObjects([url as NSURL])
                #elseif os(iOS)
                pasteboard.url = url
                #endif
            }
        }

        #if os(macOS)
        guard autoPaste, let previousApp = HistoryPanel.shared.previousActiveApp else { return }

        // Step 2: Hide our panel
        HistoryPanel.shared.hide()

        // Step 3: Wait, activate previous app and paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            previousApp.activate(options: .activateIgnoringOtherApps)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendPasteViaCGEventDirect()
            }
        }
        #endif
    }

    private func sendPasteWithNSEvent() {
        print("⌨️ Trying NSEvent method")

        // Try AppleScript first (most reliable if permissions allow)
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }

        if let error = error {
            print("⚠️ AppleScript failed: \(error), trying CGEvent")
            sendPasteViaCGEvent()
        } else {
            print("✅ AppleScript paste executed")
        }
    }

    private func sendPasteViaCGEvent() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let vKeyCode: UInt16 = 0x09

        guard let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true),
              let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false) else {
            return
        }

        cmdDown.flags = .maskCommand
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand

        let tapLocation = CGEventTapLocation.cghidEventTap

        cmdDown.post(tap: tapLocation)
        usleep(20000)
        vDown.post(tap: tapLocation)
        usleep(30000)
        vUp.post(tap: tapLocation)
        usleep(20000)
        cmdUp.post(tap: tapLocation)

        print("✅ CGEvent paste sent")
    }

    private func sendPasteViaCGEventDirect() {
        print("⌨️ Using direct CGEvent method")

        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // V key down with Command
        guard let eventDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        eventDown.flags = .maskCommand

        // V key up with Command
        guard let eventUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        eventUp.flags = .maskCommand

        // Only send once, to HID tap
        eventDown.post(tap: .cghidEventTap)
        usleep(50000)
        eventUp.post(tap: .cghidEventTap)

        print("✅ CGEvent sent once, paste should work perfectly now!")
    }

    func clearHistory() {
        history.removeAll()
        StorageManager.shared.saveHistory()
    }
}
