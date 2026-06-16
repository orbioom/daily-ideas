import SwiftUI
import SwiftData

@main
struct LaneApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()
    @StateObject private var proStore = ProStore()

    let container: ModelContainer

    init() {
        let schema = Schema([
            Board.self,
            BoardColumn.self,
            Card.self,
            ChecklistItem.self,
            Label.self
        ])
        if let onDisk = try? ModelContainer(for: schema) {
            container = onDisk
        } else if let mem = try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ) {
            container = mem
        } else {
            fatalError("Unable to initialize ModelContainer.") // Unreachable: empty in-memory store cannot fail.
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    RootView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(settings)
            .environmentObject(proStore)
            .tint(Theme.accent)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
            .task {
                SeedData.seedIfNeeded(context: container.mainContext)
            }
        }
        .modelContainer(container)
    }
}
