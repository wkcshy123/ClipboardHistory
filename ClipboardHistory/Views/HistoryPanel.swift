import AppKit
import SwiftUI

class HistoryPanel: NSPanel {
    static let shared = HistoryPanel()
    var previousActiveApp: NSRunningApplication?

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        setupContentView()
    }

    private func setupPanel() {
        title = "Clipboard History"
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
    }

    private func setupContentView() {
        let contentView = NSHostingView(rootView: HistoryListView())
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 12
        contentView.layer?.masksToBounds = true
        self.contentView = contentView
    }

    func show() {
        // Save the active app before we activate our own
        previousActiveApp = NSWorkspace.shared.frontmostApplication

        // Position panel at mouse with screen boundary check
        let mouseLocation = NSEvent.mouseLocation
        let panelWidth = frame.width
        let panelHeight = frame.height
        
        var x = mouseLocation.x - panelWidth / 2
        var y = mouseLocation.y - panelHeight - 10
        
        // Get screen frame (excluding menu bar)
        guard let screen = NSScreen.main else {
            setFrameOrigin(NSPoint(x: x, y: y))
            activateAndShow()
            return
        }
        
        let screenFrame = screen.visibleFrame
        
        // Adjust x position to stay within screen bounds
        if x < screenFrame.minX {
            x = screenFrame.minX
        } else if x + panelWidth > screenFrame.maxX {
            x = screenFrame.maxX - panelWidth
        }
        
        // Adjust y position to stay within screen bounds
        if y < screenFrame.minY {
            // If panel would go below screen, show above mouse instead
            y = mouseLocation.y + 10
        } else if y + panelHeight > screenFrame.maxY {
            y = screenFrame.maxY - panelHeight
        }
        
        setFrameOrigin(NSPoint(x: x, y: y))
        activateAndShow()
    }
    
    private func activateAndShow() {
        // Activate app and show panel
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }

    func hide() {
        orderOut(nil)
    }

    func toggle() {
        isVisible ? hide() : show()
    }
}

struct HistoryListView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""

    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return clipboardManager.history }
        let lowercasedQuery = searchText.lowercased()
        return clipboardManager.history.filter { item in
            // Search in preview first
            if item.preview.lowercased().contains(lowercasedQuery) {
                return true
            }
            // Search in full text content for text items
            if item.type == .text, let fullText = item.textContent {
                return fullText.lowercased().contains(lowercasedQuery)
            }
            // Search in file path for file items
            if item.type == .fileURL, let path = item.fileURL?.path {
                return path.lowercased().contains(lowercasedQuery)
            }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search...", text: $searchText).textFieldStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            List(filteredItems) { item in
                Button(action: {
                    clipboardManager.copyItemToClipboard(item)
                }) {
                    HistoryItemView(item: item)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .contextMenu {
                    Button("Delete") {
                        if let index = clipboardManager.history.firstIndex(where: { $0.id == item.id }) {
                            clipboardManager.history.remove(at: index)
                            StorageManager.shared.saveHistory()
                        }
                    }
                    Button("Copy Only (Don't Paste)") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        switch item.type {
                        case .text:
                            if let text = item.textContent {
                                pasteboard.setString(text, forType: .string)
                            }
                        case .image:
                            if let image = item.getImage() {
                                pasteboard.writeObjects([image])
                            }
                        case .fileURL:
                            if let url = item.fileURL {
                                pasteboard.writeObjects([url as NSURL])
                            }
                        }
                        HistoryPanel.shared.hide()
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 400, height: 500)
        .onExitCommand {
            HistoryPanel.shared.hide()
        }
    }
}

struct HistoryItemView: View {
    let item: ClipboardItem
    
    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Group {
                switch item.type {
                case .text: Image(systemName: "text.alignleft").foregroundColor(.blue)
                case .image: Image(systemName: "photo").foregroundColor(.green)
                case .fileURL: Image(systemName: "folder").foregroundColor(.purple)
                }
            }.frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview).lineLimit(2).font(.system(size: 13))
                Text(timeAgoString(from: item.timestamp)).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    private func timeAgoString(from date: Date) -> String {
        Self.dateFormatter.localizedString(for: date, relativeTo: Date())
    }
}
