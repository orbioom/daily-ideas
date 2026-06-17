import SwiftUI
import SwiftData

/// The app shell: a TabView hosting the four feature areas plus Settings.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Int = 0
    @State private var studio: StudioModel

    init() {
        // Initialize the studio with sensible defaults; corrected from settings on appear.
        _studio = State(initialValue: StudioModel(grainDefault: true, aspect: .phone))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            StudioView()
                .tabItem { Label("Studio", systemImage: "wand.and.stars") }
                .tag(0)

            LibraryView(selectedTab: $selectedTab)
                .tabItem { Label("Library", systemImage: "square.stack.fill") }
                .tag(1)

            PalettesView(selectedTab: $selectedTab)
                .tabItem { Label("Palettes", systemImage: "paintpalette.fill") }
                .tag(2)

            PacksView(selectedTab: $selectedTab)
                .tabItem { Label("Packs", systemImage: "square.grid.2x2.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .environment(studio)
        .tint(Theme.accent)
        .onAppear {
            // Apply user defaults to the freshly created studio and seed sample data.
            studio.aspect = settings.defaultAspect
            if !settings.grainOnByDefault {
                studio.spec.grain = 0
            }
            SeedData.seedIfNeeded(modelContext)
        }
        .onChange(of: studio.pendingTabSwitch) { _, newValue in
            if newValue {
                selectedTab = 0
                studio.pendingTabSwitch = false
            }
        }
    }
}
