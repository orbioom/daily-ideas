import SwiftUI
import SwiftData

/// Routes between onboarding and the main tab interface based on a persisted flag,
/// and performs first-run bootstrap (settings row + sample data seeding).
struct RootView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("ember.didOnboard") private var didOnboard = false
    @State private var didBootstrap = false

    var body: some View {
        Group {
            if didOnboard {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView(onFinish: completeOnboarding)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: didOnboard)
        .task { bootstrapIfNeeded() }
    }

    private func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true
        PersistenceController.bootstrap(context)
        syncHapticsFlag()
    }

    private func completeOnboarding() {
        didOnboard = true
    }

    private func syncHapticsFlag() {
        let settings = (try? context.fetch(FetchDescriptor<AppSettings>()))?.first
        Haptics.shared.enabled = settings?.hapticsEnabled ?? true
    }
}

#Preview {
    RootView()
        .previewModelContainer()
}
