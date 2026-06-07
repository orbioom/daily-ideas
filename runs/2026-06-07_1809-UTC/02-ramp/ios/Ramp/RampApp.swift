import SwiftUI
import SwiftData

@main
struct RampApp: App {
    let container: ModelContainer
    init() {
        let schema = Schema([Ride.self, FTPEntry.self])
        if let c = try? ModelContainer(for: schema) { container = c }
        else { container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
