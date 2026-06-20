import SwiftUI
import SwiftData

@main
struct DropApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: DropResult.self)
        }
    }
}

struct RootView: View {
    @AppStorage("drop_onboarding_done") private var onboardingDone = false

    var body: some View {
        if onboardingDone {
            ContentView()
        } else {
            DropOnboardingView(onComplete: { onboardingDone = true })
        }
    }
}
