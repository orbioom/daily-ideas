import SwiftUI
import SwiftData

@main
struct SweepApp: App {
    let container: ModelContainer
    @StateObject private var library = PhotoLibraryService()

    init() {
        let schema = Schema([KeptPhoto.self, CleanSession.self])
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
        WindowGroup {
            RootView().environmentObject(library)
        }
        .modelContainer(container)
    }
}
