import SwiftUI
import SwiftData

struct SparContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [SparSettings]

    var body: some View {
        let s = settings.first ?? SparSettings.fetch(context: context)
        if s.hasCompletedOnboarding {
            SparTabView()
                .onAppear { SparSeeder.seed(context: context) }
        } else {
            SparOnboardingView(settings: s)
        }
    }
}
