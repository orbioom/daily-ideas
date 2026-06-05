import SwiftUI
import SwiftData

/// Root container: seeds sample data once, gates onboarding, hosts the tab bar.
struct RootView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var bottles: [Bottle]

    var body: some View {
        ZStack {
            Brand.pageBackground

            if !settings.hasOnboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                TabView {
                    CellarListView()
                        .tabItem { Label("Cellar", systemImage: "square.grid.2x2.fill") }
                    InsightsView()
                        .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
                .transition(.opacity)
            }
        }
        .animation(Brand.ease(), value: settings.hasOnboarded)
        .task { seedIfNeeded() }
    }

    /// Insert the starter cellar exactly once, on the very first launch.
    private func seedIfNeeded() {
        guard !settings.hasSeeded, bottles.isEmpty else { return }
        SampleData.insert(into: context)
        settings.hasSeeded = true
    }
}
