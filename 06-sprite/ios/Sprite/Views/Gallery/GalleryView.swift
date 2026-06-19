import SwiftUI
import SwiftData

struct SpriteGalleryView: View {
    @Query(sort: \SpriteArtwork.modifiedAt, order: .reverse) private var artworks: [SpriteArtwork]
    @Environment(\.modelContext) private var context
    @State private var showNewSheet = false
    @State private var selectedArtwork: SpriteArtwork?

    var body: some View {
        NavigationStack {
            Group {
                if artworks.isEmpty {
                    ContentUnavailableView(
                        "No Artwork Yet",
                        systemImage: "paintbrush.pointed",
                        description: Text("Tap + to create your first pixel art.")
                    )
                } else {
                    artGrid
                }
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewSheet = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNewSheet) {
                NewArtworkSheet { name, size in
                    let art = SpriteArtwork(name: name, width: size, height: size)
                    context.insert(art)
                    selectedArtwork = art
                }
            }
            .navigationDestination(item: $selectedArtwork) { art in
                SpriteCanvasView(vm: CanvasViewModel(artwork: art))
            }
        }
    }

    private var artGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(artworks) { art in
                    ArtworkCard(artwork: art) {
                        selectedArtwork = art
                    } onDelete: {
                        context.delete(art)
                    }
                }
            }
            .padding()
        }
    }
}

private struct ArtworkCard: View {
    let artwork: SpriteArtwork
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 8) {
                ArtworkPreview(artwork: artwork)
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(spacing: 2) {
                    Text(artwork.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(artwork.width)×\(artwork.height)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel(artwork.name)
    }
}

private struct ArtworkPreview: View {
    let artwork: SpriteArtwork

    var body: some View {
        let pixels = artwork.loadPixels()
        let w = artwork.width
        let h = artwork.height
        Canvas { ctx, size in
            let cellW = size.width / CGFloat(w)
            let cellH = size.height / CGFloat(h)
            for r in 0..<h {
                for c in 0..<w {
                    let idx = r * w + c
                    let rect = CGRect(x: CGFloat(c) * cellW, y: CGFloat(r) * cellH, width: cellW, height: cellH)
                    let px = pixels[safe: idx] ?? 0
                    if px == 0 {
                        let light = (r + c) % 2 == 0
                        ctx.fill(Path(rect), with: .color(light ? Color(.systemGray5) : Color(.systemGray4)))
                    } else {
                        let rv = Double((px >> 16) & 0xFF) / 255
                        let g = Double((px >> 8) & 0xFF) / 255
                        let b = Double(px & 0xFF) / 255
                        ctx.fill(Path(rect), with: .color(Color(red: rv, green: g, blue: b)))
                    }
                }
            }
        }
    }
}

private struct NewArtworkSheet: View {
    let onCreate: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Untitled"
    @State private var gridSize = 16

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Artwork name", text: $name)
                }
                Section("Grid Size") {
                    Picker("Size", selection: $gridSize) {
                        Text("8×8").tag(8)
                        Text("16×16").tag(16)
                        Text("32×32").tag(32)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Artwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        onCreate(name.isEmpty ? "Untitled" : name, gridSize)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
