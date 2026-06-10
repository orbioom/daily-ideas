import SwiftUI
import SwiftData

@main
struct MosaicApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: CollageProject.self, CollageCell.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: CollageProject.self, CollageCell.self, configurations: config)
        }
        Haptics.enabled = UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
