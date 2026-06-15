import SwiftUI
import SwiftData

struct MyArtworksView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Artwork.updatedAt, order: .reverse) private var artworks: [Artwork]
    @Query private var customPalettes: [CustomPalette]

    @State private var route: ColoringRoute?
    @State private var detail: Artwork?
    @State private var filter: ArtFilter = .all

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private enum ArtFilter: String, CaseIterable, Identifiable {
        case all = "All", inProgress = "In progress", completed = "Completed"
        var id: String { rawValue }
    }

    private var resolvedCustom: [Palette] { customPalettes.map { $0.asPalette() } }

    /// Only show artworks whose page still exists in the library.
    private var valid: [Artwork] {
        artworks.filter { PageLibrary.page(withID: $0.pageID) != nil }
    }

    private var filtered: [Artwork] {
        switch filter {
        case .all: return valid
        case .inProgress: return valid.filter { !$0.isCompleted }
        case .completed: return valid.filter { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if valid.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("My Art")
            .navigationDestination(item: $route) { route in
                ColoringContainerView(route: route)
            }
            .sheet(item: $detail) { art in
                ArtworkDetailView(artwork: art,
                                  palette: PaletteLibrary.resolve(id: art.paletteId, custom: resolvedCustom),
                                  isPro: isPro,
                                  onContinue: { continueEditing(art) })
            }
        }
    }

    private var content: some View {
        ScrollView {
            Picker("Filter", selection: $filter) {
                ForEach(ArtFilter.allCases) { f in Text(f.rawValue).tag(f) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            if filtered.isEmpty {
                Text("No \(filter.rawValue.lowercased()) artworks yet.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { art in
                        cell(art)
                    }
                }
                .padding(20)
            }
        }
    }

    private func cell(_ art: Artwork) -> some View {
        guard let page = PageLibrary.page(withID: art.pageID) else {
            return AnyView(EmptyView())
        }
        let palette = PaletteLibrary.resolve(id: art.paletteId, custom: resolvedCustom)
        return AnyView(
            Button {
                detail = art
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    ArtworkThumb(artwork: art, page: page, palette: palette, side: 150)
                        .overlay(alignment: .topTrailing) {
                            if art.isCompleted {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.good)
                                    .padding(8)
                                    .accessibilityHidden(true)
                            }
                        }
                    Text(art.title)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    ProgressBadge(filled: art.filledCount, total: page.regionCount)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(art.title), \(art.isCompleted ? "completed" : "\(percent(art, page)) percent filled")")
            .accessibilityHint("Opens details, continue or export")
            .contextMenu {
                Button { continueEditing(art) } label: { Label("Continue", systemImage: "paintbrush") }
                Button(role: .destructive) { delete(art) } label: { Label("Delete", systemImage: "trash") }
            }
        )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No artworks yet", systemImage: "paintpalette")
        } description: {
            Text("Pick a page from the Gallery and start coloring. Your work appears here automatically.")
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func percent(_ art: Artwork, _ page: ColoringPage) -> Int {
        guard page.regionCount > 0 else { return 0 }
        return Int((Double(art.filledCount) / Double(page.regionCount)) * 100)
    }

    private func continueEditing(_ art: Artwork) {
        guard PageLibrary.page(withID: art.pageID) != nil else { return }
        let target = ColoringRoute(pageID: art.pageID, artworkID: art.persistentModelID)
        detail = nil
        // Defer the push so the sheet finishes dismissing first (avoids a presentation race).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            route = target
        }
    }

    private func delete(_ art: Artwork) {
        context.delete(art)
        try? context.save()
    }
}
