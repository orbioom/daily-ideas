import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settingsQuery: [RampartSettings]

    private var hasCompletedOnboarding: Bool {
        settingsQuery.first?.hasCompletedOnboarding ?? false
    }

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
