import SwiftUI
import SwiftData

@main
struct FieldApp: App {
    var body: some Scene {
        WindowGroup {
            FieldRootView()
        }
        .modelContainer(for: [Observation.self, FieldTrip.self, FieldSettings.self])
    }
}
