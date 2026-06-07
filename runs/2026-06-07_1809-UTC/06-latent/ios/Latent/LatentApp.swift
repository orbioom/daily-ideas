import SwiftUI
import SwiftData

/// App entry point. Builds the SwiftData container for the two persistent models
/// and falls back to an in-memory store if the on-disk store can't be opened, so
/// the app always launches into a usable state.
@main
struct LatentApp: App {
    let container: ModelContainer
    init() {
        let schema = Schema([Recipe.self, DevSession.self])
        if let c = try? ModelContainer(for: schema) { container = c }
        else { container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
