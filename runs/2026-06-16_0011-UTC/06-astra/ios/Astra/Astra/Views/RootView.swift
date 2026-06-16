import SwiftUI
import SwiftData

/// Root tab container. Seeds example data on first launch.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.and.horizon.fill") }

            ChartView()
                .tabItem { Label("Chart", systemImage: "circle.hexagongrid.fill") }

            PlacementsView()
                .tabItem { Label("Placements", systemImage: "list.star") }

            CompatibilityView()
                .tabItem { Label("Compatibility", systemImage: "heart.circle.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            if let primaryID = SeedData.seedIfEmpty(context: modelContext) {
                if settings.primaryProfileID.isEmpty {
                    settings.primaryProfileID = primaryID.uuidString
                }
            }
        }
    }
}
