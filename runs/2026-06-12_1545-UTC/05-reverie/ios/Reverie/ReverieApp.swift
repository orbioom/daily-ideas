import SwiftUI
import SwiftData

@main
struct ReverieApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .tint(Theme.accent)
            .preferredColorScheme(colorScheme)
        }
        .modelContainer(for: [Dream.self, DreamSign.self])
    }

    private var colorScheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        TabView {
            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
            SignsView()
                .tabItem { Label("Signs", systemImage: "sparkle.magnifyingglass") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            LearnView()
                .tabItem { Label("Learn", systemImage: "graduationcap.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { SeedData.installIfNeeded(context: context) }
    }
}
