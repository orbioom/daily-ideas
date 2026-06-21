import SwiftUI
import SwiftData

@main
struct NovaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [ObservingSession.self, NovaSettings.self])
        }
    }
}

struct RootView: View {
    @Query private var settings: [NovaSettings]

    var body: some View {
        if settings.first?.hasCompletedOnboarding == true {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
