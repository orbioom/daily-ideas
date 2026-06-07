import SwiftUI
import SwiftData

@main
struct ChainsApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: DiscCourse.self, Hole.self, Round.self, HoleScore.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: DiscCourse.self, Hole.self, Round.self, HoleScore.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
