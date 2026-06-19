import SwiftUI
import SwiftData

struct StampGalleryView: View {
    @Query(sort: \SavedSticker.createdAt, order: .reverse) private var stickers: [SavedSticker]
    @Environment(\.modelContext) private var context
    @State private var selectedSticker: SavedSticker?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            Group {
                if stickers.isEmpty {
                    ContentUnavailableView(
                        "No Stickers Yet",
                        systemImage: "star.square.on.square",
                        description: Text("Create your first sticker in the Editor tab.")
                    )
                } else {
                    stickerGrid
                }
            }
            .navigationTitle("My Stickers")
            .sheet(isPresented: $showShareSheet) {
                if let img = shareImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }

    private var stickerGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(stickers) { sticker in
                    StickerCard(sticker: sticker) {
                        if let img = UIImage(data: sticker.imageData) {
                            shareImage = img
                            showShareSheet = true
                        }
                    } onDelete: {
                        context.delete(sticker)
                    }
                }
            }
            .padding()
        }
    }
}

private struct StickerCard: View {
    let sticker: SavedSticker
    let onShare: () -> Void
    let onDelete: () -> Void
    @State private var showActions = false

    var body: some View {
        VStack(spacing: 8) {
            if let img = UIImage(data: sticker.imageData) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 120)
                    .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
            }
            Text(sticker.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button { onShare() } label: { Label("Share", systemImage: "square.and.arrow.up") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel(sticker.name)
        .accessibilityAction(named: "Share") { onShare() }
        .accessibilityAction(named: "Delete") { onDelete() }
    }
}
