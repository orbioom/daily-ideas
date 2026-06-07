import SwiftUI
import SwiftData

@main
struct ReserveApp: App {
    let container: ModelContainer
    init() {
        let schema = Schema([PowerSystem.self, Load.self])
        if let c = try? ModelContainer(for: schema) { container = c }
        else { container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
