import SwiftUI
import SwiftData

/// Root: gates onboarding on `hasOnboarded`, otherwise the main TabView.
/// Seeds bundled data idempotently on first appearance.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .task { SeedData.seedIfNeeded(context: context) }
            } else {
                OnboardingView()
            }
        }
    }
}
