import SwiftUI
import SwiftData

@main
struct QuestApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Game.self)
        } catch {
            let c = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Game.self, configurations: c)
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
        }
        .modelContainer(container)
    }
}
