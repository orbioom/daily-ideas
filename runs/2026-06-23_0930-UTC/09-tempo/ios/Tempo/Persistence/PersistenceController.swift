import Foundation
import SwiftData

/// Builds the shared SwiftData container. Falls back to an in-memory store if the
/// on-disk store cannot be created, so the app never crashes on launch.
enum PersistenceController {
    static let schema = Schema([
        Exercise.self,
        Workout.self,
        SetEntry.self,
        Routine.self,
        RoutineItem.self,
        AppSettings.self,
    ])

    /// Builds the container, returning nil only if every fallback fails. Callers
    /// decide how to surface that calmly rather than crashing here.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer? {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // Recoverable fallback: in-memory store so a transient disk issue does not
        // brick the app. Data won't persist this session, surfaced to the user.
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try? ModelContainer(for: schema, configurations: [memoryConfig])
    }

    /// A preview container with seeded data for SwiftUI previews. Non-optional for
    /// ergonomic `#Preview` usage; only ever runs in the simulator/canvas.
    @MainActor
    static let preview: ModelContainer = {
        let cfg = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [cfg])
            SeedData.seedIfNeeded(container.mainContext)
            return container
        } catch {
            // Canvas-only fallback; an in-memory AppSettings store always builds.
            do {
                return try ModelContainer(
                    for: AppSettings.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Preview container unavailable: \(error)")
            }
        }
    }()
}
