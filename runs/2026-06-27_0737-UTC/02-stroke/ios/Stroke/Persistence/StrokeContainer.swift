import SwiftData

enum StrokeContainer {
    static let shared: ModelContainer = {
        let schema = Schema([RowWorkout.self, RowPR.self, StrokeSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create Stroke container: \(error)")
        }
    }()
}
