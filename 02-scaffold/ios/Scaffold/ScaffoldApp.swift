import SwiftUI
import SwiftData

@main
struct ScaffoldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Property.self, Room.self, Project.self,
                                      ProjectTask.self, Material.self,
                                      ProjectPhoto.self, ScaffoldSettings.self])
        }
    }
}
