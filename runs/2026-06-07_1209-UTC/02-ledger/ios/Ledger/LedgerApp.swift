import SwiftUI
import SwiftData

@main
struct LedgerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Account.self, Snapshot.self, SnapshotEntry.self, Target.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Account.self, Snapshot.self, SnapshotEntry.self, Target.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
