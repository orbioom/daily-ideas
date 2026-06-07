import SwiftUI
import SwiftData

@main
struct VialApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Medication.self, DoseLog.self, Refill.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Medication.self, DoseLog.self, Refill.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
