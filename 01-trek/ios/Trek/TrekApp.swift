import SwiftUI
import SwiftData

@main
struct TrekApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Trail.self, HikeSession.self])
        }
    }
}
