import SwiftUI
import SwiftData

/// Root tab interface. Five substantive sections.
struct MainTabView: View {
    @Query private var settingsRows: [AppSettings]

    private var settings: AppSettings? { settingsRows.first }

    var body: some View {
        TabView {
            BreatheHomeView()
                .tabItem { Label("Breathe", systemImage: "wind") }

            PatternsView()
                .tabItem { Label("Patterns", systemImage: "square.grid.2x2") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onAppear {
            Haptics.shared.enabled = settings?.hapticsEnabled ?? true
        }
    }
}

#Preview {
    MainTabView()
        .previewModelContainer()
}
