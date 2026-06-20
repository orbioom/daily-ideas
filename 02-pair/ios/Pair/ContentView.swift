import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsList: [PairSettings]

    private var settings: PairSettings? { settingsList.first }
    private var hasCompletedOnboarding: Bool { settings?.hasCompletedOnboarding ?? false }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
