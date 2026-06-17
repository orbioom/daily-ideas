import SwiftUI
import SwiftData

@main
struct ParcelApp: App {

    /// Shared SwiftData container registering every @Model type.
    /// Optional so a store-open failure shows a calm screen instead of crashing.
    private let container: ModelContainer?

    /// App-wide preferences (UserDefaults-backed, observable).
    @State private var prefs = AppPreferences()

    /// Read-aloud synthesizer (Pro).
    @State private var speech = SpeechManager()

    init() {
        let schema = Schema([
            ExamResult.self,
            QuestionStat.self
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
                    .environment(prefs)
                    .environment(speech)
                    .modelContainer(container)
            } else {
                StoreUnavailableView()
            }
        }
    }
}

/// Calm, recoverable error screen shown if the data store cannot be opened at all.
struct StoreUnavailableView: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            Theme.background(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 46))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Storage unavailable")
                    .font(Theme.title)
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("Parcel couldn't open its data store. Please relaunch the app — your device may be low on space.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Routes between onboarding and the main tabbed experience.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

/// The four feature tabs plus Settings.
struct MainTabView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Study", systemImage: "house.fill") }
            TopicsView()
                .tabItem { Label("Topics", systemImage: "square.grid.2x2.fill") }
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.accent)
    }
}
