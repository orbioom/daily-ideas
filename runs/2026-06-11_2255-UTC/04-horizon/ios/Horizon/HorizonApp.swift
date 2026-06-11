import SwiftUI
import SwiftData

@main
struct HorizonApp: App {
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
        .modelContainer(for: Scenario.self)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "sunrise") }
            ScenariosView()
                .tabItem { Label("Scenarios", systemImage: "slider.horizontal.3") }
            CompareView()
                .tabItem { Label("Compare", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
