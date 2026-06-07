import SwiftUI
import SwiftData

@main
struct DatumApp: App {
    let container: ModelContainer
    init() {
        let schema = Schema([Aircraft.self, Station.self, EnvelopePoint.self, Flight.self, StationLoad.self])
        if let c = try? ModelContainer(for: schema) { container = c }
        else { container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
    }
    var body: some Scene { WindowGroup { RootView() }.modelContainer(container) }
}
