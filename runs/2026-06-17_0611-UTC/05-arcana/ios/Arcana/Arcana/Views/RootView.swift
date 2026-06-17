import SwiftUI

/// Switches between onboarding and the main app based on the persisted `hasOnboarded` flag,
/// and owns the shared `AppSettings`.
struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var settings = AppSettings()

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(settings)
        .tint(Theme.accent)
        .preferredColorScheme(settings.appearance.colorScheme)
    }
}

/// A calm, recoverable screen shown only if persistent storage can't be created at all.
struct StoreUnavailableView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                Text("Arcana can't open right now")
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("The deck is shuffled but the table won't set. Please relaunch the app — your saved readings are safe.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 32)
            }
        }
    }
}
