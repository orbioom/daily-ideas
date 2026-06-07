import SwiftUI
import SwiftData

@main
struct GambitApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Encounter.self, Combatant.self, StatBlock.self, DiceLog.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Encounter.self, Combatant.self, StatBlock.self, DiceLog.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
