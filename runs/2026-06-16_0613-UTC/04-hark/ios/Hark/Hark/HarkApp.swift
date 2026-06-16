import SwiftUI
import SwiftData

@main
struct HarkApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        let schema = Schema([HearingTest.self, Threshold.self, TinnitusMatch.self])
        if let onDisk = try? ModelContainer(for: schema) {
            container = onDisk
        } else if let mem = try? ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
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
            .tint(Theme.accent)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        }
        .modelContainer(container)
    }
}
