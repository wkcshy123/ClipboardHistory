import Foundation

class StorageManager {
    static let shared = StorageManager()

    private let defaults = UserDefaults.standard
    private let historyKey = "ClipboardHistory"

    private init() {}

    func saveHistory() {
        let history = ClipboardManager.shared.history
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            defaults.set(data, forKey: historyKey)
        } catch {
            print("Error saving history: \(error)")
        }
    }

    func loadHistory() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: historyKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let history = try decoder.decode([ClipboardItem].self, from: data)
            return history
        } catch {
            print("Error loading history: \(error)")
            return []
        }
    }
}
