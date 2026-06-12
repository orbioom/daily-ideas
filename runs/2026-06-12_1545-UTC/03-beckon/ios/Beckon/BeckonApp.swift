import SwiftUI
import SwiftData

@main
struct BeckonApp: App {
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
        .modelContainer(for: [Intention.self, PracticeLog.self])
    }

    private var colorScheme: ColorScheme? {
        switch appearance { case "light": return .light; case "dark": return .dark; default: return nil }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sparkles") }
            IntentionsView()
                .tabItem { Label("Intentions", systemImage: "star.circle") }
            InsightsView()
                .tabItem { Label("Journey", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { SeedData.installIfNeeded(context: context) }
    }
}
