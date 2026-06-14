import SwiftUI
import SwiftData

/// Top-level tab container. Seeds realistic sample data on first ever launch.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("didSeedSamples") private var didSeedSamples = false
    @Query private var events: [CountdownEvent]

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Timeline", systemImage: "rectangle.stack.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            TemplatesView()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
        .onAppear(perform: seedIfNeeded)
    }

    private func seedIfNeeded() {
        guard !didSeedSamples else { return }
        // Only seed when truly empty to avoid duplicating a user's own data.
        if events.isEmpty {
            SampleData.seed(into: context)
        }
        didSeedSamples = true
    }
}
