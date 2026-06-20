import SwiftUI
import SwiftData

@main
struct GammonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: GammonResult.self)
                .preferredColorScheme(.dark)
        }
    }
}
