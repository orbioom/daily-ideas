import SwiftUI
import SwiftData

@main
struct DominoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameRecord.self,
            DominoSettings.self
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [DominoSettings]
    @State private var engine = DominoEngine()

    private var settings: DominoSettings {
        if let existing = settingsQuery.first {
            return existing
        }
        let newSettings = DominoSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                OnboardingView(settings: settings, engine: engine)
            } else {
                MainTabView(engine: engine, settings: settings)
            }
        }
        .preferredColorScheme(.dark)
    }
}
