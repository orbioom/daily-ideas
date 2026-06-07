import SwiftUI
import SwiftData

@main
struct CapoApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Song.self, Section.self, Setlist.self, SetlistItem.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Song.self, Section.self, Setlist.self, SetlistItem.self,
                                            configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
