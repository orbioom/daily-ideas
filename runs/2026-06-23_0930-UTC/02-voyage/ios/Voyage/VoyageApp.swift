import SwiftUI
import SwiftData

@main
struct VoyageApp: App {
    /// Built once at launch. `nil` signals an unrecoverable store failure,
    /// which we surface as a calm error screen rather than crashing.
    private let container: ModelContainer?

    init() {
        container = PersistenceController.makeContainer()
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
            .tint(Theme.brand)
        }
    }
}
