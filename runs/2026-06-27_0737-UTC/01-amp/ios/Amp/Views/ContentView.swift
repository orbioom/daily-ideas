import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AmpSettings]

    var body: some View {
        let s = settings.first ?? AmpSettings.fetch(context: context)
        if s.hasCompletedOnboarding {
            MainTabView()
                .onAppear { AmpSeeder.seed(context: context) }
        } else {
            OnboardingView(settings: s)
        }
    }
}
