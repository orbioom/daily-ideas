import SwiftUI
import SwiftData

@main
struct SurgeApp: SwiftUI.App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RunnerProfile.self,
            PlannedRun.self,
            RunLog.self,
            SurgeSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [RunnerProfile]
    @Query private var settings: [SurgeSettings]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasCompletedOnboarding {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            seedSettingsIfNeeded()
        }
        .preferredColorScheme(.dark)
    }

    private func seedSettingsIfNeeded() {
        if settings.isEmpty {
            let defaultSettings = SurgeSettings()
            modelContext.insert(defaultSettings)
        }
    }
}

struct MainTabView: View {
    let profile: RunnerProfile
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(profile: profile)
                .tabItem {
                    Label("Today", systemImage: "bolt.fill")
                }
                .tag(0)

            PlanView(profile: profile)
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(1)

            WeekView(profile: profile)
                .tabItem {
                    Label("Week", systemImage: "list.bullet.rectangle")
                }
                .tag(2)

            RunHistoryView()
                .tabItem {
                    Label("Log", systemImage: "square.and.pencil")
                }
                .tag(3)

            InsightsView(profile: profile)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(.surgeAccent)
    }
}
