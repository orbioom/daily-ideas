import SwiftUI
import SwiftData

@main
struct TempoApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    /// Built once; nil only if SwiftData is completely unavailable, handled calmly.
    private let container = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    RootView(hasOnboarded: $hasOnboarded)
                        .modelContainer(container)
                        .task {
                            SeedData.seedIfNeeded(container.mainContext)
                        }
                } else {
                    StorageUnavailableView()
                }
            }
            .tint(Theme.accent)
        }
    }
}

/// Calm recoverable error screen shown only if persistence cannot initialize.
private struct StorageUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Storage Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Tempo couldn't open its workout database. Restart the app to try again — your saved sessions are safe.")
        }
        .padding()
    }
}

/// Switches between onboarding and the main tab interface based on the persisted flag.
struct RootView: View {
    @Binding var hasOnboarded: Bool

    var body: some View {
        if hasOnboarded {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingView(hasOnboarded: $hasOnboarded)
                .transition(.opacity)
        }
    }
}
