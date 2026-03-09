import AppKit

enum ClipboardContentType: Codable {
    case text
    case image
    case fileURL
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ClipboardContentType
    let timestamp: Date
    let textContent: String?
    let imageData: Data?
    let fileURL: URL?
    let preview: String

    enum CodingKeys: String, CodingKey {
        case type, timestamp, textContent, imageData, fileURL, preview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        type = try container.decode(ClipboardContentType.self, forKey: .type)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        textContent = try container.decodeIfPresent(String.self, forKey: .textContent)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        fileURL = try container.decodeIfPresent(URL.self, forKey: .fileURL)
        preview = try container.decode(String.self, forKey: .preview)
    }

    init(text: String) {
        self.id = UUID()
        self.type = .text
        self.timestamp = Date()
        self.textContent = text
        self.imageData = nil
        self.fileURL = nil
        self.preview = String(text.prefix(100)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(image: NSImage) {
        self.id = UUID()
        self.type = .image
        self.timestamp = Date()
        self.textContent = nil
        self.imageData = image.tiffRepresentation
        self.fileURL = nil
        self.preview = "🖼️  Image"
    }

    init(fileURL: URL) {
        self.id = UUID()
        self.type = .fileURL
        self.timestamp = Date()
        self.textContent = nil
        self.imageData = nil
        self.fileURL = fileURL
        self.preview = "📁 \(fileURL.lastPathComponent)"
    }

    func getImage() -> NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        switch (lhs.type, rhs.type) {
        case (.text, .text):
            return lhs.textContent == rhs.textContent
        case (.image, .image):
            return lhs.imageData == rhs.imageData
        case (.fileURL, .fileURL):
            return lhs.fileURL == rhs.fileURL
        default:
            return false
        }
    }
}
