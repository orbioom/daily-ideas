import SwiftUI
import SwiftData

@main
struct OcheApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Match.self, Leg.self, PracticeSession.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Match.self, Leg.self, PracticeSession.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
