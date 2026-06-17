import SwiftUI
import SwiftData

@main
struct ArcanaApp: App {
    private let container: ModelContainer?

    init() {
        let schema = Schema([Reading.self, DrawnCard.self, DailyDraw.self])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [mem])
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView().modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}
