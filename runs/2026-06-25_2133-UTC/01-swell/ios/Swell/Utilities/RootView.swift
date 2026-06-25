import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var allSettings: [SurfSettings]
    @Environment(\.modelContext) private var context

    private var settings: SurfSettings? { allSettings.first }

    var body: some View {
        Group {
            if let s = settings {
                if s.showOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                MainTabView()
                    .onAppear { ensureSettings() }
            }
        }
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if allSettings.isEmpty {
            let s = SurfSettings()
            context.insert(s)
            try? context.save()
        }
    }
}
