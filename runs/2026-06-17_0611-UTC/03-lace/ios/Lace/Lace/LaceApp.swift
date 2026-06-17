import SwiftUI
import SwiftData

@main
struct LaceApp: App {

    /// Shared SwiftData container registering every @Model type.
    /// Optional so a store-open failure surfaces a calm screen, never a crash.
    private let container: ModelContainer?

    /// App-wide preferences & the simulated Pro entitlement, shared via environment.
    @State private var settings = AppSettings()
    @State private var proStore = ProStore()

    init() {
        let schema = Schema([
            ActivePlan.self,
            CompletedSession.self,
            CustomPlan.self,
            CustomSession.self,
            CustomInterval.self
        ])
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            container = c
        } else {
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try? ModelContainer(for: schema, configurations: [mem])
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
                    .environment(settings)
                    .environment(proStore)
                    .tint(Theme.coral)
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
            Theme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.coral)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Text("Lace couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Routes between onboarding and the main tabbed experience, seeds data once,
/// and keeps the custom-plan resolver registry fresh for run restoration.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query private var customPlans: [CustomPlan]

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
            registerCustomPlans()
        }
        .onChange(of: customPlans.count) { _, _ in
            registerCustomPlans()
        }
    }

    private func registerCustomPlans() {
        PlanResolver.shared.registerCustom(customPlans.map { $0.asTrainingPlan() })
    }
}
