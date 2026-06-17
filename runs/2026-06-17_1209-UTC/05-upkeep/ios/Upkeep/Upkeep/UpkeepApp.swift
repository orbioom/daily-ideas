import SwiftUI
import SwiftData

@main
struct UpkeepApp: App {
    @StateObject private var settings = AppSettings()
    private let container: ModelContainer?

    init() {
        let schema = Schema([
            HomeSystem.self,
            MaintenanceTask.self,
            CompletionLog.self
        ])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let disk = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = disk
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [mem])
        }
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
            .environmentObject(settings)
            .tint(Theme.accent)
        }
    }
}
