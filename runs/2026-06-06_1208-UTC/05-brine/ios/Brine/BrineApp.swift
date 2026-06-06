import SwiftUI
import SwiftData

@main
struct BrineApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Tank.self, Reading.self, DoseEntry.self, CareTask.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Tank.self, Reading.self, DoseEntry.self, CareTask.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
