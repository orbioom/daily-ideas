import SwiftUI
import SwiftData

@main
struct AscendApp: App {
    @StateObject private var settings = AppSettings()
    private let container: ModelContainer?

    init() {
        let schema = Schema([
            Program.self,
            ProgramDay.self,
            ProgramExercise.self,
            WorkoutSession.self,
            LoggedExercise.self,
            LoggedSet.self
        ])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [mem])
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .environmentObject(settings)
                    .tint(Theme.accent)
                    .modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}
