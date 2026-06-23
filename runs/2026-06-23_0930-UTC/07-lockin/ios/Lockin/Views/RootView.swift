import SwiftUI
import SwiftData

/// Hosts onboarding gating and the main tab bar.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @State private var didSeed = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView { hasOnboarded = true }
            }
        }
        .tint(Theme.Palette.brand)
        .task {
            guard !didSeed else { return }
            didSeed = true
            SampleData.seedIfNeeded(context)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
            TasksView()
                .tabItem { Label("Tasks", systemImage: "folder.fill") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
