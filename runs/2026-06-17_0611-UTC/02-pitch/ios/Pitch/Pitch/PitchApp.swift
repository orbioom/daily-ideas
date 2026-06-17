import SwiftUI
import SwiftData

@main
struct PitchApp: App {

    /// Shared SwiftData container registering every @Model type in the schema.
    /// Optional so a store-open failure surfaces a calm screen instead of crashing.
    private let container: ModelContainer?

    // App-wide engines, created once and shared through the environment. All are
    // @MainActor @Observable, stored with @State per the app's single pattern.
    @State private var tuner = TunerEngine()
    @State private var metronome = MetronomeEngine()
    @State private var tone = ToneGenerator()

    init() {
        let schema = Schema([
            CustomTuning.self,
            MetronomePreset.self,
            PracticeLog.self
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
                    .environment(tuner)
                    .environment(metronome)
                    .environment(tone)
                    .tint(PitchTheme.indigo)
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
            PitchTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(PitchTheme.indigo)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                Text("Pitch couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
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
