import SwiftUI
import SwiftData

@main
struct PetalApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.accent)
        }
        .modelContainer(persistence.container)
    }
}
