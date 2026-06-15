import SwiftUI
import SwiftData

@main
struct StashApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @StateObject private var settings = AppSettings()
    let container: ModelContainer

    init() {
        let schema = Schema([LoyaltyCard.self, GiftCard.self, BalanceTransaction.self])
        if let onDisk = try? ModelContainer(for: schema) {
            container = onDisk
        } else if let inMemory = try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
            // The on-disk store couldn't be opened (e.g. a migration issue). Fall back
            // to an in-memory store so the app still launches rather than crashing.
            container = inMemory
        } else {
            // Truly unreachable in practice: an empty in-memory store cannot fail to
            // build. We surface a clear message instead of a silent force-unwrap.
            fatalError("Unable to initialize a ModelContainer for Stash.")
        }
    }

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
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
            .preferredColorScheme(appearance.colorScheme)
        }
        .modelContainer(container)
    }
}
