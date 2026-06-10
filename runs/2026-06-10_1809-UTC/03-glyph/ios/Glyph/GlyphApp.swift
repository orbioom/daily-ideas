import SwiftUI
import SwiftData

@main
struct GlyphApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: SudokuGame.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: SudokuGame.self, configurations: config)
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
