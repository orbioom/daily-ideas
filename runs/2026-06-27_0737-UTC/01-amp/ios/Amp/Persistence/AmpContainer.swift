import SwiftData
import Foundation

enum AmpContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Vehicle.self, ChargingSession.self, AmpSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            return container
        } catch {
            fatalError("Failed to create Amp model container: \(error)")
        }
    }()
}
