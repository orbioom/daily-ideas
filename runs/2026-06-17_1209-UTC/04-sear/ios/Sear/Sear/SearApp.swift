import SwiftUI
import SwiftData

@main
struct SearApp: App {
    private let container: ModelContainer?
    @State private var settings = AppSettings()

    init() {
        let schema = Schema([Cook.self, TempLog.self, Rub.self])
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
                RootView()
                    .environment(settings)
                    .tint(Theme.accent)
                    .modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}
