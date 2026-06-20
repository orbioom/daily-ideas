import SwiftUI
import SwiftData

@main
struct KinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Person.self, Relationship.self, LifeEvent.self, KinSettings.self])
        }
    }
}
