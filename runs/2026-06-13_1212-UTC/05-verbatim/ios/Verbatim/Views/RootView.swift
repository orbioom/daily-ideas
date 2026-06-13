import SwiftUI
import SwiftData

/// The four feature tabs plus Settings. Each tab owns its own NavigationStack.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var pro = ProStore()
    @AppStorage("didSeedLibrary") private var didSeedLibrary = false

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            TodayView()
                .tabItem { Label("Today", systemImage: "calendar.badge.clock") }
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environment(pro)
        .tint(Theme.accent)
        .task { seedIfNeeded() }
    }

    /// Seed three sample passages exactly once, after onboarding.
    private func seedIfNeeded() {
        guard !didSeedLibrary else { return }
        didSeedLibrary = true
        SeedContent.insertSamples(into: context)
    }
}
