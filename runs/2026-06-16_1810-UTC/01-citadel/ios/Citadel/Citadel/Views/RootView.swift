import SwiftUI
import SwiftData

/// Top-level view: gates onboarding, seeds data once, and resolves the Theme from settings.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage(SettingsKeys.feltStyle) private var feltRaw = FeltStyle.emerald.rawValue
    @AppStorage("isPro") private var isPro = false

    @State private var didSeed = false

    private var theme: Theme {
        let felt = FeltStyle(rawValue: feltRaw) ?? .emerald
        // Non-Pro users always fall back to the free felt to keep state honest.
        let resolved = (felt.requiresPro && !isPro) ? .emerald : felt
        return Theme(felt: resolved)
    }

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
            } else {
                OnboardingView { hasOnboarded = true }
            }
        }
        .environment(\.theme, theme)
        .tint(Theme.accent)
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.seedResultsIfNeeded(context: modelContext)
        }
    }
}
