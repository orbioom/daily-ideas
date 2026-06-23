import SwiftUI
import SwiftData

/// Resolves the singleton settings row, gates onboarding, ensures sample data is
/// seeded once, and applies the user's appearance preference.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]
    @Query private var pets: [Pet]

    @State private var didBootstrap = false

    private var settings: AppSettings? { settingsRows.first }

    var body: some View {
        Group {
            if let settings {
                if settings.hasOnboarded {
                    MainTabView(settings: settings)
                } else {
                    OnboardingView(settings: settings)
                }
            } else {
                // Brief loading state while we create the settings row.
                LoadingView(message: "Setting up Petal…")
            }
        }
        .preferredColorScheme(colorScheme(for: settings?.appearance ?? .system))
        .task { bootstrap() }
    }

    private func colorScheme(for mode: AppearanceMode) -> ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Creates the settings row and seeds sample data on first launch.
    private func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true
        if settingsRows.isEmpty {
            let new = AppSettings()
            context.insert(new)
        }
        if pets.isEmpty {
            SampleData.seed(into: context)
        }
        try? context.save()
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.preview.container)
}
