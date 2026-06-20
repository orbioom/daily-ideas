import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsArray: [GlowSettings]

    private var hasCompletedOnboarding: Bool {
        settingsArray.first?.hasCompletedOnboarding ?? false
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedProduct.self, GlowSettings.self], inMemory: true)
}
