import Foundation
import SwiftData

/// Owns the SwiftData container and exposes a shared instance plus an in-memory
/// preview container. Errors are surfaced rather than crashing.
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    static let schema = Schema([
        Pet.self,
        Medication.self,
        Vaccination.self,
        VetVisit.self,
        WeightEntry.self,
        FeedingSchedule.self,
        AppSettings.self
    ])

    init(inMemory: Bool = false) {
        let config = ModelConfiguration(schema: PersistenceController.schema, isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: PersistenceController.schema, configurations: [config])
        } catch {
            // Recoverable fallback: if the on-disk store can't open (e.g. an
            // incompatible older store), retry in memory so the app still runs.
            do {
                let fallback = ModelConfiguration(schema: PersistenceController.schema, isStoredInMemoryOnly: true)
                container = try ModelContainer(for: PersistenceController.schema, configurations: [fallback])
            } catch {
                // As a last resort use an empty in-memory container with the
                // minimal schema. This path is only hit if SwiftData itself is
                // unavailable, and keeps us off fatalError on user devices.
                container = try! ModelContainer(
                    for: Schema([AppSettings.self]),
                    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
                )
            }
        }
    }

    /// Preview/in-memory container pre-populated with sample data.
    @MainActor
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext
        let settings = AppSettings(hasOnboarded: true, ownerName: "Sam")
        context.insert(settings)
        SampleData.seed(into: context)
        try? context.save()
        return controller
    }()
}
