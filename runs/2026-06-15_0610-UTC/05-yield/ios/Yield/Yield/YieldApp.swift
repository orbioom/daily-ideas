import SwiftUI
import SwiftData

@main
struct YieldApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Holding.self, DividendPayment.self)
        } catch {
            // Fall back to an in-memory store so a corrupt on-disk store never blocks launch.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Holding.self, DividendPayment.self, configurations: config)
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
            .preferredColorScheme(settings.preferredColorScheme)
        }
        .modelContainer(container)
    }
}
