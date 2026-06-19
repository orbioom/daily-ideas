import SwiftUI
import SwiftData

@main
struct VolleyApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: Question.self, GameSession.self
            )
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = (try? ModelContainer(
                for: Question.self, GameSession.self,
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
