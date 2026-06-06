import SwiftUI
import SwiftData

@main
struct LarderApp: App {
    @State private var settings = SettingsStore()

    @State private var container: ModelContainer? = LarderApp.makeContainer()

    /// Builds the persistent store, degrading to an in-memory store if the on-disk one
    /// can't be opened (rare; e.g. a corrupt store). Returns `nil` only if even an
    /// in-memory store can't be created, which the UI handles with a calm error screen
    /// instead of crashing.
    private static func makeContainer() -> ModelContainer? {
        let schema = Schema([
            Item.self, Location.self, Category.self, ShoppingListEntry.self
        ])
        if let disk = try? ModelContainer(for: schema) {
            return disk
        }
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try? ModelContainer(for: schema, configurations: memoryConfig)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView()
                        .modelContainer(container)
                } else {
                    StoreUnavailableView()
                }
            }
            .environment(settings)
            .preferredColorScheme(settings.appearance.colorScheme)
            .tint(Brand.text)
        }
    }
}

/// Shown only in the extraordinary case that no data store could be created. Keeps the
/// app from crashing and gives the user a clear, calm message.
private struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Brand.pageBackground
            EmptyStateView(
                icon: "externaldrive.badge.exclamationmark",
                title: "Storage unavailable",
                message: "Larder couldn't open its data store. Restart the app, and if this keeps happening, free up some device storage.",
                actionTitle: nil,
                action: nil)
        }
    }
}
