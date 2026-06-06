import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Exercise.self, Workout.self, SetEntry.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Exercise.self, Workout.self, SetEntry.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
