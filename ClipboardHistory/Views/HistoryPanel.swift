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

        // Position panel at mouse
        let mouseLocation = NSEvent.mouseLocation
        let panelWidth = frame.width
        let panelHeight = frame.height
        let x = mouseLocation.x - panelWidth / 2
        let y = mouseLocation.y - panelHeight - 10
        setFrameOrigin(NSPoint(x: x, y: y))

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
        searchText.isEmpty ? clipboardManager.history : clipboardManager.history.filter {
            $0.preview.localizedCaseInsensitiveContains(searchText)
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
            }
            .listStyle(.plain)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 400, height: 500)
    }
}

struct HistoryItemView: View {
    let item: ClipboardItem
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
