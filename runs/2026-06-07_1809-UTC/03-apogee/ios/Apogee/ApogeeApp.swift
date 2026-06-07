import SwiftUI
import SwiftData

@main
struct ApogeeApp: App {
    let container: ModelContainer
    init() {
        let schema = Schema([Rocket.self, Motor.self, Flight.self])
        if let c = try? ModelContainer(for: schema) { container = c }
        else { container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
