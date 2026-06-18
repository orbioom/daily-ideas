import SwiftUI
import SwiftData

/// Full-screen detail for a single moment, with edit / favorite / delete /
/// share (a rendered card via ImageRenderer).
struct MomentDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let moment: Moment

    @State private var showEditor = false
    @State private var showDeleteConfirm = false
    @State private var shareImage: ShareableImage?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MomentImageView(filename: moment.imageFilename, pointSize: 700, cornerRadius: Theme.cardRadius, fullResolution: true)
                    .aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)

                HStack {
                    MoodPill(mood: moment.mood)
                    Spacer()
                    Text(Self.dateFormatter.string(from: moment.displayDate))
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }

                if !moment.title.isEmpty {
                    Text(moment.title)
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.ink)
                }

                if !moment.caption.isEmpty {
                    Text(moment.caption)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !moment.tags.isEmpty {
                    FlowTags(tags: moment.tags)
                }

                actions
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditor = true
                    } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(moment.isFavorite ? "Remove favorite" : "Add to favorites",
                              systemImage: moment.isFavorite ? "heart.slash" : "heart")
                    }
                    Button {
                        renderShareCard()
                    } label: { Label("Share card", systemImage: "square.and.arrow.up") }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            MomentEditorView(dayKey: moment.dayKey, existing: moment)
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(image: item.image)
        }
        .confirmationDialog("Delete this moment?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the photo and its caption. This can't be undone.")
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                toggleFavorite()
            } label: {
                Label(moment.isFavorite ? "Favorited" : "Favorite",
                      systemImage: moment.isFavorite ? "heart.fill" : "heart")
                    .font(Theme.rounded(15, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(moment.isFavorite ? Theme.accent : Theme.ink)
            }
            .buttonStyle(.plain)

            Button {
                renderShareCard()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(Theme.rounded(15, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleFavorite() {
        moment.isFavorite.toggle()
        Haptics.tap(settings.hapticsEnabled)
        try? context.save()
    }

    private func delete() {
        ImageStore.shared.delete(moment.imageFilename)
        context.delete(moment)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        dismiss()
    }

    @MainActor
    private func renderShareCard() {
        let card = ShareCard(moment: moment)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareImage = ShareableImage(image: image)
            Haptics.tap(settings.hapticsEnabled)
        }
    }
}

/// Wrapper so the rendered UIImage is Identifiable for `.sheet(item:)`.
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Simple wrapping tag layout for detail.
struct FlowTags: View {
    let tags: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { TagChip(tag: $0) }
            }
        }
    }
}
