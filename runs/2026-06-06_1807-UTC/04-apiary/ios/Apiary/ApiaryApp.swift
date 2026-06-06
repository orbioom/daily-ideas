import SwiftUI
import SwiftData

@main
struct ApiaryApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Apiary.self, Hive.self, Inspection.self,
                                           Treatment.self, Harvest.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Apiary.self, Hive.self, Inspection.self,
                                            Treatment.self, Harvest.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
