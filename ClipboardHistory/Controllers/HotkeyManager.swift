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

    @Published var isRecording = false
    @Published var recordedHotkey: String?

    private var hotkeyRef: EventHotKeyRef?
    private let hotkeySignature: OSType = OSType(fourCharCode: "CBHK")
    private let hotkeyID: UInt32 = 1

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
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
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
        var hotkeyID = EventHotKeyID(signature: hotkeySignature, id: self.hotkeyID)
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

        recordedHotkey = parts.joined(separator: "+")
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
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 126: return "Up"
        case 125: return "Down"
        case 123: return "Left"
        case 124: return "Right"
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 53: return "Escape"
        case 51: return "Delete"
        default: return String(keyCode)
        }
    }

    private func stringToKeyCode(_ keyString: String) -> UInt16? {
        switch keyString.uppercased() {
        case "A": return 0
        case "S": return 1
        case "D": return 2
        case "F": return 3
        case "H": return 4
        case "G": return 5
        case "Z": return 6
        case "X": return 7
        case "C": return 8
        case "V": return 9
        case "B": return 11
        case "Q": return 12
        case "W": return 13
        case "E": return 14
        case "R": return 15
        case "Y": return 16
        case "T": return 17
        case "O": return 31
        case "U": return 32
        case "I": return 34
        case "P": return 35
        case "UP": return 126
        case "DOWN": return 125
        case "LEFT": return 123
        case "RIGHT": return 124
        case "SPACE": return 49
        case "RETURN", "ENTER": return 36
        case "TAB": return 48
        case "ESCAPE", "ESC": return 53
        case "DELETE", "BACKSPACE": return 51
        default:
            if let code = UInt16(keyString) {
                return code
            }
            return 9 // Default to V
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
