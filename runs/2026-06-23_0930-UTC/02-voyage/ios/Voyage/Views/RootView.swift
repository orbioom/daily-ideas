import SwiftUI
import SwiftData

/// Decides between onboarding and the main tab interface based on a persisted flag.
struct RootView: View {
    @AppStorage("voyage.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
                .transition(.opacity)
        } else {
            OnboardingView {
                withAnimation(.easeInOut) { hasOnboarded = true }
            }
            .transition(.opacity)
        }
    }
}

/// Calm, recoverable error screen shown if the data store cannot be created.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.brand)
                    .accessibilityHidden(true)
                Text("Storage Unavailable")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("Voyage couldn't open its phrase library. Please relaunch the app. If this keeps happening, restart your device to free up storage.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        RootView().modelContainer(container)
    } else {
        StoreUnavailableView()
    }
}
