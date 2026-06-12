import SwiftUI
import SwiftData

@main
struct MonikerApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootTabView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: Decision.self)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            SwipeView()
                .tabItem { Label("Swipe", systemImage: "hand.draw.fill") }
            MatchesView()
                .tabItem { Label("Matches", systemImage: "heart.fill") }
            BrowseView()
                .tabItem { Label("Browse", systemImage: "magnifyingglass") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(MonikerTheme.roseDeep)
    }
}
