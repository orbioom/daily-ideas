import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Attack.self, Trigger.self, Symptom.self, MedTaken.self, Medication.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: config) {
            container = c
        } else {
            let mem = ModelConfiguration(isStoredInMemoryOnly: true)
            container = (try? ModelContainer(for: schema, configurations: mem))
                ?? { fatalError("Unable to create in-memory ModelContainer") }()
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
