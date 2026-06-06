import SwiftUI
import SwiftData

@main
struct SpoolApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Spool.self, Printer.self, PrintJob.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Spool.self, Printer.self, PrintJob.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(container)
    }
}
