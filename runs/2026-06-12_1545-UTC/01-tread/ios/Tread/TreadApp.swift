import SwiftUI
import SwiftData

@main
struct TreadApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var pedometer = PedometerService()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                        .environment(pedometer)
                } else {
                    OnboardingView()
                        .environment(pedometer)
                }
            }
            .tint(Theme.accent)
        }
        .modelContainer(for: [DayLog.self, Badge.self])
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.walk") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.xaxis") }
            BadgesView()
                .tabItem { Label("Badges", systemImage: "rosette") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
