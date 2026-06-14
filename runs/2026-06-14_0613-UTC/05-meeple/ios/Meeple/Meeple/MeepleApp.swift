import SwiftUI
import SwiftData

@main
struct MeepleApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: BoardGame.self, Play.self, PlayerResult.self, Player.self)
        } catch {
            let c = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(
                for: BoardGame.self, Play.self, PlayerResult.self, Player.self,
                configurations: c
            )
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
