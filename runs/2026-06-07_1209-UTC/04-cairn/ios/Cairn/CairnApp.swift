import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: GearItem.self, PackList.self, PackEntry.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: GearItem.self, PackList.self, PackEntry.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
