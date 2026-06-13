import SwiftUI
import SwiftData

@main
struct PlumbApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Account.self, BalanceEntry.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Account.self, BalanceEntry.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded { RootView() } else { OnboardingView() }
            }
            .tint(Theme.accent)
        }
        .modelContainer(container)
    }
}
