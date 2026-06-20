import SwiftUI
import SwiftData

@main
struct RampartApp: SwiftUI.App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: GameRecord.self, RampartSettings.self)
        } catch {
            fatalError("[RampartApp] ModelContainer failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
