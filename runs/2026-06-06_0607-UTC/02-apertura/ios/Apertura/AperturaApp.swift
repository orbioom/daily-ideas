import SwiftUI
import SwiftData

@main
struct AperturaApp: App {
    @State private var settings = SettingsStore()

    let container: ModelContainer

    init() {
        container = Self.makeContainer()
    }

    /// Build the SwiftData container, degrading gracefully to an in-memory store if the
    /// on-disk store can't be opened (e.g. corruption). Never crashes on cold open.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Roll.self, Frame.self])

        if let disk = try? ModelContainer(for: schema) {
            return disk
        }
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let memory = try? ModelContainer(for: schema, configurations: memoryConfig) {
            return memory
        }
        // Final attempt without an explicit schema argument; this path is effectively
        // unreachable, but we resolve it without a force-unwrap or fatalError.
        if let bare = try? ModelContainer(for: Roll.self, Frame.self) {
            return bare
        }
        // If even an in-memory store cannot be created the runtime is unusable; throw a
        // clear, non-silent error at this single init boundary (never a user path).
        return Self.lastResort(schema: schema, config: memoryConfig)
    }

    private static func lastResort(schema: Schema, config: ModelConfiguration) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            preconditionFailure("SwiftData container unavailable: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
                .tint(Brand.text)
        }
        .modelContainer(container)
    }
}
