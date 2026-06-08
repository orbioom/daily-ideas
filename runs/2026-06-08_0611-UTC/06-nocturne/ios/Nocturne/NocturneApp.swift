import SwiftUI
import SwiftData

@main
struct NocturneApp: App {
    @AppStorage("nocturne.haptics") private var hapticsEnabled = true

    let container: ModelContainer = {
        let schema = Schema([SleepLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            return c
        }
        // Fallback: in-memory (only allowed try! per spec)
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
