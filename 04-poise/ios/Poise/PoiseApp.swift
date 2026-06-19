import SwiftUI
import SwiftData

@main
struct PoiseApp: App {
    @State private var scheduler = BreakScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scheduler)
        }
        .modelContainer(for: [BreakRecord.self, UserSchedule.self])
    }
}
