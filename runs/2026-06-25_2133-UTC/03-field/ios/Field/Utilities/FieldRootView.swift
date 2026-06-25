import SwiftUI
import SwiftData

struct FieldRootView: View {
    @Query private var allSettings: [FieldSettings]
    @Environment(\.modelContext) private var context

    private var settings: FieldSettings? { allSettings.first }

    var body: some View {
        Group {
            if let s = settings {
                if s.showOnboarding {
                    FieldOnboardingView()
                } else {
                    FieldMainTabView()
                }
            } else {
                FieldMainTabView()
            }
        }
        .onAppear { ensureSettings() }
    }

    private func ensureSettings() {
        if allSettings.isEmpty {
            context.insert(FieldSettings())
            try? context.save()
        }
    }
}
