import SwiftUI
import SwiftData

struct AtelierRootView: View {
    @Query private var allSettings: [AtelierSettings]
    @Environment(\.modelContext) private var context

    private var settings: AtelierSettings? { allSettings.first }

    var body: some View {
        Group {
            if let s = settings {
                if s.showOnboarding {
                    AtelierOnboardingView()
                } else {
                    AtelierMainTabView()
                }
            } else {
                AtelierMainTabView()
            }
        }
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if allSettings.isEmpty {
            context.insert(AtelierSettings())
            try? context.save()
        }
    }
}
