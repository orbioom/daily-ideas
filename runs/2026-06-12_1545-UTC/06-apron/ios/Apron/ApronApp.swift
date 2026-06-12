import SwiftUI
import SwiftData

@main
struct ApronApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

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
        }
        .modelContainer(for: [Job.self, Shift.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "chart.line.uptrend.xyaxis") }
            ShiftsView()
                .tabItem { Label("Shifts", systemImage: "list.bullet.rectangle") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
            JobsView()
                .tabItem { Label("Jobs", systemImage: "briefcase.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task { SeedData.installIfNeeded(context: context) }
    }
}
