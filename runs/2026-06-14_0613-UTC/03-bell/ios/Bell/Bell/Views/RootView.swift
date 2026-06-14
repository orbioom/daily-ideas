import SwiftUI
import SwiftData

/// Tab shell. Seeds sample data on first appearance and presents the immersive
/// session player as a full-screen cover so the timer owns the whole screen.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false
    @EnvironmentObject private var settings: AppSettings

    @State private var activePreset: Preset?

    var body: some View {
        TabView {
            TodayView(activePreset: $activePreset)
                .tabItem { Label("Today", systemImage: "circle.hexagongrid") }

            PresetsView(activePreset: $activePreset)
                .tabItem { Label("Presets", systemImage: "slider.horizontal.3") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }

            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.accent)
        .task {
            didSeed = SeedData.seedIfNeeded(context: context, didSeed: didSeed)
        }
        .fullScreenCover(item: $activePreset) { preset in
            SessionPlayerView(preset: preset)
                .environmentObject(settings)
        }
    }
}
