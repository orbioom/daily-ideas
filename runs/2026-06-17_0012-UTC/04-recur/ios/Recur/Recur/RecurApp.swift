import SwiftUI
import SwiftData

@main
struct RecurApp: App {

    /// Shared SwiftData container registering every @Model type in the schema.
    /// Optional so a store-open failure surfaces a calm screen instead of a crash.
    private let container: ModelContainer?

    init() {
        let schema = Schema([
            Subscription.self,
            PriceChange.self
        ])
        // Try the on-disk store first; fall back to an in-memory store so the
        // app stays usable even if the persistent store can't be opened.
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [memory])
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}

/// Calm, recoverable error screen shown if the data store cannot be opened at all.
private struct StoreUnavailableView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            RecurTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(RecurTheme.coral)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                Text("Recur couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Routes between onboarding and the main tabbed experience, and seeds data once.
struct RootView: View {
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded: Bool = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            SeedData.seedIfNeeded(modelContext)
        }
    }
}
