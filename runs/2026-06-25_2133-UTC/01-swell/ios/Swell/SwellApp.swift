import SwiftUI
import SwiftData

@main
struct SwellApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [SurfSession.self, SurfSpot.self, Board.self, SurfSettings.self])
    }
}
