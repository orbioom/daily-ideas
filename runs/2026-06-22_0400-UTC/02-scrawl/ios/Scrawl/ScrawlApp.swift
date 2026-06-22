import SwiftUI
import SwiftData

@main
struct ScrawlApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ScrawlRecord.self,
            CustomWordList.self,
            ScrawlSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [ScrawlSettings]

    var settings: ScrawlSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = ScrawlSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(settings: settings)
            }
        }
        .preferredColorScheme(nil)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Play", systemImage: "pencil.circle.fill")
                }
                .tag(0)

            PacksView()
                .tabItem {
                    Label("Packs", systemImage: "rectangle.stack.fill")
                }
                .tag(1)

            CustomWordsView()
                .tabItem {
                    Label("Custom", systemImage: "plus.square.fill")
                }
                .tag(2)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(ScrawlTheme.skyBlue)
    }
}
