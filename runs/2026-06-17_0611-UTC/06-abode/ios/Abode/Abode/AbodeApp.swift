import SwiftUI
import SwiftData

@main
struct AbodeApp: App {

    /// Shared SwiftData container registering every @Model type. Optional so a
    /// store-open failure surfaces a calm screen instead of crashing.
    private let container: ModelContainer?

    @State private var settings = AppSettings()
    @State private var proStore = ProStore()

    init() {
        let schema = Schema([
            MortgageScenario.self,
            AffordabilityProfile.self
        ])
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
                    .environment(settings)
                    .environment(proStore)
                    .tint(AbodeTheme.accent)
            } else {
                StoreUnavailableView()
            }
        }
    }
}

/// Calm, recoverable error screen shown if the data store cannot be opened.
private struct StoreUnavailableView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            AbodeTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(AbodeTheme.accent)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AbodeTheme.primaryText(scheme))
                Text("Abode couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(AbodeTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Routes between onboarding and the main tabbed experience, and seeds data once.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            // Keep currency / cents formatting in sync with saved prefs at launch.
            Format.configure(currencyCode: settings.currencyCode, showCents: settings.showCents)
            SeedData.seedIfNeeded(modelContext)
        }
    }
}
