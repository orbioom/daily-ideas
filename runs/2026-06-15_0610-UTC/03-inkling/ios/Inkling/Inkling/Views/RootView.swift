import SwiftUI
import SwiftData

/// Root tab bar. Seeds the starter library + synthetic history on first appearance so every screen
/// is rich immediately.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("didSeed") private var didSeed = false
    @AppStorage("onboardingPicks") private var onboardingPicksRaw = ""

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "square.and.pencil") }

            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "sparkles") }

            TrendsScreen()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            TrackersScreen()
                .tabItem { Label("Trackers", systemImage: "checklist") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            var seeded = didSeed
            let picks = onboardingPicksRaw.isEmpty
                ? nil
                : onboardingPicksRaw.split(separator: "|").map(String.init)
            SeedData.seedIfNeeded(context: context, didSeed: &seeded, activeNames: picks)
            didSeed = seeded
        }
    }
}
