import SwiftUI
import UIKit

struct HistoryListView: View {
    @ObservedObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""
    @State private var showClearConfirm = false
    
    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return clipboardManager.history }
        let lowercasedQuery = searchText.lowercased()
        return clipboardManager.history.filter { item in
            if item.preview.lowercased().contains(lowercasedQuery) {
                return true
            }
            if item.type == .text, let fullText = item.textContent {
                return fullText.lowercased().contains(lowercasedQuery)
            }
            if item.type == .fileURL, let path = item.fileURL?.path {
                return path.lowercased().contains(lowercasedQuery)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    Button(action: {
                        clipboardManager.copyItemToClipboard(item)
                        // 震动反馈
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        HistoryItemView(item: item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let index = clipboardManager.history.firstIndex(where: { $0.id == item.id }) {
                                clipboardManager.history.remove(at: index)
                                StorageManager.shared.saveHistory()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            clipboardManager.copyItemToClipboard(item)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(role: .destructive) {
                            if let index = clipboardManager.history.firstIndex(where: { $0.id == item.id }) {
                                clipboardManager.history.remove(at: index)
                                StorageManager.shared.saveHistory()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Clipboard History")
            .searchable(text: $searchText, prompt: "Search history...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .confirmationDialog("Clear All History?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    clipboardManager.clearHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All clipboard history will be permanently deleted.")
            }
            .onAppear {
                // 进入页面时检查剪贴板
                clipboardManager.checkClipboard()
            }
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
        HStack(alignment: .top, spacing: 12) {
            Group {
                switch item.type {
                case .text:
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                case .image:
                    if let image = item.getImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.green)
                            .frame(width: 24, height: 24)
                    }
                case .fileURL:
                    Image(systemName: "folder")
                        .foregroundColor(.purple)
                        .frame(width: 24, height: 24)
                }
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .lineLimit(2)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                Text(Self.dateFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
        }
        .padding(.vertical, 8)
    }
}
