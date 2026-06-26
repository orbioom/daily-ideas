import SwiftUI
import SwiftData

@main
struct SplashApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: SwimPool.self, SwimSession.self, SwimSet.self, SplashSettings.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}

struct RootView: View {
    @Query private var settingsAll: [SplashSettings]
    @Environment(\.modelContext) private var context

    var settings: SplashSettings {
        if let s = settingsAll.first { return s }
        let s = SplashSettings()
        context.insert(s)
        try? context.save()
        return s
    }

    var body: some View {
        if !settings.hasSeenOnboarding {
            OnboardingView(hasSeenOnboarding: Binding(
                get: { settings.hasSeenOnboarding },
                set: { v in
                    settings.hasSeenOnboarding = v
                    if v { SeedData.seedIfNeeded(context: context) }
                    try? context.save()
                }
            ))
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(SplashTheme.accent)
    }
}
