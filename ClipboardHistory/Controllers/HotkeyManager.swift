import AppKit
import Combine
import Carbon

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    private let defaults = UserDefaults.standard
    private let hotkeyKey = "globalHotkey"
    private var storedHotkey: String {
        get { defaults.string(forKey: hotkeyKey) ?? "Command+Option+V" }
        set { defaults.set(newValue, forKey: hotkeyKey) }
    }

    @Published var isRecording = false {
        didSet {
            if isRecording {
                installLocalEventMonitor()
            } else {
                removeLocalEventMonitor()
            }
        }
    }
    @Published var recordedHotkey: String?

    private var hotkeyRef: EventHotKeyRef?
    private let hotkeySignature: OSType = OSType(fourCharCode: "CBHK")
    private let hotkeyID: UInt32 = 1
    private var localEventMonitor: Any?
    
    // Static key code mapping tables for faster lookup
    private static let keyCodeToStringMap: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U",
        34: "I", 35: "P", 126: "Up", 125: "Down", 123: "Left", 124: "Right", 49: "Space",
        36: "Return", 48: "Tab", 53: "Escape", 51: "Delete"
    ]
    
    private static let stringToKeyCodeMap: [String: UInt16] = [
        "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8, "V": 9,
        "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17, "O": 31, "U": 32,
        "I": 34, "P": 35, "UP": 126, "DOWN": 125, "LEFT": 123, "RIGHT": 124, "SPACE": 49,
        "RETURN": 36, "TAB": 48, "ESCAPE": 53, "DELETE": 51
    ]

    private init() {}

    func setup() {
        // Check accessibility permissions
        checkAccessibilityPermissions()

        // Install event handler
        installHotkeyHandler()

        // Load saved hotkey
        updateHotkey(storedHotkey)
    }

    private func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ Accessibility permissions are required for global hotkeys to work.")
        }
    }

    private func installHotkeyHandler() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                _ = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    HistoryPanel.shared.toggle()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )

        if status != noErr {
            print("❌ Failed to install event handler: \(status)")
        }
    }

    func updateHotkey(_ hotkeyString: String) {
        // Unregister existing hotkey
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }

        // Parse hotkey components
        let (modifiers, keyCode) = parseHotkey(hotkeyString)
        guard let keyCode = keyCode else { return }

        // Convert to Carbon modifiers
        var carbonModifiers = UInt32(0)
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }

        print("🔧 Registering hotkey: \(hotkeyString), carbon modifiers: \(carbonModifiers), keyCode: \(keyCode)")
        print("🔧 Accessibility enabled: \(AXIsProcessTrusted())")

        // Register new hotkey
        let hotkeyID = EventHotKeyID(signature: hotkeySignature, id: self.hotkeyID)
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("❌ Failed to register hotkey, error code: \(status)")
        } else {
            print("✅ Hotkey registered successfully!")
        }
    }

    private func installLocalEventMonitor() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isRecording else { return event }
            
            // Ignore modifier keys alone
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasNonModifierKey = event.keyCode != 0x37 && event.keyCode != 0x38 && event.keyCode != 0x3A && event.keyCode != 0x3B
            let hasAtLeastOneModifier = modifiers.contains(.command) || modifiers.contains(.option) || modifiers.contains(.shift) || modifiers.contains(.control)
            
            // Require at least one modifier key for global shortcut to avoid conflicts
            if hasNonModifierKey && hasAtLeastOneModifier {
                self.recordPressedKeys(event: event)
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    private func removeLocalEventMonitor() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }

    private func recordPressedKeys(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        // Convert to human-readable string
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("Command") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        if modifiers.contains(.option) { parts.append("Option") }
        if modifiers.contains(.control) { parts.append("Control") }

        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        guard !parts.isEmpty else { return }
        recordedHotkey = parts.joined(separator: "+")
        isRecording = false
    }

    private func parseHotkey(_ hotkeyString: String) -> (NSEvent.ModifierFlags, UInt16?) {
        let parts = hotkeyString.components(separatedBy: "+")
        var modifiers: NSEvent.ModifierFlags = []
        var keyPart = ""

        for part in parts {
            switch part.lowercased() {
            case "command", "cmd": modifiers.insert(.command)
            case "shift": modifiers.insert(.shift)
            case "option", "alt": modifiers.insert(.option)
            case "control", "ctrl": modifiers.insert(.control)
            default: keyPart = part
            }
        }

        return (modifiers, stringToKeyCode(keyPart))
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        return Self.keyCodeToStringMap[keyCode] ?? String(keyCode)
    }

    private func stringToKeyCode(_ keyString: String) -> UInt16? {
        let uppercased = keyString.uppercased()
        // Check mapping table first
        if let code = Self.stringToKeyCodeMap[uppercased] {
            return code
        }
        // Handle aliases
        switch uppercased {
        case "ENTER": return 36
        case "ESC": return 53
        case "BACKSPACE": return 51
        default:
            // Try to parse as numeric key code
            return UInt16(uppercased)
        }
    }
}

extension OSType {
    init(fourCharCode: String) {
        var result: OSType = 0
        for char in fourCharCode.utf8 {
            result = (result << 8) + OSType(char)
        }
        self = result
    }
}
