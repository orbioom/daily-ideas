import SwiftUI
import SwiftData

struct StrokeContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [StrokeSettings]

    var body: some View {
        let s = settings.first ?? StrokeSettings.fetch(context: context)
        if s.hasCompletedOnboarding {
            StrokeTabView()
                .onAppear { StrokeSeeder.seed(context: context) }
        } else {
            StrokeOnboardingView(settings: s)
        }
    }
}
