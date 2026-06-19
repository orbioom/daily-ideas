import SwiftUI
import SwiftData

@main
struct KeysApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: PracticeSession.self, UserSettings.self
            )
        } catch {
            // Attempt recovery by destroying and recreating the store
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = (try? ModelContainer(
                for: PracticeSession.self, UserSettings.self,
                configurations: config
            )) ?? {
                fatalError("Could not create ModelContainer")
            }()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
