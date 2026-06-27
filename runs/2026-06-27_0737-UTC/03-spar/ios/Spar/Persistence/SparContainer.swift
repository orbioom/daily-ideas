import SwiftData

enum SparContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Fighter.self, TrainingSession.self, Technique.self, FightRecord.self, SparSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create Spar container: \(error)")
        }
    }()
}
