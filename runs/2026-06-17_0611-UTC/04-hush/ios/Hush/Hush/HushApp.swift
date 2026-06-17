import SwiftUI
import SwiftData

@main
struct HushApp: App {

    /// Shared SwiftData container registering every @Model type in the schema.
    /// Optional so a store-open failure surfaces a calm screen instead of crashing.
    private let container: ModelContainer?

    /// App-wide observable singletons shared via the environment.
    @State private var settings = AppSettings()
    @State private var proStore = ProStore()
    @State private var engine = SoundEngine()
    @State private var sleepTimer = SleepTimer()

    init() {
        let schema = Schema([
            SavedMix.self,
            MixLayer.self,
            ListeningSession.self
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
                    .environment(engine)
                    .environment(sleepTimer)
                    .tint(HushTheme.teal)
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
            HushTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(HushTheme.teal)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(HushTheme.primaryText(scheme))
                Text("Hush couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(HushTheme.secondaryText(scheme))
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
