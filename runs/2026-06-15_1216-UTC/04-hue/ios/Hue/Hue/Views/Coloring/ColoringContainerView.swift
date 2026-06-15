import SwiftUI
import SwiftData

/// Identifies which page to color and which (optional) existing artwork to resume.
struct ColoringRoute: Identifiable, Hashable {
    var id: String { (pageID) + (artworkID.map { "\($0.hashValue)" } ?? "new") }
    let pageID: String
    let artworkID: PersistentIdentifier?
}

/// Resolves the page + artwork, creates a new Artwork on demand, then hosts the canvas.
/// Handles the "page not found" and brief loading states.
struct ColoringContainerView: View {
    let route: ColoringRoute

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var customPalettes: [CustomPalette]

    @State private var artwork: Artwork?
    @State private var loadFailed = false
    @State private var isPreparing = true

    var body: some View {
        Group {
            if let page = PageLibrary.page(withID: route.pageID) {
                if let artwork {
                    ColoringCanvasScreen(page: page, artwork: artwork,
                                         customPalettes: customPalettes.map { $0.asPalette() })
                } else if loadFailed {
                    errorState
                } else if isPreparing {
                    loadingState
                } else {
                    errorState
                }
            } else {
                missingPageState
            }
        }
        .task(id: route.id) { await prepare() }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Preparing your page…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var errorState: some View {
        ContentUnavailableView {
            Label("Couldn't open this artwork", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Something went wrong loading this page. Please go back and try again.")
        } actions: {
            Button("Go back") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private var missingPageState: some View {
        ContentUnavailableView {
            Label("Page unavailable", systemImage: "questionmark.square.dashed")
        } description: {
            Text("This coloring page is no longer in the library.")
        } actions: {
            Button("Go back") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    @MainActor
    private func prepare() async {
        isPreparing = true
        loadFailed = false
        guard let page = PageLibrary.page(withID: route.pageID) else {
            isPreparing = false
            return
        }
        // Brief yield so the loading state can show for complex pages.
        await Task.yield()

        if let id = route.artworkID {
            if let existing = context.model(for: id) as? Artwork {
                artwork = existing
                isPreparing = false
                return
            }
            // Fall through to create new if the model couldn't be resolved.
        }

        // Create a fresh artwork.
        let paletteId = settings.defaultPaletteId
        let new = Artwork(pageID: page.id, title: page.title,
                          paletteId: paletteId, byNumberMode: settings.byNumberDefault)
        context.insert(new)
        try? context.save()
        artwork = new
        isPreparing = false
    }
}
