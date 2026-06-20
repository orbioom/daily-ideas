import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var settingsArray: [GlowSettings]

    private var settings: GlowSettings? { settingsArray.first }

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            AnalyzerView()
                .tabItem {
                    Label("Analyzer", systemImage: "sparkles")
                }

            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "tray.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(GlowTheme.accent)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
